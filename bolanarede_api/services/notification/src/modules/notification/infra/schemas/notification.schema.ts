import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { NotificationType } from '../../domain/models/notification.entity';

export type NotificationDocument = NotificationDoc & Document;

@Schema({ timestamps: true, collection: 'notifications' })
export class NotificationDoc {
  @Prop({ required: true }) recipientUserId!: string;
  @Prop({ required: true, enum: NotificationType }) type!: NotificationType;
  @Prop({ required: true }) title!: string;
  @Prop({ required: true }) body!: string;
  @Prop({ type: Object, default: {} }) data!: Record<string, unknown>;
  @Prop({ default: false }) isRead!: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(NotificationDoc);
NotificationSchema.index({ recipientUserId: 1, createdAt: -1 });
NotificationSchema.index({ recipientUserId: 1, isRead: 1 });
