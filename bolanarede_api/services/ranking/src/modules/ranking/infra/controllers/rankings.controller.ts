import {
  BadRequestException,
  Controller,
  Get,
  Param,
  Query,
} from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';
import { RankingService } from '../../application/services/ranking.service';
import { RankingDto } from '../../application/dto/ranking.dto';
import { LeaderboardEntryDto } from '../../application/dto/leaderboard-entry.dto';

@ApiTags('Rankings')
@Controller('rankings')
export class RankingsController {
  constructor(private readonly rankingService: RankingService) {}

  @Get()
  @HateoasList<LeaderboardEntryDto>({
    basePath: '/v1/rankings',
    itemLinks: (e) => ({
      self: { href: `/v1/rankings/${e.playerUserId}`, method: 'GET' },
      profile: { href: `/v1/profiles/${e.playerUserId}`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Get leaderboard for a sport (top N players by points)' })
  @ApiQuery({ name: 'sport', required: true, description: 'Sport name (e.g. futsal)' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Max results (default 10, max 100)' })
  async getLeaderboard(
    @Query('sport') sport: string,
    @Query('limit') limit?: string,
  ): Promise<LeaderboardEntryDto[]> {
    if (!sport) throw new BadRequestException('sport query parameter is required');
    const parsedLimit = Math.min(Math.max(1, parseInt(limit ?? '10', 10) || 10), 100);
    return this.rankingService.getLeaderboard(sport, parsedLimit);
  }

  @Get(':userId')
  @HateoasItem<RankingDto>({
    basePath: '/v1/rankings',
    itemLinks: (r) => ({
      self: { href: `/v1/rankings/${r.playerUserId}`, method: 'GET' },
      profile: { href: `/v1/profiles/${r.playerUserId}`, method: 'GET' },
      score: { href: `/v1/scores/players/${r.playerUserId}`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Get ranking for a specific player in a sport' })
  @ApiQuery({ name: 'sport', required: true, description: 'Sport name (e.g. futsal)' })
  async getPlayerRanking(
    @Param('userId') userId: string,
    @Query('sport') sport: string,
  ): Promise<RankingDto> {
    if (!sport) throw new BadRequestException('sport query parameter is required');
    return this.rankingService.getPlayerRanking(userId, sport);
  }
}
