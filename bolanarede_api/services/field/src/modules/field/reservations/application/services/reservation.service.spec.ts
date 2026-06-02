import { ConflictException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { ReservationService } from './reservation.service';
import { FIELD_REPOSITORY } from '../../../fields/domain/repositories/field-repository.interface';
import { RESERVATION_REPOSITORY } from '../../domain/repositories/reservation-repository.interface';
import { FieldMessagingService } from '../../../fields/application/services/field-messaging.service';
import type { Reservation } from '../../domain/models/reservation.entity';
import type { Field } from '../../../fields/domain/models/field.entity';

const mockFieldRepo = { findById: jest.fn(), findCourt: jest.fn() };
const mockReservationRepo = {
  create: jest.fn(),
  findById: jest.fn(),
  findByField: jest.fn(),
  findOverlapping: jest.fn(),
  cancel: jest.fn(),
};
const mockMessaging = {
  publishReservationConfirmed: jest.fn(),
  publishReservationCancelled: jest.fn(),
};

const mockField: Field = {
  id: 'field-uuid-1', name: 'Arena', description: null, city: 'SP',
  address: 'Rua X', lat: -23.5, lng: -46.6,
  ownerUserId: 'owner-uuid-1', isActive: true,
  createdAt: new Date(), updatedAt: new Date(),
};

const mockReservation: Reservation = {
  id: 'res-uuid-1', courtId: 'court-uuid-1', fieldId: 'field-uuid-1',
  playerUserId: null, channel: 'manual', notes: null,
  startsAt: new Date('2026-06-15T08:00:00Z'),
  endsAt: new Date('2026-06-15T09:00:00Z'),
  status: 'confirmed', createdAt: new Date(),
};

describe('ReservationService', () => {
  let service: ReservationService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        ReservationService,
        { provide: FIELD_REPOSITORY, useValue: mockFieldRepo },
        { provide: RESERVATION_REPOSITORY, useValue: mockReservationRepo },
        { provide: FieldMessagingService, useValue: mockMessaging },
      ],
    }).compile();
    service = module.get(ReservationService);
  });

  describe('createManual', () => {
    it('creates a reservation and publishes reservation.confirmed event', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      mockFieldRepo.findCourt.mockResolvedValue({ id: 'court-uuid-1', fieldId: 'field-uuid-1' });
      mockReservationRepo.findOverlapping.mockResolvedValue([]);
      mockReservationRepo.create.mockResolvedValue(mockReservation);

      const result = await service.createManual('owner-uuid-1', 'field-uuid-1', {
        courtId: 'court-uuid-1',
        channel: 'manual',
        startsAt: '2026-06-15T08:00:00Z',
        endsAt: '2026-06-15T09:00:00Z',
      });

      expect(mockReservationRepo.create).toHaveBeenCalled();
      expect(mockMessaging.publishReservationConfirmed).toHaveBeenCalledWith(mockReservation);
      expect(result.id).toBe('res-uuid-1');
    });

    it('throws NotFoundException when field not found', async () => {
      mockFieldRepo.findById.mockResolvedValue(null);
      await expect(
        service.createManual('owner-uuid-1', 'not-found', {
          courtId: 'c', channel: 'manual',
          startsAt: '2026-06-15T08:00:00Z', endsAt: '2026-06-15T09:00:00Z',
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws ConflictException when time slot is already reserved', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      mockFieldRepo.findCourt.mockResolvedValue({ id: 'court-uuid-1', fieldId: 'field-uuid-1' });
      mockReservationRepo.findOverlapping.mockResolvedValue([mockReservation]);

      await expect(
        service.createManual('owner-uuid-1', 'field-uuid-1', {
          courtId: 'court-uuid-1', channel: 'manual',
          startsAt: '2026-06-15T08:00:00Z', endsAt: '2026-06-15T09:00:00Z',
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('cancel', () => {
    it('cancels reservation and publishes reservation.cancelled event', async () => {
      const cancelled = { ...mockReservation, status: 'cancelled' as const };
      mockReservationRepo.findById.mockResolvedValue(mockReservation);
      mockReservationRepo.cancel.mockResolvedValue(cancelled);
      mockFieldRepo.findById.mockResolvedValue(mockField);

      const result = await service.cancel('owner-uuid-1', 'field-uuid-1', 'res-uuid-1');

      expect(mockReservationRepo.cancel).toHaveBeenCalledWith('res-uuid-1');
      expect(mockMessaging.publishReservationCancelled).toHaveBeenCalledWith(cancelled);
      expect(result.status).toBe('cancelled');
    });

    it('throws NotFoundException when reservation not found', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      mockReservationRepo.findById.mockResolvedValue(null);
      await expect(service.cancel('owner-uuid-1', 'field-uuid-1', 'not-found')).rejects.toThrow(NotFoundException);
    });
  });

  describe('list', () => {
    it('returns reservations for field', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      mockReservationRepo.findByField.mockResolvedValue([mockReservation]);

      const result = await service.list('field-uuid-1', 1, 10);

      expect(mockReservationRepo.findByField).toHaveBeenCalledWith('field-uuid-1', 1, 10);
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('res-uuid-1');
    });
  });
});
