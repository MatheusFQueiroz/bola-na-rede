export type PendingMatchStatus = 'proposed' | 'accepted' | 'expired';

export class PendingMatch {
  id!: number;
  externalId!: string;
  requestAExternalId!: string;
  requestBExternalId!: string;
  userAId!: string;
  userBId!: string;
  sport!: string;
  status!: PendingMatchStatus;
  acceptedByA!: boolean;
  acceptedByB!: boolean;
  proposedAt!: Date;
  expiresAt!: Date;
  updatedAt!: Date;
}
