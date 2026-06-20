'use client';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { LayoutDashboard, LogOut } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { getSession, logout } from '@/lib/auth';
import { cn } from '@/lib/utils';

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const session = getSession();

  function handleLogout() {
    logout();
    router.push('/login');
  }

  return (
    <aside className="flex h-screen w-60 flex-col border-r bg-card">
      <div className="p-6 border-b">
        <h1 className="font-semibold text-lg">BolaNaRede</h1>
        <p className="text-xs text-muted-foreground">Painel do Dono</p>
      </div>
      <nav className="flex-1 p-4 flex flex-col gap-1">
        <Link
          href="/fields"
          className={cn(
            'flex items-center gap-2 rounded-md px-3 py-2 text-sm transition-colors hover:bg-accent hover:text-accent-foreground',
            pathname.startsWith('/fields') && 'bg-accent text-accent-foreground font-medium'
          )}
        >
          <LayoutDashboard className="h-4 w-4" />
          Meus Campos
        </Link>
      </nav>
      <div className="p-4 border-t flex flex-col gap-2">
        <p className="text-xs text-muted-foreground truncate">{session?.displayName ?? session?.email ?? 'Usuário'}</p>
        <Button variant="outline" size="sm" onClick={handleLogout} className="w-full justify-start gap-2">
          <LogOut className="h-4 w-4" />
          Sair
        </Button>
      </div>
    </aside>
  );
}
