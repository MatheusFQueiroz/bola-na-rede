import {
  Controller,
  Get,
  NotFoundException,
  Param,
  Query,
} from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { RankingService } from '../../application/services/ranking.service';
import { RankingDto } from '../../application/dto/ranking.dto';
import { LeaderboardEntryDto } from '../../application/dto/leaderboard-entry.dto';

@ApiTags('Rankings')
@Controller('rankings')
export class RankingsController {
  constructor(private readonly rankingService: RankingService) {}

  @Get()
  @ApiOperation({ summary: 'Get leaderboard for a sport (top N players by points)' })
  @ApiQuery({ name: 'sport', required: true, description: 'Sport name (e.g. futsal)' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Max results (default 10, max 100)' })
  async getLeaderboard(
    @Query('sport') sport: string,
    @Query('limit') limit?: string,
  ): Promise<LeaderboardEntryDto[]> {
    if (!sport) throw new NotFoundException('sport query parameter is required');
    const parsedLimit = Math.min(parseInt(limit ?? '10', 10) || 10, 100);
    return this.rankingService.getLeaderboard(sport, parsedLimit);
  }

  @Get(':userId')
  @ApiOperation({ summary: 'Get ranking for a specific player in a sport' })
  @ApiQuery({ name: 'sport', required: true, description: 'Sport name (e.g. futsal)' })
  async getPlayerRanking(
    @Param('userId') userId: string,
    @Query('sport') sport: string,
  ): Promise<RankingDto> {
    if (!sport) throw new NotFoundException('sport query parameter is required');
    return this.rankingService.getPlayerRanking(userId, sport);
  }
}
