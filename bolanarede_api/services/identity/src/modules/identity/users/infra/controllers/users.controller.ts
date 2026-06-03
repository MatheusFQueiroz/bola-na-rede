import { Body, Controller, Get, Param, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { UserService } from '../../application/services/user.service';
import { UserMessagingService } from '../../application/services/user-messaging.service';
import { UpdateProfileDto } from '../../application/dto/update-profile.dto';
import { UserDto } from '../../application/dto/user.dto';

@ApiTags('users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('users')
export class UsersController {
  constructor(
    private readonly userService: UserService,
    private readonly messagingService: UserMessagingService,
  ) {}

  @Get('me')
  @Permissions('players:read')
  @HateoasItem(UserDto)
  @ApiOperation({ summary: 'Obter perfil do usuário autenticado' })
  getMe(@CurrentUser() user: AuthenticatedUser): Promise<UserDto> {
    return this.userService.getProfile(user.id);
  }

  @Put('me/profile')
  @Permissions('players:write')
  @HateoasItem(UserDto)
  @ApiOperation({ summary: 'Atualizar perfil do usuário autenticado' })
  updateProfile(
    @Body() dto: UpdateProfileDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<UserDto> {
    return this.userService.updateProfile(user.id, dto, this.messagingService);
  }

  @Get(':id/profile')
  @Public()
  @HateoasItem(UserDto)
  @ApiOperation({ summary: 'Obter perfil público de um usuário' })
  getPublicProfile(@Param('id') id: string): Promise<UserDto> {
    return this.userService.getPublicProfile(id);
  }
}
