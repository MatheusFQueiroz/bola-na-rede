export type MatchRequestStatus = 'pending' | 'matched' | 'cancelled' | 'expired';
export type SportType = 'futsal' | 'society' | 'campo';

export class MatchRequest {
  id!: number;
  externalId!: string;
  requesterUserId!: string;
  displayName!: string;
  sport!: SportType;
  status!: MatchRequestStatus;
  requestedAt!: Date;
  expiresAt!: Date;
  updatedAt!: Date;
}
