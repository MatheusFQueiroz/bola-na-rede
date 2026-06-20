import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem } from '@shared/infra/hateoas';
import { ReviewService } from '../../application/services/review.service';
import { PlayerScoreDto } from '../../application/dto/player-score.dto';

@ApiTags('scores')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('scores')
export class ScoresController {
  constructor(private readonly service: ReviewService) {}

  @Get('players/:userId')
  @Public()
  @HateoasItem<PlayerScoreDto>({
    basePath: '/v1/scores',
    itemLinks: (s) => ({
      self: { href: `/v1/scores/players/${s.playerUserId}`, method: 'GET' },
      reviews: { href: `/v1/reviews?revieweeId=${s.playerUserId}`, method: 'GET' },
      profile: { href: `/v1/users/${s.playerUserId}/profile`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Obter score/reputação de um jogador' })
  getPlayerScore(@Param('userId') userId: string): Promise<PlayerScoreDto> {
    return this.service.getPlayerScore(userId);
  }
}
