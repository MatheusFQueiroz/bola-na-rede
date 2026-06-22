'use client';
import { use } from 'react';
import { usePathname } from 'next/navigation';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import { useField } from '@/hooks/use-fields';

const TABS = [
  { label: 'Quadras', segment: 'courts' },
  { label: 'Disponibilidade', segment: 'availability' },
  { label: 'Reservas', segment: 'reservations' },
  { label: 'Planos', segment: 'plans' },
];

export default function FieldLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const pathname = usePathname();
  const { data: field } = useField(id);

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-start gap-3">
        <Button variant="ghost" size="sm" nativeButton={false} render={<Link href="/fields" />} className="mt-0.5 shrink-0">
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div className="min-w-0">
          <h1 className="text-2xl font-bold tracking-tight leading-tight">
            {field?.name ?? 'Carregando...'}
          </h1>
          {field?.city && (
            <p className="text-sm text-muted-foreground mt-0.5">
              {field.city} · {field.address}
            </p>
          )}
        </div>
      </div>

      <div className="border-b flex gap-0">
        {TABS.map(tab => {
          const href = `/fields/${id}/${tab.segment}`;
          const isActive = pathname === href;
          return (
            <Link
              key={tab.segment}
              href={href}
              className={cn(
                'px-4 py-2.5 text-sm font-medium border-b-2 transition-colors',
                isActive
                  ? 'border-primary text-primary'
                  : 'border-transparent text-muted-foreground hover:text-foreground hover:border-border'
              )}
            >
              {tab.label}
            </Link>
          );
        })}
      </div>

      {children}
    </div>
  );
}
