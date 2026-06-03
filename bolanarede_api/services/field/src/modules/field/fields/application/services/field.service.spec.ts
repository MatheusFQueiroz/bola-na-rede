import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { FieldService } from './field.service';
import { FIELD_REPOSITORY } from '../../domain/repositories/field-repository.interface';
import { FieldMessagingService } from './field-messaging.service';
import type { Field } from '../../domain/models/field.entity';
import type { FieldCourt } from '../../domain/models/field-court.entity';

const mockFieldRepo = {
  create: jest.fn(),
  findById: jest.fn(),
  findNearby: jest.fn(),
  addCourt: jest.fn(),
  findCourt: jest.fn(),
  findCourts: jest.fn(),
  setAvailabilitySlots: jest.fn(),
  getAvailabilitySlots: jest.fn(),
};

const mockMessaging = {
  publishFieldRegistered: jest.fn(),
};

const mockField: Field = {
  id: 'field-uuid-1',
  name: 'Arena São Paulo',
  description: 'Quadras society',
  city: 'São Paulo',
  address: 'Rua Teste, 123',
  lat: -23.5505,
  lng: -46.6333,
  ownerUserId: 'owner-uuid-1',
  isActive: true,
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
};

const mockCourt: FieldCourt = {
  id: 'court-uuid-1',
  fieldId: 'field-uuid-1',
  name: 'Quadra A',
  type: 'society',
  maxPlayers: 10,
  isActive: true,
};

describe('FieldService', () => {
  let service: FieldService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        FieldService,
        { provide: FIELD_REPOSITORY, useValue: mockFieldRepo },
        { provide: FieldMessagingService, useValue: mockMessaging },
      ],
    }).compile();
    service = module.get(FieldService);
  });

  describe('register', () => {
    it('creates a field and publishes field.registered event', async () => {
      mockFieldRepo.create.mockResolvedValue(mockField);

      const result = await service.register('owner-uuid-1', {
        name: 'Arena São Paulo',
        city: 'São Paulo',
        address: 'Rua Teste, 123',
        lat: -23.5505,
        lng: -46.6333,
      });

      expect(mockFieldRepo.create).toHaveBeenCalledWith({
        name: 'Arena São Paulo',
        city: 'São Paulo',
        address: 'Rua Teste, 123',
        lat: -23.5505,
        lng: -46.6333,
        ownerUserId: 'owner-uuid-1',
        description: undefined,
      });
      expect(mockMessaging.publishFieldRegistered).toHaveBeenCalledWith(mockField);
      expect(result.id).toBe('field-uuid-1');
      expect(result.name).toBe('Arena São Paulo');
    });
  });

  describe('getById', () => {
    it('returns field when found', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      const result = await service.getById('field-uuid-1');
      expect(result.id).toBe('field-uuid-1');
    });

    it('throws NotFoundException when field not found', async () => {
      mockFieldRepo.findById.mockResolvedValue(null);
      await expect(service.getById('not-found')).rejects.toThrow(NotFoundException);
    });
  });

  describe('searchNearby', () => {
    it('returns list of fields from repository', async () => {
      mockFieldRepo.findNearby.mockResolvedValue([mockField]);
      const results = await service.searchNearby({ city: 'São Paulo' });
      expect(mockFieldRepo.findNearby).toHaveBeenCalledWith({ city: 'São Paulo' });
      expect(results).toHaveLength(1);
      expect(results[0].id).toBe('field-uuid-1');
    });
  });

  describe('addCourt', () => {
    it('adds court to existing field', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      mockFieldRepo.addCourt.mockResolvedValue(mockCourt);

      const result = await service.addCourt('owner-uuid-1', 'field-uuid-1', {
        name: 'Quadra A',
        type: 'society',
        maxPlayers: 10,
      });

      expect(mockFieldRepo.addCourt).toHaveBeenCalledWith({
        fieldExternalId: 'field-uuid-1',
        name: 'Quadra A',
        type: 'society',
        maxPlayers: 10,
      });
      expect(result.name).toBe('Quadra A');
    });

    it('throws NotFoundException when field not found', async () => {
      mockFieldRepo.findById.mockResolvedValue(null);
      await expect(
        service.addCourt('owner-uuid-1', 'not-found', { name: 'Q', type: 'futsal', maxPlayers: 10 }),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws ForbiddenException when user is not field owner', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      const { ForbiddenException } = await import('@nestjs/common');
      await expect(
        service.addCourt('another-user', 'field-uuid-1', { name: 'Q', type: 'futsal', maxPlayers: 10 }),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
