import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class PushNotificationService {
  private readonly logger = new Logger(PushNotificationService.name);

  async send(
    token: string,
    title: string,
    body: string,
    data?: Record<string, unknown>,
  ): Promise<void> {
    // Production: integrate with FCM / APNs using firebase-admin
    this.logger.log(
      `[PUSH] token=${token.slice(0, 12)}... title="${title}" body="${body}" data=${JSON.stringify(data ?? {})}`,
    );
  }
}
