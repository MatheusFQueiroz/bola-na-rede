export declare class User {
    id: string;
    email: string | null;
    phone: string | null;
    status: 'ACTIVE' | 'ANONYMIZED';
    createdAt: Date;
    updatedAt: Date;
    deletedAt: Date | null;
}
