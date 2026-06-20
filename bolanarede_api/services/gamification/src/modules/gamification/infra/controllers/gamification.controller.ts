import {
  Controller,
  Get,
  NotFoundException,
  Param,
} from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';
import { XpService } from '../../application/services/xp.service';
import { LeaderboardEntryDto } from '../../application/dto/leaderboard-entry.dto';
import { ProfileDto } from '../../application/dto/profile.dto';

@ApiTags('Gamification')
@Controller()
export class GamificationController {
  constructor(private readonly xpService: XpService) {}

  @Get('profiles/:userId')
  @Public()
  @HateoasItem<ProfileDto>({
    basePath: '/v1/profiles',
    itemLinks: (p) => ({
      self: { href: `/v1/profiles/${p.playerUserId}`, method: 'GET' },
      reviews: { href: `/v1/reviews?revieweeId=${p.playerUserId}`, method: 'GET' },
      score: { href: `/v1/scores/players/${p.playerUserId}`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Get player profile (XP, level, badges)' })
  async getProfile(@Param('userId') userId: string): Promise<ProfileDto> {
    const { profile, badges } = await this.xpService.getProfile(userId);
    if (!profile) {
      throw new NotFoundException(
        `Profile for player "${userId}" not found`,
      );
    }
    return ProfileDto.from(profile, badges);
  }

  @Get('leaderboard')
  @Public()
  @HateoasList<LeaderboardEntryDto>({
    basePath: '/v1/leaderboard',
    itemLinks: (e) => ({
      self: { href: `/v1/profiles/${e.playerUserId}`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Top 10 players by XP' })
  async getLeaderboard(): Promise<LeaderboardEntryDto[]> {
    const profiles = await this.xpService.getLeaderboard();
    return profiles.map((p, i) => LeaderboardEntryDto.from(p, i + 1));
  }
}
