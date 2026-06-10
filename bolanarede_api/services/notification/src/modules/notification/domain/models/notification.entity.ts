export enum NotificationType {
  MATCH_ACCEPTED = 'match_accepted',
  MATCH_EXPIRED = 'match_expired',
  MATCH_COMPLETED = 'match_completed',
  RESULT_DISPUTED = 'result_disputed',
  BADGE_AWARDED = 'badge_awarded',
}

export class Notification {
  id!: string;
  recipientUserId!: string;
  type!: NotificationType;
  title!: string;
  body!: string;
  data!: Record<string, unknown>;
  isRead!: boolean;
  createdAt!: Date;
}
