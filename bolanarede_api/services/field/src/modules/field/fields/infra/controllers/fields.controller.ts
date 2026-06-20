import {
  Body, Controller, Get, HttpCode, HttpStatus, Param, Post, Put, Query, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { FieldService } from '../../application/services/field.service';
import { AvailabilityService } from '../../application/services/availability.service';
import { CreateFieldDto } from '../../application/dto/create-field.dto';
import { CreateCourtDto } from '../../application/dto/create-court.dto';
import { SetAvailabilityDto } from '../../application/dto/set-availability.dto';
import { SearchFieldsDto } from '../../application/dto/search-fields.dto';
import { FieldDto } from '../../application/dto/field.dto';
import { FieldCourtDto } from '../../application/dto/field-court.dto';
import { FieldAvailabilityDto } from '../../application/dto/field-availability.dto';

@ApiTags('fields')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('fields')
export class FieldsController {
  constructor(
    private readonly fieldService: FieldService,
    private readonly availabilityService: AvailabilityService,
  ) {}

  @Post()
  @Permissions('fields:write')
  @HateoasItem<FieldDto>({
    basePath: '/v1/fields',
    itemLinks: (f) => ({
      self: { href: `/v1/fields/${f.id}`, method: 'GET' },
      courts: { href: `/v1/fields/${f.id}/courts`, method: 'GET' },
      availability: { href: `/v1/fields/${f.id}/availability`, method: 'GET' },
      reservations: { href: `/v1/fields/${f.id}/reservations`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Registrar campo' })
  register(
    @Body() dto: CreateFieldDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<FieldDto> {
    return this.fieldService.register(user.id, dto);
  }

  @Get()
  @Public()
  @HateoasList<FieldDto>({
    basePath: '/v1/fields',
    itemLinks: (f) => ({
      self: { href: `/v1/fields/${f.id}`, method: 'GET' },
      courts: { href: `/v1/fields/${f.id}/courts`, method: 'GET' },
      availability: { href: `/v1/fields/${f.id}/availability`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Buscar campos por cidade ou geolocalização' })
  search(@Query() query: SearchFieldsDto): Promise<FieldDto[]> {
    return this.fieldService.searchNearby({
      city: query.city,
      lat: query.lat,
      lng: query.lng,
      radiusKm: query.radius,
    });
  }

  @Get('mine')
  @Permissions('fields:read')
  @HateoasList<FieldDto>({
    basePath: '/v1/fields',
    itemLinks: (f) => ({
      self: { href: `/v1/fields/${f.id}`, method: 'GET' },
      courts: { href: `/v1/fields/${f.id}/courts`, method: 'GET' },
      availability: { href: `/v1/fields/${f.id}/availability`, method: 'GET' },
      reservations: { href: `/v1/fields/${f.id}/reservations`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Listar campos do dono autenticado' })
  getMine(@CurrentUser() user: AuthenticatedUser): Promise<FieldDto[]> {
    return this.fieldService.findByOwner(user.id);
  }

  @Get(':id')
  @Public()
  @HateoasItem<FieldDto>({
    basePath: '/v1/fields',
    itemLinks: (f) => ({
      self: { href: `/v1/fields/${f.id}`, method: 'GET' },
      courts: { href: `/v1/fields/${f.id}/courts`, method: 'GET' },
      availability: { href: `/v1/fields/${f.id}/availability`, method: 'GET' },
      reservations: { href: `/v1/fields/${f.id}/reservations`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Obter campo por ID' })
  getById(@Param('id') id: string): Promise<FieldDto> {
    return this.fieldService.getById(id);
  }

  @Get(':id/availability')
  @Public()
  @HateoasItem<FieldAvailabilityDto>({
    basePath: '/v1/fields',
    itemLinks: (f) => ({
      self: { href: `/v1/fields/${f.fieldId}/availability`, method: 'GET' },
      field: { href: `/v1/fields/${f.fieldId}`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Verificar disponibilidade do campo na data' })
  @ApiQuery({ name: 'date', description: 'Data no formato YYYY-MM-DD', example: '2026-06-15' })
  getAvailability(
    @Param('id') id: string,
    @Query('date') date: string,
  ): Promise<FieldAvailabilityDto> {
    return this.availabilityService.getAvailability(id, date);
  }

  @Post(':id/courts')
  @Permissions('fields:write')
  @HateoasItem<FieldCourtDto>({
    basePath: '/v1/fields',
    itemLinks: (c) => ({
      self: { href: `/v1/fields/${c.fieldId}/courts`, method: 'GET' },
      field: { href: `/v1/fields/${c.fieldId}`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Adicionar quadra ao campo' })
  addCourt(
    @Param('id') id: string,
    @Body() dto: CreateCourtDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<FieldCourtDto> {
    return this.fieldService.addCourt(user.id, id, dto);
  }

  @Get(':id/courts')
  @Public()
  @HateoasList<FieldCourtDto>({
    basePath: '/v1/fields',
    itemLinks: (c) => ({
      self: { href: `/v1/fields/${c.fieldId}/courts`, method: 'GET' },
      field: { href: `/v1/fields/${c.fieldId}`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Listar quadras do campo' })
  getCourts(@Param('id') id: string): Promise<FieldCourtDto[]> {
    return this.fieldService.getCourts(id);
  }

  @Put(':id/courts/:courtId/availability')
  @Permissions('fields:write')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Definir disponibilidade semanal da quadra' })
  setAvailability(
    @Param('id') id: string,
    @Param('courtId') courtId: string,
    @Body() dto: SetAvailabilityDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<void> {
    return this.fieldService.setAvailability(user.id, id, courtId, dto.slots);
  }
}
