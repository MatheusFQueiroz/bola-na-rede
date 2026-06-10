import { ApiProperty } from '@nestjs/swagger';
import { NotificationType, type Notification } from '../../domain/models/notification.entity';

export class NotificationResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() recipientUserId!: string;
  @ApiProperty({ enum: NotificationType }) type!: NotificationType;
  @ApiProperty() title!: string;
  @ApiProperty() body!: string;
  @ApiProperty() data!: Record<string, unknown>;
  @ApiProperty() isRead!: boolean;
  @ApiProperty() createdAt!: Date;

  static from(n: Notification): NotificationResponseDto {
    const dto = new NotificationResponseDto();
    dto.id = n.id;
    dto.recipientUserId = n.recipientUserId;
    dto.type = n.type;
    dto.title = n.title;
    dto.body = n.body;
    dto.data = n.data;
    dto.isRead = n.isRead;
    dto.createdAt = n.createdAt;
    return dto;
  }
}
