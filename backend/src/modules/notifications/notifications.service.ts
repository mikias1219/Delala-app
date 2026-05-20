import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from './entities/notification.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private readonly notificationsRepo: Repository<Notification>,
  ) {}

  async listForUser(userId: string) {
    return this.notificationsRepo.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  async create(userId: string, type: string, payload: Record<string, unknown>) {
    const notification = this.notificationsRepo.create({
      userId,
      type,
      payloadJson: payload,
      sentAt: new Date(),
    });
    return this.notificationsRepo.save(notification);
  }

  async markRead(id: string, userId: string) {
    const notification = await this.notificationsRepo.findOne({
      where: { id, userId },
    });
    if (!notification) {
      return null;
    }
    notification.readAt = new Date();
    return this.notificationsRepo.save(notification);
  }
}
