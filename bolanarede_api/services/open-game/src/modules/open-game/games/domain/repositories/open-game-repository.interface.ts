import type { OpenGame, GameStatus } from '../models/open-game.entity';
import type { GameParticipant } from '../models/game-participant.entity';

export const OPEN_GAME_REPOSITORY = 'OPEN_GAME_REPOSITORY';

export interface CreateOpenGameData {
  organizerUserId: string;
  fieldId?: string;
  fieldNameSnapshot?: string;
  fieldAddressSnapshot?: string;
  title: string;
  description?: string;
  sport: string;
  scheduledAt: Date;
  durationMinutes?: number;
  minPlayers?: number;
  maxPlayers?: number;
  pricePerPlayer?: number;
}

export interface UpdateOpenGameData {
  title?: string;
  description?: string;
  fieldId?: string;
  fieldNameSnapshot?: string;
  fieldAddressSnapshot?: string;
  scheduledAt?: Date;
  durationMinutes?: number;
  minPlayers?: number;
  maxPlayers?: number;
  pricePerPlayer?: number;
}

export interface ListOpenGamesFilter {
  sport?: string;
  fieldId?: string;
  fromDate?: Date;
  toDate?: Date;
  status?: GameStatus[];
}

export interface OpenGameRepositoryInterface {
  create(data: CreateOpenGameData): Promise<OpenGame>;
  findById(externalId: string): Promise<OpenGame | null>;
  findUpcoming(filter: ListOpenGamesFilter): Promise<OpenGame[]>;
  update(externalId: string, data: UpdateOpenGameData): Promise<OpenGame>;
  updateStatus(externalId: string, status: GameStatus): Promise<void>;
  deactivate(externalId: string): Promise<void>;

  // participants
  addParticipant(gameExternalId: string, playerUserId: string, displayName: string, position: string | null): Promise<GameParticipant>;
  removeParticipant(gameExternalId: string, playerUserId: string): Promise<void>;
  findParticipant(gameExternalId: string, playerUserId: string): Promise<GameParticipant | null>;
  findParticipants(gameExternalId: string): Promise<GameParticipant[]>;
  countActiveParticipants(gameExternalId: string): Promise<number>;
  updateParticipantSnapshot(playerUserId: string, displayName: string, position: string | null): Promise<void>;
}
