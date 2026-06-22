'use client';

import Link from 'next/link';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import {
  Building2,
  Goal,
  CalendarDays,
  Clock,
  TrendingUp,
  CheckCircle2,
  XCircle,
  ChevronRight,
} from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { useDashboardStats, type DayBucket } from '@/hooks/use-dashboard-stats';
import { cn } from '@/lib/utils';

// ─── Stat card ────────────────────────────────────────────────────────────────

interface StatCardProps {
  label: string;
  value: string | number;
  sub?: string;
  icon: React.ElementType;
  accent?: string;
  loading?: boolean;
}

function StatCard({ label, value, sub, icon: Icon, accent = 'text-primary', loading }: StatCardProps) {
  return (
    <div className="flex flex-col gap-3 rounded-xl bg-card ring-1 ring-foreground/10 p-5">
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">{label}</p>
        <div className={cn('p-2 rounded-lg bg-primary/10', accent.replace('text-', 'bg-').replace('primary', 'primary/10'))}>
          <Icon className={cn('h-4 w-4', accent)} />
        </div>
      </div>
      {loading ? (
        <div className="h-8 w-20 rounded-md bg-muted animate-pulse" />
      ) : (
        <p className="text-3xl font-bold tracking-tight">{value}</p>
      )}
      {sub && <p className="text-xs text-muted-foreground">{sub}</p>}
    </div>
  );
}

// ─── Bar chart ────────────────────────────────────────────────────────────────

function ReservationsChart({ data }: { data: DayBucket[] }) {
  const maxCount = Math.max(1, ...data.map(d => d.count));

  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-stretch gap-px h-24 w-full">
        {data.map((d, i) => (
          <div
            key={i}
            className="group/bar flex-1 flex flex-col justify-end cursor-default"
            title={`${d.label}: ${d.count} reserva${d.count !== 1 ? 's' : ''}`}
          >
            <div
              className={cn(
                'w-full rounded-t-[2px] transition-colors',
                d.count === 0
                  ? 'bg-muted'
                  : 'bg-primary/50 group-hover/bar:bg-primary'
              )}
              style={{
                height: d.count === 0 ? '3px' : `${(d.count / maxCount) * 100}%`,
              }}
            />
          </div>
        ))}
      </div>
      {/* Labels every 5 days */}
      <div className="flex">
        {data.map((d, i) => (
          <div key={i} className="flex-1 text-center">
            {i % 5 === 0 && (
              <span className="text-[9px] text-muted-foreground">{d.label}</span>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Status badge ─────────────────────────────────────────────────────────────

function StatusBadge({ status }: { status: string }) {
  const map: Record<string, { label: string; variant: 'default' | 'secondary' | 'destructive' }> = {
    confirmed: { label: 'Confirmada', variant: 'default' },
    pending: { label: 'Pendente', variant: 'secondary' },
    cancelled: { label: 'Cancelada', variant: 'destructive' },
  };
  const { label, variant } = map[status] ?? { label: status, variant: 'secondary' };
  return <Badge variant={variant}>{label}</Badge>;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function HomePage() {
  const stats = useDashboardStats();
  const monthLabel = format(new Date(), 'MMMM yyyy', { locale: ptBR });

  const cancellationRate =
    stats.thisMonthTotal > 0
      ? Math.round((stats.thisMonthCancelled / stats.thisMonthTotal) * 100)
      : 0;

  return (
    <div className="flex flex-col gap-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Visão Geral</h1>
        <p className="text-sm text-muted-foreground mt-0.5 capitalize">{monthLabel}</p>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="Campos ativos"
          value={stats.totalFields}
          sub={`${stats.totalCourts} quadra${stats.totalCourts !== 1 ? 's' : ''} no total`}
          icon={Building2}
          loading={stats.isLoading}
        />
        <StatCard
          label="Reservas este mês"
          value={stats.thisMonthTotal}
          sub={`${stats.thisMonthConfirmed} confirmadas · ${stats.thisMonthCancelled} canceladas`}
          icon={CalendarDays}
          loading={stats.isLoading}
        />
        <StatCard
          label="Horas confirmadas"
          value={`${stats.hoursBooked}h`}
          sub={cancellationRate > 0 ? `${cancellationRate}% taxa de cancelamento` : 'sem cancelamentos'}
          icon={Clock}
          accent="text-blue-500"
          loading={stats.isLoading}
        />
        <StatCard
          label="Faturamento estimado"
          value={
            stats.thisMonthConfirmed === 0
              ? '—'
              : `R$ ${stats.revenueThisMonth.toFixed(2).replace('.', ',')}`
          }
          sub={
            stats.revenueIsPartial
              ? 'Parcial — algumas quadras sem preço'
              : stats.thisMonthConfirmed > 0
              ? `${stats.hoursBooked}h confirmadas`
              : 'Sem reservas confirmadas este mês'
          }
          icon={TrendingUp}
          accent="text-emerald-500"
          loading={stats.isLoading}
        />
      </div>

      {/* Status breakdown + Chart */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Breakdown */}
        <div className="rounded-xl bg-card ring-1 ring-foreground/10 p-5 flex flex-col gap-4">
          <p className="text-sm font-semibold">Situação das reservas</p>
          {stats.isLoading ? (
            <div className="space-y-3">
              {[1, 2, 3].map(i => (
                <div key={i} className="h-8 rounded-md bg-muted animate-pulse" />
              ))}
            </div>
          ) : stats.thisMonthTotal === 0 ? (
            <p className="text-sm text-muted-foreground py-4 text-center">Sem reservas este mês.</p>
          ) : (
            <div className="flex flex-col gap-3">
              {[
                { label: 'Confirmadas', count: stats.thisMonthConfirmed, icon: CheckCircle2, color: 'text-primary' },
                { label: 'Canceladas', count: stats.thisMonthCancelled, icon: XCircle, color: 'text-destructive' },
              ].map(({ label, count, icon: Icon, color }) => (
                <div key={label} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Icon className={cn('h-4 w-4', color)} />
                    <span className="text-sm">{label}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-24 h-1.5 rounded-full bg-muted overflow-hidden">
                      <div
                        className={cn(
                          'h-full rounded-full',
                          color === 'text-primary' ? 'bg-primary' :
                          color === 'text-amber-500' ? 'bg-amber-500' : 'bg-destructive'
                        )}
                        style={{
                          width: `${stats.thisMonthTotal > 0 ? (count / stats.thisMonthTotal) * 100 : 0}%`,
                        }}
                      />
                    </div>
                    <span className="text-sm font-semibold w-5 text-right">{count}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Chart */}
        <div className="lg:col-span-2 rounded-xl bg-card ring-1 ring-foreground/10 p-5 flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <p className="text-sm font-semibold">Reservas nos últimos 30 dias</p>
            <span className="text-xs text-muted-foreground">
              {stats.byDay.reduce((s, d) => s + d.count, 0)} total
            </span>
          </div>
          {stats.isLoading ? (
            <div className="h-24 rounded-md bg-muted animate-pulse" />
          ) : (
            <ReservationsChart data={stats.byDay} />
          )}
        </div>
      </div>

      {/* Upcoming reservations */}
      <div className="rounded-xl bg-card ring-1 ring-foreground/10 overflow-hidden">
        <div className="px-5 py-4 border-b border-border flex items-center justify-between">
          <p className="text-sm font-semibold">Próximas Reservas</p>
          <Button
            nativeButton={false}
            render={<Link href="/fields" />}
            variant="ghost"
            size="sm"
            className="text-xs gap-1 text-muted-foreground"
          >
            Ver campos
            <ChevronRight className="h-3 w-3" />
          </Button>
        </div>

        {stats.isLoading ? (
          <div className="p-5 space-y-3">
            {[1, 2, 3].map(i => (
              <div key={i} className="h-10 rounded-md bg-muted animate-pulse" />
            ))}
          </div>
        ) : stats.upcoming.length === 0 ? (
          <div className="py-12 text-center text-muted-foreground">
            <Goal className="h-10 w-10 mx-auto mb-3 opacity-20" />
            <p className="text-sm font-medium">Sem reservas futuras</p>
            <p className="text-xs mt-1">As próximas reservas aparecerão aqui.</p>
          </div>
        ) : (
          <div className="divide-y divide-border">
            {stats.upcoming.map(r => (
              <div key={r.id} className="flex items-center justify-between px-5 py-3 hover:bg-muted/40 transition-colors">
                <div className="flex items-center gap-4 min-w-0">
                  <div className="shrink-0 text-center">
                    <p className="text-xs font-bold text-primary leading-tight">
                      {format(new Date(r.startsAt), 'dd', { locale: ptBR })}
                    </p>
                    <p className="text-[10px] text-muted-foreground uppercase">
                      {format(new Date(r.startsAt), 'MMM', { locale: ptBR })}
                    </p>
                  </div>
                  <div className="w-px h-8 bg-border shrink-0" />
                  <div className="min-w-0">
                    <p className="text-sm font-medium truncate">
                      {r.courtName ?? 'Quadra'} · {r.fieldName}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {format(new Date(r.startsAt), 'HH:mm')} – {format(new Date(r.endsAt), 'HH:mm')}
                      {' · '}
                      <span className="capitalize">{r.channel}</span>
                    </p>
                  </div>
                </div>
                <StatusBadge status={r.status} />
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
