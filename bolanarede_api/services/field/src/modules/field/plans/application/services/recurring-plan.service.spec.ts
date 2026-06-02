import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { RecurringPlanService } from './recurring-plan.service';
import { FIELD_REPOSITORY } from '../../../fields/domain/repositories/field-repository.interface';
import { RECURRING_PLAN_REPOSITORY } from '../../domain/repositories/recurring-plan-repository.interface';
import { FieldMessagingService } from '../../../fields/application/services/field-messaging.service';
import type { Field } from '../../../fields/domain/models/field.entity';
import type { RecurringPlan } from '../../domain/models/recurring-plan.entity';
import type { RecurringPlanSlot } from '../../domain/models/recurring-plan-slot.entity';

const mockFieldRepo = { findById: jest.fn() };
const mockPlanRepo = {
  create: jest.fn(),
  findById: jest.fn(),
  findByField: jest.fn(),
  deactivate: jest.fn(),
  createSlot: jest.fn(),
  findSlot: jest.fn(),
  releaseSlot: jest.fn(),
  findActiveSlotsByField: jest.fn(),
};
const mockMessaging = { publishPlanSlotReleased: jest.fn() };

const mockField: Field = {
  id: 'field-uuid-1', name: 'Arena', description: null, city: 'SP',
  address: 'Rua X', lat: -23.5, lng: -46.6,
  ownerUserId: 'owner-uuid-1', isActive: true,
  createdAt: new Date(), updatedAt: new Date(),
};

const mockPlan: RecurringPlan = {
  id: 'plan-uuid-1', courtId: 'court-uuid-1', fieldId: 'field-uuid-1',
  playerUserId: 'player-uuid-1', dayOfWeek: 1, startTime: '08:00', endTime: '09:00',
  planStartsAt: new Date('2026-06-01'), planEndsAt: null, isActive: true,
  createdAt: new Date(),
};

const mockSlot: RecurringPlanSlot = {
  id: 'slot-uuid-1', planId: 'plan-uuid-1', fieldId: 'field-uuid-1',
  slotDate: new Date('2026-06-08'), status: 'active',
};

describe('RecurringPlanService', () => {
  let service: RecurringPlanService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        RecurringPlanService,
        { provide: FIELD_REPOSITORY, useValue: mockFieldRepo },
        { provide: RECURRING_PLAN_REPOSITORY, useValue: mockPlanRepo },
        { provide: FieldMessagingService, useValue: mockMessaging },
      ],
    }).compile();
    service = module.get(RecurringPlanService);
  });

  describe('create', () => {
    it('creates recurring plan for existing field', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      mockPlanRepo.create.mockResolvedValue(mockPlan);

      const result = await service.create('owner-uuid-1', 'field-uuid-1', {
        courtId: 'court-uuid-1',
        dayOfWeek: 1,
        startTime: '08:00',
        endTime: '09:00',
        planStartsAt: '2026-06-01T00:00:00Z',
        playerUserId: 'player-uuid-1',
      });

      expect(mockPlanRepo.create).toHaveBeenCalledWith(expect.objectContaining({
        courtExternalId: 'court-uuid-1',
        fieldExternalId: 'field-uuid-1',
        dayOfWeek: 1,
        startTime: '08:00',
      }));
      expect(result.id).toBe('plan-uuid-1');
    });

    it('throws NotFoundException when field not found', async () => {
      mockFieldRepo.findById.mockResolvedValue(null);
      await expect(
        service.create('owner-uuid-1', 'not-found', {
          courtId: 'c', dayOfWeek: 1, startTime: '08:00',
          endTime: '09:00', planStartsAt: '2026-06-01T00:00:00Z',
        }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('releaseSlot', () => {
    it('releases a slot and publishes plan.slot-released event', async () => {
      const released = { ...mockSlot, status: 'released' as const };
      mockPlanRepo.findSlot.mockResolvedValue(mockSlot);
      mockPlanRepo.releaseSlot.mockResolvedValue(released);

      const result = await service.releaseSlot('owner-uuid-1', 'field-uuid-1', 'slot-uuid-1');

      expect(mockPlanRepo.releaseSlot).toHaveBeenCalledWith('slot-uuid-1');
      expect(mockMessaging.publishPlanSlotReleased).toHaveBeenCalledWith(released);
      expect(result.status).toBe('released');
    });

    it('throws NotFoundException when slot not found', async () => {
      mockPlanRepo.findSlot.mockResolvedValue(null);
      await expect(service.releaseSlot('owner-uuid-1', 'field-uuid-1', 'not-found')).rejects.toThrow(NotFoundException);
    });
  });

  describe('getByField', () => {
    it('returns active plans for field', async () => {
      mockFieldRepo.findById.mockResolvedValue(mockField);
      mockPlanRepo.findByField.mockResolvedValue([mockPlan]);

      const result = await service.getByField('field-uuid-1');

      expect(mockPlanRepo.findByField).toHaveBeenCalledWith('field-uuid-1');
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe('plan-uuid-1');
    });
  });
});
