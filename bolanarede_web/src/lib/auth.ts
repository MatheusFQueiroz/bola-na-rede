import Cookies from 'js-cookie';

const TOKEN_COOKIE = 'bnr_token';
const SESSION_KEY = 'bnr_session';

export interface Session {
  userId: string;
  displayName: string;
  email: string;
}

export function getToken(): string | undefined {
  return Cookies.get(TOKEN_COOKIE);
}

export function setToken(token: string): void {
  Cookies.set(TOKEN_COOKIE, token, { expires: 7, sameSite: 'lax' });
}

export function clearToken(): void {
  Cookies.remove(TOKEN_COOKIE);
}

export function setSession(session: Session): void {
  if (typeof window !== 'undefined') {
    localStorage.setItem(SESSION_KEY, JSON.stringify(session));
  }
}

export function getSession(): Session | null {
  if (typeof window === 'undefined') return null;
  const raw = localStorage.getItem(SESSION_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as Session;
  } catch {
    return null;
  }
}

export function clearSession(): void {
  if (typeof window !== 'undefined') {
    localStorage.removeItem(SESSION_KEY);
  }
}

export function logout(): void {
  clearToken();
  clearSession();
}
