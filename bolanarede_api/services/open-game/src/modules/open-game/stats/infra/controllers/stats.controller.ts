import {
  Body, Controller, Get, Param, Post, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasList } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { StatsService } from '../../application/services/stats.service';
import { RecordStatsDto } from '../../application/dto/record-stats.dto';
import { StatsDto } from '../../application/dto/stats.dto';

@ApiTags('open-games')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('open-games')
export class StatsController {
  constructor(private readonly service: StatsService) {}

  @Post(':id/stats')
  @Permissions('open-games:write')
  @HateoasList(StatsDto)
  @ApiOperation({ summary: 'Registrar estatísticas dos jogadores (somente organizador)' })
  recordStats(
    @Param('id') id: string,
    @Body() dto: RecordStatsDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<StatsDto[]> {
    return this.service.recordStats(user.id, id, dto);
  }

  @Get(':id/stats')
  @Public()
  @HateoasList(StatsDto)
  @ApiOperation({ summary: 'Listar estatísticas da partida' })
  getGameStats(@Param('id') id: string): Promise<StatsDto[]> {
    return this.service.getGameStats(id);
  }
}
