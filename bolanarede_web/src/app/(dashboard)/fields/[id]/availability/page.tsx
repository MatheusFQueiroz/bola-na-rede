'use client';
import { use, useState, useMemo } from 'react';
import { addDays, startOfWeek, format, isSameDay } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { ChevronLeft, ChevronRight, Smartphone, Phone, ClipboardList } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Badge } from '@/components/ui/badge';
import { useCourts, type CourtDto } from '@/hooks/use-courts';
import { useCourtWeeklySlots } from '@/hooks/use-availability';
import { useReservations, useCreateReservation, useCancelReservation, type ReservationDto } from '@/hooks/use-reservations';
import { api } from '@/lib/api';
import { cn } from '@/lib/utils';
import { toast } from 'sonner';

const HOURS = Array.from({ length: 17 }, (_, i) => i + 6); // 06–22

const CHANNEL_LABEL: Record<string, string> = {
  app: 'App',
  manual: 'Manual',
  phone: 'Telefone',
};

const CHANNEL_ICON: Record<string, React.ElementType> = {
  app: Smartphone,
  manual: ClipboardList,
  phone: Phone,
};

interface PlayerProfile { displayName?: string; phone?: string | null; email?: string | null; }

interface ClickedCell {
  date: Date;
  hour: number;
  reservation?: ReservationDto;
}

export default function AvailabilityPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { data: courts, isLoading } = useCourts(id);
  const [selectedCourtId, setSelectedCourtId] = useState('');
  const [weekOffset, setWeekOffset] = useState(0);
  const [clickedCell, setClickedCell] = useState<ClickedCell | null>(null);

  const { data: templateSlots = [] } = useCourtWeeklySlots(id, selectedCourtId);
  const { data: reservations = [] } = useReservations(id);
  const createReservation = useCreateReservation(id);
  const cancelReservation = useCancelReservation(id);

  const weekStart = useMemo(() => {
    const base = startOfWeek(new Date(), { weekStartsOn: 1 });
    return addDays(base, weekOffset * 7);
  }, [weekOffset]);

  const weekDays = useMemo(
    () => Array.from({ length: 7 }, (_, i) => addDays(weekStart, i)),
    [weekStart],
  );

  function isInTemplate(jsDay: number, hour: number): boolean {
    return templateSlots.some(slot => {
      if (slot.dayOfWeek !== jsDay || !slot.isAvailable) return false;
      const start = parseInt(slot.startTime.split(':')[0]);
      const end = parseInt(slot.endTime.split(':')[0]);
      return hour >= start && hour < end;
    });
  }

  function getReservation(date: Date, hour: number): ReservationDto | undefined {
    if (!selectedCourtId) return undefined;
    return reservations.find(r => {
      if (r.courtId !== selectedCourtId || r.status !== 'confirmed') return false;
      const start = new Date(r.startsAt);
      return isSameDay(start, date) && start.getHours() === hour;
    });
  }

  async function handleConfirm() {
    if (!clickedCell || !selectedCourtId) return;
    const { date, hour, reservation } = clickedCell;
    try {
      if (reservation) {
        await cancelReservation.mutateAsync(reservation.id);
        toast.success('Reserva cancelada.');
      } else {
        const startsAt = new Date(date);
        startsAt.setHours(hour, 0, 0, 0);
        const endsAt = new Date(date);
        endsAt.setHours(hour + 1, 0, 0, 0);
        await createReservation.mutateAsync({
          courtId: selectedCourtId,
          startsAt: startsAt.toISOString(),
          endsAt: endsAt.toISOString(),
        });
        toast.success('Reserva criada.');
      }
      setClickedCell(null);
    } catch {
      toast.error('Erro ao processar reserva.');
    }
  }

  const isPending = createReservation.isPending || cancelReservation.isPending;

  const playerUserId = clickedCell?.reservation?.playerUserId ?? null;
  const { data: playerProfile } = useQuery<PlayerProfile>({
    queryKey: ['user-profile', playerUserId],
    queryFn: async () => {
      const res = await api.get(`/v1/users/${playerUserId}/profile`);
      return res.data.data ?? res.data;
    },
    enabled: !!playerUserId,
    staleTime: 5 * 60 * 1000,
  });

  const now = useMemo(() => new Date(), []);

  if (isLoading) return <p className="text-muted-foreground text-sm">Carregando quadras...</p>;

  const selectedCourt = courts?.find((c: CourtDto) => c.id === selectedCourtId);

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-start justify-between flex-wrap gap-4">
        <div>
          <h2 className="text-lg font-medium">Agenda da Quadra</h2>
          <p className="text-xs text-muted-foreground">
            Clique num horário disponível para reservar ou numa reserva para cancelar
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="icon" onClick={() => setWeekOffset(w => w - 1)}>
            <ChevronLeft className="h-4 w-4" />
          </Button>
          <span className="text-sm font-medium min-w-40 text-center">
            {format(weekStart, "dd 'de' MMM", { locale: ptBR })}
            {' – '}
            {format(addDays(weekStart, 6), "dd 'de' MMM", { locale: ptBR })}
          </span>
          <Button variant="outline" size="icon" onClick={() => setWeekOffset(w => w + 1)}>
            <ChevronRight className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Court selector */}
      <div className="flex flex-col gap-1.5 max-w-xs">
        <Label>Quadra</Label>
        <select
          className="h-9 rounded-md border border-input bg-transparent px-3 text-sm"
          value={selectedCourtId}
          onChange={e => setSelectedCourtId(e.target.value)}
        >
          <option value="">Selecione uma quadra</option>
          {courts?.map((c: CourtDto) => (
            <option key={c.id} value={c.id}>{c.name}</option>
          ))}
        </select>
      </div>

      {!selectedCourtId ? (
        <p className="text-sm text-muted-foreground">Selecione uma quadra para ver a agenda.</p>
      ) : (
        <>
          {/* Grid */}
          <div className="overflow-x-auto rounded-xl border border-border">
            <table className="text-xs border-collapse w-full">
              <thead>
                <tr className="border-b border-border">
                  <th className="w-14 sticky left-0 bg-card z-10" />
                  {weekDays.map((day, i) => (
                    <th key={i} className="text-center font-medium py-2 px-1 min-w-[72px]">
                      <div className="capitalize">{format(day, 'EEE', { locale: ptBR })}</div>
                      <div className="text-muted-foreground font-normal">{format(day, 'dd/MM')}</div>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {HOURS.map(hour => (
                  <tr key={hour} className="border-b border-border/50 last:border-0">
                    <td className="text-right pr-3 text-muted-foreground py-1 w-14 sticky left-0 bg-card z-10">
                      {String(hour).padStart(2, '0')}:00
                    </td>
                    {weekDays.map((day, dayIdx) => {
                      const jsDay = day.getDay();
                      const inTemplate = isInTemplate(jsDay, hour);
                      const reservation = getReservation(day, hour);
                      const Icon = reservation ? CHANNEL_ICON[reservation.channel] : null;

                      const slotStart = new Date(day);
                      slotStart.setHours(hour, 0, 0, 0);
                      const isPast = slotStart < now;
                      // Slot is clickable if: has reservation (to cancel/view) OR is available and not past
                      const canClick = !!reservation || (inTemplate && !isPast);

                      return (
                        <td key={dayIdx} className="p-0.5 text-center">
                          <button
                            type="button"
                            disabled={!canClick}
                            onClick={() => canClick && setClickedCell({ date: day, hour, reservation })}
                            className={cn(
                              'w-full h-8 rounded text-[10px] font-medium transition-colors flex items-center justify-center gap-0.5',
                              // States without reservation (order matters for override)
                              !reservation && !inTemplate && 'bg-muted/30 cursor-not-allowed opacity-30',
                              !reservation && inTemplate && isPast && 'bg-muted/40 cursor-not-allowed opacity-50',
                              !reservation && inTemplate && !isPast && 'border border-border hover:bg-accent cursor-pointer',
                              // Reservation always shows clearly regardless of template/past
                              reservation && 'bg-primary text-primary-foreground hover:bg-primary/80',
                              reservation && !isPast && 'cursor-pointer',
                              reservation && isPast && 'cursor-default opacity-70',
                            )}
                          >
                            {reservation && Icon && (
                              <>
                                <Icon className="h-2.5 w-2.5 shrink-0" />
                                <span>{CHANNEL_LABEL[reservation.channel] ?? reservation.channel}</span>
                              </>
                            )}
                          </button>
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Legend */}
          <div className="flex items-center gap-5 text-xs text-muted-foreground">
            <span className="flex items-center gap-1.5">
              <span className="inline-block w-3 h-3 rounded-sm bg-primary" />
              Reservado
            </span>
            <span className="flex items-center gap-1.5">
              <span className="inline-block w-3 h-3 rounded-sm border border-border" />
              Disponível
            </span>
            <span className="flex items-center gap-1.5">
              <span className="inline-block w-3 h-3 rounded-sm bg-muted/30 opacity-50" />
              Fora do horário
            </span>
          </div>
        </>
      )}

      {/* Confirmation dialog */}
      <Dialog open={!!clickedCell} onOpenChange={open => !open && setClickedCell(null)}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>
              {clickedCell?.reservation ? 'Cancelar reserva' : 'Nova reserva manual'}
            </DialogTitle>
          </DialogHeader>
          {clickedCell && (
            <div className="flex flex-col gap-4 pt-1">
              <div className="rounded-lg bg-muted/50 p-4 flex flex-col gap-2 text-sm">
                <div className="flex items-center justify-between">
                  <span className="text-muted-foreground">Quadra</span>
                  <span className="font-medium">{selectedCourt?.name}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-muted-foreground">Data</span>
                  <span className="font-medium capitalize">
                    {format(clickedCell.date, "EEEE, dd 'de' MMM", { locale: ptBR })}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-muted-foreground">Horário</span>
                  <span className="font-medium">
                    {String(clickedCell.hour).padStart(2, '0')}:00 –{' '}
                    {String(clickedCell.hour + 1).padStart(2, '0')}:00
                  </span>
                </div>
                {clickedCell.reservation && (
                  <>
                    <div className="flex items-center justify-between">
                      <span className="text-muted-foreground">Canal</span>
                      <Badge variant="secondary">
                        {CHANNEL_LABEL[clickedCell.reservation.channel] ?? clickedCell.reservation.channel}
                      </Badge>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-muted-foreground">Jogador</span>
                      {clickedCell.reservation.playerUserId ? (
                        <div className="text-right">
                          <p className="font-medium text-sm">{playerProfile?.displayName ?? '...'}</p>
                          {(playerProfile?.phone ?? playerProfile?.email) && (
                            <p className="text-xs text-muted-foreground">{playerProfile?.phone ?? playerProfile?.email}</p>
                          )}
                        </div>
                      ) : (
                        <span className="text-sm">Dono do campo</span>
                      )}
                    </div>
                  </>
                )}
              </div>

              <div className="flex justify-end gap-2">
                <Button variant="outline" onClick={() => setClickedCell(null)}>
                  Voltar
                </Button>
                <Button
                  variant={clickedCell.reservation ? 'destructive' : 'default'}
                  onClick={handleConfirm}
                  disabled={isPending}
                >
                  {isPending
                    ? 'Aguarde...'
                    : clickedCell.reservation
                      ? 'Cancelar reserva'
                      : 'Confirmar reserva'}
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
