import { Controller, HttpCode, HttpStatus, Param, Post, Request, UseGuards } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { MatchmakingService } from '../../application/services/matchmaking.service';
import { PendingMatchDto } from '../../application/dto/pending-match.dto';

@ApiTags('Matches')
@UseGuards(JwtAuthGuard)
@Controller('matches')
export class MatchesController {
  constructor(private readonly matchmakingService: MatchmakingService) {}

  @Post(':id/accept')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Accept a proposed match' })
  async acceptMatch(@Request() req: any, @Param('id') id: string): Promise<PendingMatchDto> {
    const userId: string = req.user.sub;
    const match = await this.matchmakingService.acceptMatch(userId, id);
    return PendingMatchDto.from(match);
  }
}
