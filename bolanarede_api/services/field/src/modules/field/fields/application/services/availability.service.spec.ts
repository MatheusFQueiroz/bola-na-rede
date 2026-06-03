import { Test } from '@nestjs/testing';
import { AvailabilityService } from './availability.service';
import { FIELD_REPOSITORY } from '../../domain/repositories/field-repository.interface';
import { RESERVATION_REPOSITORY } from '../../../reservations/domain/repositories/reservation-repository.interface';
import { RECURRING_PLAN_REPOSITORY } from '../../../plans/domain/repositories/recurring-plan-repository.interface';
import type { AvailabilitySlot } from '../../domain/models/availability-slot.entity';
import type { Reservation } from '../../../reservations/domain/models/reservation.entity';

const mockFieldRepo = {
  findById: jest.fn(),
  findCourts: jest.fn(),
  getAvailabilitySlots: jest.fn(),
};
const mockReservationRepo = { findOverlapping: jest.fn() };
const mockPlanRepo = { findActiveSlotsByField: jest.fn() };

const mockAvailabilitySlots: AvailabilitySlot[] = [
  { id: 1n, courtId: 1n, dayOfWeek: 0, startTime: '08:00', endTime: '09:00', isAvailable: true },
  { id: 2n, courtId: 1n, dayOfWeek: 0, startTime: '09:00', endTime: '10:00', isAvailable: true },
];

describe('AvailabilityService', () => {
  let service: AvailabilityService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        AvailabilityService,
        { provide: FIELD_REPOSITORY, useValue: mockFieldRepo },
        { provide: RESERVATION_REPOSITORY, useValue: mockReservationRepo },
        { provide: RECURRING_PLAN_REPOSITORY, useValue: mockPlanRepo },
      ],
    }).compile();
    service = module.get(AvailabilityService);
  });

  describe('getAvailability', () => {
    it('returns all slots as available when no reservations exist', async () => {
      mockFieldRepo.findById.mockResolvedValue({ id: 'f-1', isActive: true });
      mockFieldRepo.findCourts.mockResolvedValue([
        { id: 'c-1', name: 'Quadra A', type: 'society' },
      ]);
      mockFieldRepo.getAvailabilitySlots.mockResolvedValue(mockAvailabilitySlots);
      mockReservationRepo.findOverlapping.mockResolvedValue([]);
      mockPlanRepo.findActiveSlotsByField.mockResolvedValue([]);

      // Sunday, 2026-06-07 (dayOfWeek=0)
      const result = await service.getAvailability('f-1', '2026-06-07');

      expect(result.courts).toHaveLength(1);
      expect(result.courts[0].slots).toHaveLength(2);
      expect(result.courts[0].slots[0].isAvailable).toBe(true);
      expect(result.courts[0].slots[1].isAvailable).toBe(true);
    });

    it('marks slots as unavailable when confirmed reservation overlaps', async () => {
      mockFieldRepo.findById.mockResolvedValue({ id: 'f-1', isActive: true });
      mockFieldRepo.findCourts.mockResolvedValue([
        { id: 'c-1', name: 'Quadra A', type: 'society' },
      ]);
      mockFieldRepo.getAvailabilitySlots.mockResolvedValue(mockAvailabilitySlots);

      const reservation: Partial<Reservation> = {
        startsAt: new Date('2026-06-07T08:00:00-03:00'),
        endsAt: new Date('2026-06-07T09:00:00-03:00'),
        status: 'confirmed',
      };
      mockReservationRepo.findOverlapping.mockResolvedValueOnce([reservation]).mockResolvedValue([]);
      mockPlanRepo.findActiveSlotsByField.mockResolvedValue([]);

      const result = await service.getAvailability('f-1', '2026-06-07');

      // First slot (08:00-09:00) is taken, second (09:00-10:00) is free
      const slots = result.courts[0].slots;
      expect(slots[0].isAvailable).toBe(false);
      expect(slots[1].isAvailable).toBe(true);
    });

    it('throws NotFoundException when field not found', async () => {
      mockFieldRepo.findById.mockResolvedValue(null);
      const { NotFoundException } = await import('@nestjs/common');
      await expect(service.getAvailability('not-found', '2026-06-07')).rejects.toThrow(NotFoundException);
    });
  });
});
