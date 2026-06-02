export type CourtType = 'society' | 'futsal' | 'grass' | 'synthetic';

export class FieldCourt {
  id!: string;           // UUID (external_id)
  fieldId!: string;      // UUID do field pai
  name!: string;
  type!: CourtType;
  maxPlayers!: number;
  isActive!: boolean;
}
