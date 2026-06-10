import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import type { DevicePlatform } from '../../domain/models/device-token.entity';

export type DeviceTokenDocument = DeviceTokenDoc & Document;

@Schema({ timestamps: true, collection: 'device_tokens' })
export class DeviceTokenDoc {
  @Prop({ required: true, unique: true }) userId!: string;
  @Prop({ required: true }) token!: string;
  @Prop({ required: true, enum: ['ios', 'android', 'web'] }) platform!: DevicePlatform;
  updatedAt?: Date;
}

export const DeviceTokenSchema = SchemaFactory.createForClass(DeviceTokenDoc);
DeviceTokenSchema.index({ userId: 1 }, { unique: true });
