import { Body, Controller, Delete, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { ReservationService } from '../../application/services/reservation.service';
import { CreateReservationDto } from '../../application/dto/create-reservation.dto';
import { ReservationDto } from '../../application/dto/reservation.dto';

@ApiTags('reservations')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('fields/:fieldId/reservations')
export class ReservationsController {
  constructor(private readonly reservationService: ReservationService) {}

  @Post()
  @Permissions('fields:write')
  @HateoasItem<ReservationDto>({
    basePath: '/v1/fields',
    itemLinks: (r) => ({
      self: { href: `/v1/fields/${r.fieldId}/reservations/${r.id}`, method: 'GET' },
      cancel: { href: `/v1/fields/${r.fieldId}/reservations/${r.id}`, method: 'DELETE' },
      field: { href: `/v1/fields/${r.fieldId}`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Criar reserva manual/por telefone' })
  create(
    @Param('fieldId') fieldId: string,
    @Body() dto: CreateReservationDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ReservationDto> {
    return this.reservationService.createManual(user.id, fieldId, dto);
  }

  @Get()
  @Permissions('fields:write')
  @HateoasList<ReservationDto>({
    basePath: '/v1/fields',
    itemLinks: (r) => ({
      self: { href: `/v1/fields/${r.fieldId}/reservations/${r.id}`, method: 'GET' },
      cancel: { href: `/v1/fields/${r.fieldId}/reservations/${r.id}`, method: 'DELETE' },
      field: { href: `/v1/fields/${r.fieldId}`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Listar reservas do campo' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  list(
    @Param('fieldId') fieldId: string,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ): Promise<ReservationDto[]> {
    return this.reservationService.list(fieldId, Number(page), Number(limit));
  }

  @Delete(':reservationId')
  @Permissions('fields:write')
  @HateoasItem<ReservationDto>({
    basePath: '/v1/fields',
    itemLinks: (r) => ({
      self: { href: `/v1/fields/${r.fieldId}/reservations`, method: 'GET' },
      field: { href: `/v1/fields/${r.fieldId}`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Cancelar reserva' })
  cancel(
    @Param('fieldId') fieldId: string,
    @Param('reservationId') reservationId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ReservationDto> {
    return this.reservationService.cancel(user.id, fieldId, reservationId);
  }
}
