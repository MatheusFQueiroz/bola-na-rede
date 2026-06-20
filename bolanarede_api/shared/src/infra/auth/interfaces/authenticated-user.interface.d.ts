export interface AuthenticatedUser {
    id: string;
    name: string;
    email: string;
    permissions: string[];
}
