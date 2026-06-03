export type GameStatus = 'open' | 'full' | 'in_progress' | 'finished' | 'cancelled';
export type SportType = 'futsal' | 'society' | 'campo';

export class OpenGame {
  id!: string;                        // external_id UUID exposto via API
  organizerUserId!: string;           // identity UUID (cross-service, sem FK)
  fieldId!: string | null;            // field UUID (cross-service, sem FK, nullable)
  fieldNameSnapshot!: string | null;  // snapshot do nome do campo
  fieldAddressSnapshot!: string | null;
  title!: string;
  description!: string | null;
  sport!: SportType;
  scheduledAt!: Date;
  durationMinutes!: number;
  minPlayers!: number;
  maxPlayers!: number;
  pricePerPlayer!: number | null;     // NUMERIC(10,2) — null = gratuito
  status!: GameStatus;
  createdAt!: Date;
  updatedAt!: Date;
}
