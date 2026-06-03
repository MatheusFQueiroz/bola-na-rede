import type { User } from '../models/user.entity';
import type { PlayerProfile } from '../models/player-profile.entity';

export const USER_REPOSITORY = 'USER_REPOSITORY';

export interface CreateUserData {
  email: string;
  passwordHash: string;
  displayName: string;
}

export interface UserWithCredential extends User {
  passwordHash: string | null;
}

export interface UserRepositoryInterface {
  findById(externalId: string): Promise<User | null>;
  findByEmail(email: string): Promise<UserWithCredential | null>;
  create(data: CreateUserData): Promise<User>;
  findProfileById(userId: string): Promise<PlayerProfile | null>;
  updateProfile(userId: string, data: Partial<PlayerProfile>): Promise<PlayerProfile>;
}
