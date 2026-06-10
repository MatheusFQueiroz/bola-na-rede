import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import type {
  DeviceTokenRepositoryInterface,
  UpsertDeviceTokenData,
} from '../../../domain/repositories/device-token-repository.interface';
import type { DeviceToken } from '../../../domain/models/device-token.entity';
import { DeviceTokenDoc, type DeviceTokenDocument } from '../../schemas/device-token.schema';

@Injectable()
export class MongooseDeviceTokenRepository implements DeviceTokenRepositoryInterface {
  constructor(
    @InjectModel(DeviceTokenDoc.name)
    private readonly model: Model<DeviceTokenDocument>,
  ) {}

  private toEntity(doc: DeviceTokenDocument): DeviceToken {
    return {
      id: doc._id.toString(),
      userId: doc.userId,
      token: doc.token,
      platform: doc.platform,
      updatedAt: doc.updatedAt ?? new Date(),
    };
  }

  async upsert(data: UpsertDeviceTokenData): Promise<DeviceToken> {
    const doc = await this.model
      .findOneAndUpdate(
        { userId: data.userId },
        { $set: { token: data.token, platform: data.platform } },
        { upsert: true, new: true },
      )
      .exec();
    return this.toEntity(doc!);
  }

  async findByUserId(userId: string): Promise<DeviceToken | null> {
    const doc = await this.model.findOne({ userId }).exec();
    return doc ? this.toEntity(doc) : null;
  }
}
