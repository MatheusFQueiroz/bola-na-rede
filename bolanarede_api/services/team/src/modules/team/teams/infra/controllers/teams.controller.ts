import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { TeamService } from '../../application/services/team.service';
import { CreateTeamDto } from '../../application/dto/create-team.dto';
import { UpdateTeamDto } from '../../application/dto/update-team.dto';
import { TransferCaptaincyDto } from '../../application/dto/transfer-captaincy.dto';
import { TeamDto } from '../../application/dto/team.dto';
import { TeamMemberDto } from '../../application/dto/team-member.dto';

@ApiTags('teams')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('teams')
export class TeamsController {
  constructor(private readonly teamService: TeamService) {}

  @Post()
  @Permissions('teams:write')
  @HateoasItem<TeamDto>({
    basePath: '/v1/teams',
    itemLinks: (t) => ({
      self: { href: `/v1/teams/${t.id}`, method: 'GET' },
      update: { href: `/v1/teams/${t.id}`, method: 'PUT' },
      delete: { href: `/v1/teams/${t.id}`, method: 'DELETE' },
      members: { href: `/v1/teams/${t.id}/members`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Criar equipe' })
  create(
    @Body() dto: CreateTeamDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<TeamDto> {
    return this.teamService.create(user.id, user.name, dto);
  }

  @Get()
  @HateoasList<TeamDto>({
    basePath: '/v1/teams',
    itemLinks: (t) => ({
      self: { href: `/v1/teams/${t.id}`, method: 'GET' },
      update: { href: `/v1/teams/${t.id}`, method: 'PUT' },
      members: { href: `/v1/teams/${t.id}/members`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Listar times do usuário autenticado' })
  list(@CurrentUser() user: AuthenticatedUser): Promise<TeamDto[]> {
    return this.teamService.listByUser(user.id);
  }

  @Get(':id')
  @Public()
  @HateoasItem<TeamDto>({
    basePath: '/v1/teams',
    itemLinks: (t) => ({
      self: { href: `/v1/teams/${t.id}`, method: 'GET' },
      update: { href: `/v1/teams/${t.id}`, method: 'PUT' },
      delete: { href: `/v1/teams/${t.id}`, method: 'DELETE' },
      members: { href: `/v1/teams/${t.id}/members`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Obter detalhes da equipe' })
  getTeam(@Param('id') id: string): Promise<TeamDto> {
    return this.teamService.getTeam(id);
  }

  @Put(':id')
  @Permissions('teams:write')
  @HateoasItem<TeamDto>({
    basePath: '/v1/teams',
    itemLinks: (t) => ({
      self: { href: `/v1/teams/${t.id}`, method: 'GET' },
      update: { href: `/v1/teams/${t.id}`, method: 'PUT' },
      delete: { href: `/v1/teams/${t.id}`, method: 'DELETE' },
    }),
  })
  @ApiOperation({ summary: 'Atualizar equipe (somente capitão)' })
  update(
    @Param('id') id: string,
    @Body() dto: UpdateTeamDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<TeamDto> {
    return this.teamService.update(user.id, id, dto);
  }

  @Delete(':id')
  @Permissions('teams:write')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Desativar equipe (somente capitão)' })
  deactivate(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<void> {
    return this.teamService.deactivate(user.id, id);
  }

  @Post(':id/members')
  @Permissions('teams:write')
  @HateoasItem<TeamMemberDto>({
    basePath: '/v1/teams',
    itemLinks: (_m) => ({
      self: { href: `/v1/teams`, method: 'GET' },
      leave: { href: `/v1/teams`, method: 'DELETE' },
    }),
  })
  @ApiOperation({ summary: 'Entrar na equipe' })
  join(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<TeamMemberDto> {
    return this.teamService.join(user.id, user.name, id);
  }

  @Delete(':id/members/me')
  @Permissions('teams:write')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Sair da equipe' })
  leave(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<void> {
    return this.teamService.leave(user.id, id);
  }

  @Delete(':id/members/:playerId')
  @Permissions('teams:write')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Remover membro da equipe (somente capitão)' })
  removeMember(
    @Param('id') id: string,
    @Param('playerId') playerId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<void> {
    return this.teamService.removeMember(user.id, id, playerId);
  }

  @Put(':id/captain')
  @Permissions('teams:write')
  @HateoasItem<TeamDto>({
    basePath: '/v1/teams',
    itemLinks: (t) => ({
      self: { href: `/v1/teams/${t.id}`, method: 'GET' },
      update: { href: `/v1/teams/${t.id}`, method: 'PUT' },
    }),
  })
  @ApiOperation({ summary: 'Transferir capitania' })
  transferCaptaincy(
    @Param('id') id: string,
    @Body() dto: TransferCaptaincyDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<TeamDto> {
    return this.teamService.transferCaptaincy(user.id, id, dto);
  }

  @Get(':id/members')
  @Public()
  @HateoasList<TeamMemberDto>({
    basePath: '/v1/teams',
    itemLinks: (m) => ({
      self: { href: `/v1/users/${m.playerUserId}/profile`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Listar membros da equipe' })
  getMembers(@Param('id') id: string): Promise<TeamMemberDto[]> {
    return this.teamService.getMembers(id);
  }
}
