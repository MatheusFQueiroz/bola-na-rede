import { Body, Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '@shared/infra/auth/guards/permissions.guard';
import { CurrentUser } from '@shared/infra/decorators/current-user.decorator';
import { Permissions } from '@shared/infra/decorators/permissions.decorator';
import { Public } from '@shared/infra/decorators/public.decorator';
import { HateoasItem, HateoasList } from '@shared/infra/hateoas';
import type { AuthenticatedUser } from '@shared/infra/auth/interfaces/authenticated-user.interface';
import { RecurringPlanService } from '../../application/services/recurring-plan.service';
import { CreateRecurringPlanDto } from '../../application/dto/create-recurring-plan.dto';
import { RecurringPlanDto } from '../../application/dto/recurring-plan.dto';

@ApiTags('plans')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('fields/:fieldId/plans')
export class PlansController {
  constructor(private readonly planService: RecurringPlanService) {}

  @Post()
  @Permissions('fields:write')
  @HateoasItem<RecurringPlanDto>({
    basePath: '/v1/fields',
    itemLinks: (p) => ({
      self: { href: `/v1/fields/${p.fieldId}/plans`, method: 'GET' },
      field: { href: `/v1/fields/${p.fieldId}`, method: 'GET' },
      court: { href: `/v1/fields/${p.fieldId}/courts`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Criar plano recorrente para uma quadra' })
  create(
    @Param('fieldId') fieldId: string,
    @Body() dto: CreateRecurringPlanDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<RecurringPlanDto> {
    return this.planService.create(user.id, fieldId, dto);
  }

  @Get()
  @Public()
  @HateoasList<RecurringPlanDto>({
    basePath: '/v1/fields',
    itemLinks: (p) => ({
      self: { href: `/v1/fields/${p.fieldId}/plans`, method: 'GET' },
      field: { href: `/v1/fields/${p.fieldId}`, method: 'GET' },
    }),
  })
  @ApiOperation({ summary: 'Listar planos recorrentes do campo' })
  list(@Param('fieldId') fieldId: string): Promise<RecurringPlanDto[]> {
    return this.planService.getByField(fieldId);
  }

  @Delete('slots/:slotId/release')
  @Permissions('fields:write')
  @ApiOperation({ summary: 'Liberar slot de plano recorrente para reserva avulsa' })
  releaseSlot(
    @Param('fieldId') fieldId: string,
    @Param('slotId') slotId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<{ id: string; status: string }> {
    return this.planService.releaseSlot(user.id, fieldId, slotId);
  }
}
