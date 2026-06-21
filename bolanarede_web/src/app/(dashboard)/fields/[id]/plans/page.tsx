'use client';
import { use, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { useCourts, type CourtDto } from '@/hooks/use-courts';
import { usePlans, useCreatePlan, useReleaseSlot, type PlanDto } from '@/hooks/use-plans';
import { toast } from 'sonner';

const DAY_NAMES = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];

const schema = z.object({
  courtId: z.string().min(1, 'Quadra obrigatória'),
  dayOfWeek: z.number({ error: 'Dia obrigatório' }),
  startTime: z.string().regex(/^\d{2}:\d{2}$/, 'Formato HH:mm'),
  endTime: z.string().regex(/^\d{2}:\d{2}$/, 'Formato HH:mm'),
  playerUserId: z.string().optional(),
});
type FormData = z.infer<typeof schema>;

export default function PlansPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { data: plans, isLoading } = usePlans(id);
  const { data: courts } = useCourts(id);
  const createPlan = useCreatePlan(id);
  const releaseSlot = useReleaseSlot(id);
  const [open, setOpen] = useState(false);

  const { register, handleSubmit, reset, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { dayOfWeek: 1 },
  });

  const onSubmit = async (data: FormData) => {
    try {
      await createPlan.mutateAsync(data);
      toast.success('Plano criado com sucesso!');
      reset();
      setOpen(false);
    } catch {
      toast.error('Erro ao criar plano.');
    }
  };

  async function handleRelease(slotId: string) {
    try {
      await releaseSlot.mutateAsync(slotId);
      toast.success('Slot liberado com sucesso!');
    } catch {
      toast.error('Erro ao liberar slot.');
    }
  }

  function courtName(courtId: string) {
    return courts?.find((c: CourtDto) => c.id === courtId)?.name ?? courtId.slice(0, 8) + '...';
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex justify-between items-center">
        <h2 className="text-lg font-medium">Planos Recorrentes</h2>
        <Button size="sm" onClick={() => setOpen(true)}>
          <Plus className="h-4 w-4 mr-1" />
          Novo Plano
        </Button>
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Novo Plano Recorrente</DialogTitle>
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
              <Label>Dia da Semana</Label>
              <select
                className="h-9 rounded-md border border-input bg-transparent px-3 text-sm"
                {...register('dayOfWeek', { valueAsNumber: true })}
              >
                {DAY_NAMES.map((name, i) => <option key={i} value={i}>{name}</option>)}
              </select>
              {errors.dayOfWeek && <p className="text-xs text-destructive">{errors.dayOfWeek.message}</p>}
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="flex flex-col gap-1.5">
                <Label>Início</Label>
                <Input type="time" {...register('startTime')} />
                {errors.startTime && <p className="text-xs text-destructive">{errors.startTime.message}</p>}
              </div>
              <div className="flex flex-col gap-1.5">
                <Label>Fim</Label>
                <Input type="time" {...register('endTime')} />
                {errors.endTime && <p className="text-xs text-destructive">{errors.endTime.message}</p>}
              </div>
            </div>
            <div className="flex flex-col gap-1.5">
              <Label>UUID do Jogador (opcional)</Label>
              <Input placeholder="Opcional" {...register('playerUserId')} />
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="outline" onClick={() => setOpen(false)}>Cancelar</Button>
              <Button type="submit" disabled={createPlan.isPending}>
                {createPlan.isPending ? 'Criando...' : 'Criar'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {isLoading ? (
        <p className="text-sm text-muted-foreground">Carregando...</p>
      ) : !plans || plans.length === 0 ? (
        <p className="text-sm text-muted-foreground py-8 text-center">Nenhum plano recorrente.</p>
      ) : (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Quadra</TableHead>
              <TableHead>Dia</TableHead>
              <TableHead>Horário</TableHead>
              <TableHead>Status</TableHead>
              <TableHead />
            </TableRow>
          </TableHeader>
          <TableBody>
            {plans.map((plan: PlanDto) => (
              <TableRow key={plan.id}>
                <TableCell>{plan.courtName ?? courtName(plan.courtId)}</TableCell>
                <TableCell>{DAY_NAMES[plan.dayOfWeek]}</TableCell>
                <TableCell>{plan.startTime} – {plan.endTime}</TableCell>
                <TableCell>
                  <Badge variant={plan.isActive ? 'default' : 'secondary'}>
                    {plan.isActive ? 'Ativo' : 'Liberado'}
                  </Badge>
                </TableCell>
                <TableCell>
                  {plan.isActive && (
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => handleRelease(plan.id)}
                      disabled={releaseSlot.isPending}
                    >
                      Liberar
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
