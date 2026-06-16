import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { GameService } from '../../application/services/game.service';
import { SubmitResultDto } from '../../application/dto/submit-result.dto';
import { GameDto } from '../../application/dto/game.dto';

@ApiTags('Games')
@UseGuards(JwtAuthGuard)
@Controller('games')
export class GamesController {
  constructor(private readonly gameService: GameService) {}

  @Get()
  @ApiOperation({ summary: 'Listar jogos do usuário autenticado' })
  async list(@Request() req: any): Promise<GameDto[]> {
    const userId: string = req.user.sub;
    const games = await this.gameService.listByUser(userId);
    return games.map(GameDto.from);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get competitive game info' })
  async getGame(@Request() req: any, @Param('id') id: string): Promise<GameDto> {
    const userId: string = req.user.sub;
    const game = await this.gameService.getGame(userId, id);
    return GameDto.from(game);
  }

  @Post(':id/result')
  @ApiOperation({ summary: 'Submit final result for a competitive game' })
  async submitResult(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: SubmitResultDto,
  ): Promise<GameDto> {
    const userId: string = req.user.sub;
    const game = await this.gameService.submitResult(userId, id, dto);
    return GameDto.from(game);
  }

  @Post(':id/dispute')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Dispute the result of a completed game' })
  async disputeResult(@Request() req: any, @Param('id') id: string): Promise<GameDto> {
    const userId: string = req.user.sub;
    const game = await this.gameService.disputeResult(userId, id);
    return GameDto.from(game);
  }

  @Post(':id/results/confirm')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Confirmar resultado do jogo' })
  async confirmResult(@Request() req: any, @Param('id') id: string): Promise<void> {
    const userId: string = req.user.sub;
    return this.gameService.confirmResult(userId, id);
  }
}
