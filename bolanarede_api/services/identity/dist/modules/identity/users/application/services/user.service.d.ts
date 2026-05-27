import { UserRepositoryInterface } from '../../domain/repositories/user-repository.interface';
import { UpdateProfileDto } from '../dto/update-profile.dto';
import { UserDto } from '../dto/user.dto';
export declare class UserService {
    private readonly userRepository;
    constructor(userRepository: UserRepositoryInterface);
    getProfile(userId: string): Promise<UserDto>;
    updateProfile(userId: string, dto: UpdateProfileDto, messagingService: {
        publishProfileUpdated: (user: unknown, profile: unknown) => Promise<void>;
    }): Promise<UserDto>;
    getPublicProfile(userId: string): Promise<UserDto>;
}
