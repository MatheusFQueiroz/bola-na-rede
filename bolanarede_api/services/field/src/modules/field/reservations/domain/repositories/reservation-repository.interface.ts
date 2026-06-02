import type { Reservation, ReservationChannel } from '../models/reservation.entity';

export const RESERVATION_REPOSITORY = Symbol('RESERVATION_REPOSITORY');

export interface CreateReservationData {
  courtExternalId: string;
  fieldExternalId: string;
  playerUserId?: string;
  channel: ReservationChannel;
  startsAt: Date;
  endsAt: Date;
  notes?: string;
}

export interface ReservationRepositoryInterface {
  create(data: CreateReservationData): Promise<Reservation>;
  findById(externalId: string): Promise<Reservation | null>;
  findByField(fieldExternalId: string, page: number, limit: number): Promise<Reservation[]>;
  findOverlapping(courtExternalId: string, startsAt: Date, endsAt: Date): Promise<Reservation[]>;
  cancel(externalId: string): Promise<Reservation>;
}
