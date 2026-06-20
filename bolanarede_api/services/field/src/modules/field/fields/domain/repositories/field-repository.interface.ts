import type { Field } from '../models/field.entity';
import type { FieldCourt } from '../models/field-court.entity';
import type { AvailabilitySlot } from '../models/availability-slot.entity';

export const FIELD_REPOSITORY = Symbol('FIELD_REPOSITORY');

export interface CreateFieldData {
  name: string;
  description?: string;
  city: string;
  address: string;
  lat: number;
  lng: number;
  ownerUserId: string;
}

export interface CreateCourtData {
  fieldExternalId: string;
  name: string;
  type: string;
  maxPlayers: number;
}

export interface AvailabilitySlotData {
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  isAvailable: boolean;
}

export interface SearchFieldsParams {
  city?: string;
  lat?: number;
  lng?: number;
  radiusKm?: number;
}

export interface FieldRepositoryInterface {
  create(data: CreateFieldData): Promise<Field>;
  findById(externalId: string): Promise<Field | null>;
  findNearby(params: SearchFieldsParams): Promise<Field[]>;
  findByOwner(ownerUserId: string): Promise<Field[]>;
  addCourt(data: CreateCourtData): Promise<FieldCourt>;
  findCourt(courtExternalId: string): Promise<FieldCourt | null>;
  findCourts(fieldExternalId: string): Promise<FieldCourt[]>;
  setAvailabilitySlots(courtExternalId: string, slots: AvailabilitySlotData[]): Promise<void>;
  getAvailabilitySlots(courtExternalId: string): Promise<AvailabilitySlot[]>;
}
