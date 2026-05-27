export interface AuthenticatedUser {
  id: string;          // users.external_id (UUID)
  name: string;        // player_profiles.display_name
  email: string;
  permissions: string[];
}
