import { NextRequest, NextResponse } from 'next/server';

export function proxy(request: NextRequest) {
  const token = request.cookies.get('bnr_token')?.value;
  const { pathname } = request.nextUrl;

  const isDashboard = pathname.startsWith('/fields') || pathname === '/';

  if (isDashboard && !token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  if (pathname === '/login' && token) {
    return NextResponse.redirect(new URL('/fields', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/', '/login', '/fields/:path*'],
};
