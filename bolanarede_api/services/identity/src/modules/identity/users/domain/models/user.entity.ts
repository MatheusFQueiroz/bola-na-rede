export class User {
  id!: string;       // maps to users.external_id (UUID)
  email!: string | null;
  phone!: string | null;
  status!: 'ACTIVE' | 'ANONYMIZED';
  createdAt!: Date;
  updatedAt!: Date;
  deletedAt!: Date | null;
}
