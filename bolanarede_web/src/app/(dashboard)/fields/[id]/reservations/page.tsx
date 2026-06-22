'use client';
import { use, useState } from 'react';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Plus } from 'lucide-react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useQuery } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { useCourts, type CourtDto } from '@/hooks/use-courts';
import { useReservations, useCreateReservation, useCancelReservation, type ReservationDto } from '@/hooks/use-reservations';
import { api } from '@/lib/api';
import { toast } from 'sonner';

const CHANNEL_LABEL: Record<string, string> = {
  app: 'App',
  manual: 'Manual',
  phone: 'Telefone',
};

interface PlayerProfile { displayName?: string; phone?: string | null; email?: string | null; }

function PlayerCell({ playerUserId }: { playerUserId: string }) {
  const { data, isLoading } = useQuery<PlayerProfile>({
    queryKey: ['user-profile', playerUserId],
    queryFn: async () => {
      const res = await api.get(`/v1/users/${playerUserId}/profile`);
      return res.data.data ?? res.data;
    },
    staleTime: 5 * 60 * 1000,
  });
  if (isLoading) return <span className="text-xs text-muted-foreground">Carregando…</span>;
  const contact = data?.phone ?? data?.email;
  return (
    <div className="flex flex-col leading-tight">
      <span className="text-sm font-medium">{data?.displayName ?? '—'}</span>
      {contact && <span className="text-xs text-muted-foreground">{contact}</span>}
    </div>
  );
}

const CHANNEL_OPTIONS = [
  { value: 'manual', label: 'Manual' },
  { value: 'phone', label: 'Telefone' },
];

const schema = z.object({
  courtId: z.string().min(1, 'Quadra obrigatória'),
  startsAt: z.string().min(1, 'Data/hora de início obrigatória'),
  endsAt: z.string().min(1, 'Data/hora de fim obrigatória'),
  channel: z.string().default('manual'),
  notes: z.string().optional(),
});
type FormData = z.infer<typeof schema>;

function statusBadge(status: string) {
  const map: Record<string, 'default' | 'secondary' | 'destructive'> = {
    confirmed: 'default',
    pending: 'secondary',
    cancelled: 'destructive',
  };
  const labels: Record<string, string> = {
    confirmed: 'Confirmada',
    pending: 'Pendente',
    cancelled: 'Cancelada',
  };
  return <Badge variant={map[status] ?? 'secondary'}>{labels[status] ?? status}</Badge>;
}

export default function ReservationsPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { data: reservations, isLoading } = useReservations(id);
  const { data: courts } = useCourts(id);
  const createReservation = useCreateReservation(id);
  const cancelReservation = useCancelReservation(id);
  const [open, setOpen] = useState(false);

  const { register, handleSubmit, reset, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const onSubmit = async (data: FormData) => {
    try {
      await createReservation.mutateAsync({
        ...data,
        startsAt: new Date(data.startsAt).toISOString(),
        endsAt: new Date(data.endsAt).toISOString(),
      });
      toast.success('Reserva criada com sucesso!');
      reset();
      setOpen(false);
    } catch {
      toast.error('Erro ao criar reserva.');
    }
  };

  async function handleCancel(reservationId: string) {
    try {
      await cancelReservation.mutateAsync(reservationId);
      toast.success('Reserva cancelada.');
    } catch {
      toast.error('Erro ao cancelar reserva.');
    }
  }

  function courtName(courtId: string) {
    return courts?.find((c: CourtDto) => c.id === courtId)?.name ?? courtId.slice(0, 8) + '...';
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold">Reservas</h2>
          <p className="text-xs text-muted-foreground">Reservas manuais e pelo app</p>
        </div>
        <Button size="sm" onClick={() => setOpen(true)}>
          <Plus className="h-4 w-4 mr-1" />
          Nova Reserva
        </Button>
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Nova Reserva Manual</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4 pt-2">
            <div className="flex flex-col gap-1.5">
              <Label>Quadra</Label>
              <select
                className="h-9 rounded-md border border-input bg-transparent px-3 text-sm"
                {...register('courtId')}
              >
                <option value="">Selecione...</option>
                {courts?.map((c: CourtDto) => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
              {errors.courtId && <p className="text-xs text-destructive">{errors.courtId.message}</p>}
            </div>
            <div className="flex flex-col gap-1.5">
              <Label>Início</Label>
              <Input type="datetime-local" {...register('startsAt')} />
              {errors.startsAt && <p className="text-xs text-destructive">{errors.startsAt.message}</p>}
            </div>
            <div className="flex flex-col gap-1.5">
              <Label>Fim</Label>
              <Input type="datetime-local" {...register('endsAt')} />
              {errors.endsAt && <p className="text-xs text-destructive">{errors.endsAt.message}</p>}
            </div>
            <div className="flex flex-col gap-1.5">
              <Label>Canal</Label>
              <select
                className="h-9 rounded-md border border-input bg-transparent px-3 text-sm"
                {...register('channel')}
              >
                {CHANNEL_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </div>
            <div className="flex flex-col gap-1.5">
              <Label>Observações</Label>
              <Input placeholder="Opcional" {...register('notes')} />
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="outline" onClick={() => setOpen(false)}>Cancelar</Button>
              <Button type="submit" disabled={createReservation.isPending}>
                {createReservation.isPending ? 'Criando...' : 'Criar'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {isLoading ? (
        <div className="space-y-2">
          {[1, 2, 3].map(i => <div key={i} className="h-12 rounded-lg bg-muted animate-pulse" />)}
        </div>
      ) : !reservations || reservations.length === 0 ? (
        <div className="py-12 text-center border-2 border-dashed rounded-xl text-muted-foreground">
          <p className="font-medium">Nenhuma reserva encontrada.</p>
          <p className="text-sm mt-1">Crie uma reserva manual ou aguarde reservas pelo app.</p>
        </div>
      ) : (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Data/Hora</TableHead>
              <TableHead>Quadra</TableHead>
              <TableHead>Canal</TableHead>
              <TableHead>Jogador</TableHead>
              <TableHead>Status</TableHead>
              <TableHead />
            </TableRow>
          </TableHeader>
          <TableBody>
            {reservations.map((r: ReservationDto) => (
              <TableRow key={r.id}>
                <TableCell>
                  {format(new Date(r.startsAt), 'dd/MM HH:mm', { locale: ptBR })}
                </TableCell>
                <TableCell>{r.courtName ?? courtName(r.courtId)}</TableCell>
                <TableCell>{CHANNEL_LABEL[r.channel] ?? r.channel}</TableCell>
                <TableCell>
                  {r.playerUserId
                    ? <PlayerCell playerUserId={r.playerUserId} />
                    : <span className="text-xs text-muted-foreground">Dono do campo</span>}
                </TableCell>
                <TableCell>{statusBadge(r.status)}</TableCell>
                <TableCell>
                  {r.status !== 'cancelled' && (
                    <Button
                      size="sm"
                      variant="destructive"
                      onClick={() => handleCancel(r.id)}
                      disabled={cancelReservation.isPending}
                    >
                      Cancelar
                    </Button>
                  )}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}
    </div>
  );
}
