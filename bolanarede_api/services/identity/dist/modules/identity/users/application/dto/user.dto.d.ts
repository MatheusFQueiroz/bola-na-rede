import type { User } from '../../domain/models/user.entity';
import type { PlayerProfile } from '../../domain/models/player-profile.entity';
export declare class UserDto {
    id: string;
    email: string | null;
    displayName?: string;
    photoUrl?: string | null;
    bio?: string | null;
    city?: string | null;
    position?: string | null;
    skillLevel?: number | null;
    isPublic?: boolean;
    createdAt: Date;
    static fromUserAndProfile(user: User, profile: PlayerProfile | null): UserDto;
}
