// dayOfWeek: 0=Domingo, 1=Segunda, ..., 6=Sábado
// startTime / endTime: string no formato "HH:MM" (e.g. "08:00", "09:00")
export class AvailabilitySlot {
  id!: bigint;
  courtId!: bigint;
  dayOfWeek!: number;
  startTime!: string;
  endTime!: string;
  isAvailable!: boolean;
}
