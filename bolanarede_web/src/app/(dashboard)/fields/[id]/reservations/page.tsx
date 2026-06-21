'use client';
import { use, useState } from 'react';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Plus } from 'lucide-react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { useCourts, type CourtDto } from '@/hooks/use-courts';
import { useReservations, useCreateReservation, useCancelReservation, type ReservationDto } from '@/hooks/use-reservations';
import { toast } from 'sonner';

const schema = z.object({
  courtId: z.string().min(1, 'Quadra obrigatória'),
  startsAt: z.string().min(1, 'Data/hora de início obrigatória'),
  endsAt: z.string().min(1, 'Data/hora de fim obrigatória'),
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
      await createReservation.mutateAsync(data);
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
        <h2 className="text-lg font-medium">Reservas</h2>
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
        <p className="text-sm text-muted-foreground">Carregando...</p>
      ) : !reservations || reservations.length === 0 ? (
        <p className="text-sm text-muted-foreground py-8 text-center">Nenhuma reserva encontrada.</p>
      ) : (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Data/Hora</TableHead>
              <TableHead>Quadra</TableHead>
              <TableHead>Canal</TableHead>
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
                <TableCell className="capitalize">{r.channel}</TableCell>
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
