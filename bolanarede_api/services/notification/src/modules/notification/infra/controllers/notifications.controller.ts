import {
  Controller,
  Get,
  Patch,
  Param,
  Query,
  Request,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '@shared/infra/auth/guards/jwt-auth.guard';
import { NotificationService } from '../../application/services/notification.service';
import { NotificationResponseDto } from '../../application/dto/notification-response.dto';

interface AuthenticatedRequest {
  user: { id: string };
}

@Controller('notifications')
@ApiTags('Notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notifService: NotificationService) {}

  @Get()
  @ApiOperation({ summary: 'List my notifications (newest first, paginated)' })
  @ApiQuery({ name: 'skip', required: false, type: Number, description: 'Default 0' })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Default 20, max 100' })
  async listNotifications(
    @Request() req: AuthenticatedRequest,
    @Query('skip') skip?: string,
    @Query('limit') limit?: string,
  ): Promise<NotificationResponseDto[]> {
    const parsedSkip = Math.max(0, parseInt(skip ?? '0', 10) || 0);
    const parsedLimit = Math.min(Math.max(1, parseInt(limit ?? '20', 10) || 20), 100);
    const notifications = await this.notifService.getNotifications(
      req.user.id,
      parsedSkip,
      parsedLimit,
    );
    return notifications.map(NotificationResponseDto.from);
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Count unread notifications' })
  async getUnreadCount(@Request() req: AuthenticatedRequest): Promise<{ count: number }> {
    const count = await this.notifService.getUnreadCount(req.user.id);
    return { count };
  }

  @Patch('read')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Mark all notifications as read' })
  async markAllAsRead(@Request() req: AuthenticatedRequest): Promise<void> {
    await this.notifService.markAllAsRead(req.user.id);
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark a single notification as read' })
  async markAsRead(
    @Param('id') id: string,
    @Request() req: AuthenticatedRequest,
  ): Promise<NotificationResponseDto> {
    const notif = await this.notifService.markAsRead(id, req.user.id);
    return NotificationResponseDto.from(notif);
  }
}
