export type SlotStatus = 'active' | 'released' | 'cancelled';

// Representa uma instância semanal de um RecurringPlan.
// released = dono liberou o horário para reserva avulsa
export class RecurringPlanSlot {
  id!: string;              // UUID (external_id)
  planId!: string;          // UUID do plano pai
  fieldId!: string;         // UUID do campo (para o evento publicado)
  slotDate!: Date;          // Data específica da semana
  status!: SlotStatus;
}
