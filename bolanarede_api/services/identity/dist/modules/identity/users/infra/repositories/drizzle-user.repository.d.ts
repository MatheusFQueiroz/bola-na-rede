import { DrizzleService } from '@shared/infra/database/drizzle.service';
import type { CreateUserData, UserRepositoryInterface, UserWithCredential } from '../../domain/repositories/user-repository.interface';
import type { User } from '../../domain/models/user.entity';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';
export declare class DrizzleUserRepository implements UserRepositoryInterface {
    private readonly drizzle;
    constructor(drizzle: DrizzleService);
    findById(externalId: string): Promise<User | null>;
    findByEmail(email: string): Promise<UserWithCredential | null>;
    create(data: CreateUserData): Promise<User>;
    findProfileById(userId: string): Promise<PlayerProfile | null>;
    updateProfile(userId: string, data: Partial<PlayerProfile>): Promise<PlayerProfile>;
    private toUser;
    private toProfile;
}
