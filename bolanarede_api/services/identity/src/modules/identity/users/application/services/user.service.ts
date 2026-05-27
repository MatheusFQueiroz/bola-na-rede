import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import {
  USER_REPOSITORY,
  UserRepositoryInterface,
} from '../../domain/repositories/user-repository.interface';
import { User } from '../../domain/models/user.entity';
import { PlayerProfile } from '../../domain/models/player-profile.entity';
import { UpdateProfileDto } from '../dto/update-profile.dto';
import { UserDto } from '../dto/user.dto';

@Injectable()
export class UserService {
  constructor(
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepositoryInterface,
  ) {}

  async getProfile(userId: string): Promise<UserDto> {
    const user = await this.userRepository.findById(userId);
    if (!user) throw new NotFoundException(`User ${userId} not found`);

    const profile = await this.userRepository.findProfileById(userId);
    return UserDto.fromUserAndProfile(user, profile);
  }

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
    messagingService: { publishProfileUpdated: (user: User, profile: PlayerProfile) => Promise<void> },
  ): Promise<UserDto> {
    const user = await this.userRepository.findById(userId);
    if (!user) throw new NotFoundException(`User ${userId} not found`);

    const profile = await this.userRepository.updateProfile(userId, {
      displayName: dto.displayName,
      photoUrl: dto.photoUrl,
      bio: dto.bio,
      city: dto.city,
      position: dto.position as PlayerProfilePosition,
      skillLevel: dto.skillLevel,
      isPublic: dto.isPublic,
    });

    await messagingService.publishProfileUpdated(user, profile);
    return UserDto.fromUserAndProfile(user, profile);
  }

  async getPublicProfile(userId: string): Promise<UserDto> {
    const user = await this.userRepository.findById(userId);
    if (!user) throw new NotFoundException(`User ${userId} not found`);

    const profile = await this.userRepository.findProfileById(userId);
    if (!profile?.isPublic) throw new NotFoundException(`User ${userId} not found`);

    return UserDto.fromUserAndProfile(user, profile);
  }
}

type PlayerProfilePosition = 'goalkeeper' | 'defender' | 'midfielder' | 'forward' | null;
