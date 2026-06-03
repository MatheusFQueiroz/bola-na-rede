import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import type { RecurringPlan } from '../../domain/models/recurring-plan.entity';

export class RecurringPlanDto {
  @ApiProperty() id!: string;
  @ApiProperty() courtId!: string;
  @ApiProperty() fieldId!: string;
  @ApiPropertyOptional() playerUserId!: string | null;
  @ApiProperty() dayOfWeek!: number;
  @ApiProperty() startTime!: string;
  @ApiProperty() endTime!: string;
  @ApiProperty() planStartsAt!: Date;
  @ApiPropertyOptional() planEndsAt!: Date | null;
  @ApiProperty() isActive!: boolean;
  @ApiProperty() createdAt!: Date;

  static from(plan: RecurringPlan): RecurringPlanDto {
    const dto = new RecurringPlanDto();
    dto.id = plan.id;
    dto.courtId = plan.courtId;
    dto.fieldId = plan.fieldId;
    dto.playerUserId = plan.playerUserId;
    dto.dayOfWeek = plan.dayOfWeek;
    dto.startTime = plan.startTime;
    dto.endTime = plan.endTime;
    dto.planStartsAt = plan.planStartsAt;
    dto.planEndsAt = plan.planEndsAt;
    dto.isActive = plan.isActive;
    dto.createdAt = plan.createdAt;
    return dto;
  }
}
