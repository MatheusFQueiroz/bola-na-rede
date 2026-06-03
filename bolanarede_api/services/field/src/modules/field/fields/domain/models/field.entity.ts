export class Field {
  id!: string;           // UUID (external_id)
  name!: string;
  description!: string | null;
  city!: string;
  address!: string;
  lat!: number;
  lng!: number;
  ownerUserId!: string;  // UUID do dono (text, sem FK)
  isActive!: boolean;
  createdAt!: Date;
  updatedAt!: Date;
}
