// Um plano fixa um horário semanal em uma quadra.
// dayOfWeek: 0=Dom, 1=Seg, ..., 6=Sáb
// startTime / endTime: "HH:MM"
// planEndsAt null = plano indefinido
export class RecurringPlan {
  id!: string;              // UUID (external_id)
  courtId!: string;         // UUID da quadra
  fieldId!: string;         // UUID do campo (desnormalizado)
  playerUserId!: string | null;
  dayOfWeek!: number;
  startTime!: string;
  endTime!: string;
  planStartsAt!: Date;
  planEndsAt!: Date | null;
  isActive!: boolean;
  createdAt!: Date;
}
