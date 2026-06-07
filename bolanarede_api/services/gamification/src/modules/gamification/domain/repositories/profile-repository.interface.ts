import type { PlayerProfile } from '../models/player-profile.entity';

export const PROFILE_REPOSITORY = 'PROFILE_REPOSITORY';

export interface ProfileRepositoryInterface {
  /** Cria perfil com 0 XP se não existir; retorna o perfil existente caso já exista. */
  upsertProfile(playerUserId: string, displayName: string): Promise<PlayerProfile>;
  findByPlayer(playerUserId: string): Promise<PlayerProfile | null>;
  /** Incrementa totalXp e recalcula level; retorna o perfil atualizado. */
  addXp(playerUserId: string, xpToAdd: number): Promise<PlayerProfile>;
  updateDisplayName(playerUserId: string, displayName: string): Promise<void>;
  findTopByXp(limit: number): Promise<PlayerProfile[]>;
}
