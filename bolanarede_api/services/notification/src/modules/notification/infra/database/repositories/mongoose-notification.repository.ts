import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import type {
  NotificationRepositoryInterface,
  CreateNotificationData,
} from '../../../domain/repositories/notification-repository.interface';
import type { Notification } from '../../../domain/models/notification.entity';
import { NotificationDoc, type NotificationDocument } from '../../schemas/notification.schema';

@Injectable()
export class MongooseNotificationRepository implements NotificationRepositoryInterface {
  constructor(
    @InjectModel(NotificationDoc.name)
    private readonly model: Model<NotificationDocument>,
  ) {}

  private toEntity(doc: NotificationDocument): Notification {
    return {
      id: doc._id.toString(),
      recipientUserId: doc.recipientUserId,
      type: doc.type,
      title: doc.title,
      body: doc.body,
      data: doc.data,
      isRead: doc.isRead,
      createdAt: doc.createdAt ?? new Date(),
    };
  }

  async create(data: CreateNotificationData): Promise<Notification> {
    const doc = await this.model.create(data);
    return this.toEntity(doc);
  }

  async findByUserId(userId: string, skip: number, limit: number): Promise<Notification[]> {
    const docs = await this.model
      .find({ recipientUserId: userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .exec();
    return docs.map((d) => this.toEntity(d));
  }

  async findById(id: string, userId: string): Promise<Notification | null> {
    const doc = await this.model.findOne({ _id: id, recipientUserId: userId }).exec();
    return doc ? this.toEntity(doc) : null;
  }

  async markAsRead(id: string, userId: string): Promise<Notification | null> {
    const doc = await this.model
      .findOneAndUpdate(
        { _id: id, recipientUserId: userId },
        { $set: { isRead: true } },
        { new: true },
      )
      .exec();
    return doc ? this.toEntity(doc) : null;
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.model
      .updateMany({ recipientUserId: userId, isRead: false }, { $set: { isRead: true } })
      .exec();
  }

  async countUnread(userId: string): Promise<number> {
    return this.model.countDocuments({ recipientUserId: userId, isRead: false }).exec();
  }
}
