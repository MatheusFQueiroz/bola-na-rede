export type ReservationChannel = 'app' | 'manual' | 'phone';
export type ReservationStatus = 'confirmed' | 'cancelled';

export class Reservation {
  id!: string;             // UUID (external_id)
  courtId!: string;        // UUID da quadra
  fieldId!: string;        // UUID do campo (desnormalizado para queries)
  playerUserId!: string | null;  // null para reservas manual/phone
  channel!: ReservationChannel;
  startsAt!: Date;
  endsAt!: Date;
  status!: ReservationStatus;
  notes!: string | null;
  createdAt!: Date;
}
