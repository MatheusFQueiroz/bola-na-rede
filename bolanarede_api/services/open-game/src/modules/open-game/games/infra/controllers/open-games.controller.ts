import {
  Body, Controller, Delete, Get, HttpCode, HttpStatus,
  Param, Post, Put, Query, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { OpenGameService } from '../../application/services/open-game.service';
import { CreateOpenGameDto } from '../../application/dto/create-open-game.dto';
import { UpdateOpenGameDto } from '../../application/dto/update-open-game.dto';
import { ListOpenGamesDto } from '../../application/dto/list-open-games.dto';
import { OpenGameDto } from '../../application/dto/open-game.dto';
import { GameParticipantDto } from '../../application/dto/game-participant.dto';

@ApiTags('open-games')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('open-games')
export class OpenGamesController {
  constructor(private readonly service: OpenGameService) {}

  @Post()
  @Permissions('open-games:write')
  @HateoasItem(OpenGameDto)
  @ApiOperation({ summary: 'Criar partida aberta' })
  create(
    @Body() dto: CreateOpenGameDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<OpenGameDto> {
    return this.service.create(user.id, user.name, dto);
  }

  @Get()
  @Public()
  @HateoasList(OpenGameDto)
  @ApiOperation({ summary: 'Listar partidas abertas (cache 30s sem filtros)' })
  list(@Query() query: ListOpenGamesDto): Promise<OpenGameDto[]> {
    return this.service.list(query);
  }

  @Get(':id')
  @Public()
  @HateoasItem(OpenGameDto)
  @ApiOperation({ summary: 'Obter partida por ID' })
  getById(@Param('id') id: string): Promise<OpenGameDto> {
    return this.service.getById(id);
  }

  @Put(':id')
  @Permissions('open-games:write')
  @HateoasItem(OpenGameDto)
  @ApiOperation({ summary: 'Atualizar dados da partida (somente organizador)' })
  update(
    @Param('id') id: string,
    @Body() dto: UpdateOpenGameDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<OpenGameDto> {
    return this.service.update(user.id, id, dto);
  }

  @Delete(':id')
  @Permissions('open-games:write')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Cancelar partida (somente organizador)' })
  cancel(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<void> {
    return this.service.cancel(user.id, id);
  }

  @Post(':id/join')
  @Permissions('open-games:write')
  @HateoasItem(GameParticipantDto)
  @ApiOperation({ summary: 'Entrar na partida' })
  join(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<GameParticipantDto> {
    return this.service.join(user.id, user.name, null, id);
  }

  @Delete(':id/leave')
  @Permissions('open-games:write')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Sair da partida' })
  leave(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<void> {
    return this.service.leave(user.id, id);
  }

  @Post(':id/finish')
  @Permissions('open-games:write')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Finalizar partida (somente organizador)' })
  finish(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<void> {
    return this.service.finish(user.id, id);
  }

  @Get(':id/participants')
  @Public()
  @HateoasList(GameParticipantDto)
  @ApiOperation({ summary: 'Listar participantes da partida' })
  getParticipants(@Param('id') id: string): Promise<GameParticipantDto[]> {
    return this.service.getParticipants(id);
  }
}
