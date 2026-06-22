'use client';
import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { CircleDot, LayoutDashboard, Building2, LogOut } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { getSession, logout } from '@/lib/auth';
import { cn } from '@/lib/utils';

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const [session, setSession] = useState<ReturnType<typeof getSession>>(null);

  useEffect(() => {
    setSession(getSession());
  }, []);

  const initial = (session?.displayName ?? session?.email ?? '·').charAt(0).toUpperCase();

  function handleLogout() {
    logout();
    router.push('/login');
  }

  return (
    <aside className="flex h-screen w-64 flex-col border-r bg-sidebar border-sidebar-border">
      {/* Logo */}
      <div className="p-5 border-b border-sidebar-border">
        <div className="flex items-center gap-3">
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-sidebar-primary/20 shrink-0">
            <CircleDot className="h-5 w-5 text-sidebar-primary" />
          </div>
          <div className="min-w-0">
            <h1 className="font-bold text-sm leading-tight text-sidebar-foreground">BolaNaRede</h1>
            <p className="text-[10px] text-sidebar-foreground/50 leading-tight mt-0.5">Painel do Dono</p>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 p-3 flex flex-col gap-0.5">
        <p className="text-[10px] font-semibold uppercase tracking-widest text-sidebar-foreground/40 px-3 py-2">
          Gestão
        </p>
        <Link
          href="/home"
          className={cn(
            'flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm transition-colors',
            pathname === '/home'
              ? 'bg-sidebar-primary text-sidebar-primary-foreground font-semibold'
              : 'text-sidebar-foreground/70 hover:bg-sidebar-accent hover:text-sidebar-accent-foreground'
          )}
        >
          <LayoutDashboard className="h-4 w-4 shrink-0" />
          Visão Geral
        </Link>
        <Link
          href="/fields"
          className={cn(
            'flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm transition-colors',
            pathname.startsWith('/fields')
              ? 'bg-sidebar-primary text-sidebar-primary-foreground font-semibold'
              : 'text-sidebar-foreground/70 hover:bg-sidebar-accent hover:text-sidebar-accent-foreground'
          )}
        >
          <Building2 className="h-4 w-4 shrink-0" />
          Meus Campos
        </Link>
      </nav>

      {/* User */}
      <div className="p-3 border-t border-sidebar-border space-y-1">
        <div className="flex items-center gap-2.5 px-3 py-2 rounded-lg">
          <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-sidebar-primary/25 text-sidebar-primary text-xs font-bold">
            {initial}
          </div>
          <p className="text-xs text-sidebar-foreground/60 truncate flex-1 min-w-0">
            {session?.displayName ?? session?.email ?? 'Usuário'}
          </p>
        </div>
        <Button
          variant="ghost"
          size="sm"
          onClick={handleLogout}
          className="w-full justify-start gap-2 text-sidebar-foreground/60 hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
        >
          <LogOut className="h-4 w-4" />
          Sair
        </Button>
      </div>
    </aside>
  );
}
