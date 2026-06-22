'use client';
import { use, useState } from 'react';
import { Plus } from 'lucide-react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { useCourts, useAddCourt, type CourtDto } from '@/hooks/use-courts';
import { toast } from 'sonner';

const COURT_TYPES = ['futsal', 'society', 'campo', 'beach_tennis', 'padel'];

const schema = z.object({
  name: z.string().min(1, 'Nome obrigatório'),
  type: z.string().min(1, 'Tipo obrigatório'),
  maxPlayers: z.number({ error: 'Número inválido' }).int().min(2).max(50),
  pricePerHour: z.number({ error: 'Valor inválido' }).min(0).optional().nullable(),
});
type FormData = z.infer<typeof schema>;

export default function CourtsPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { data: courts, isLoading } = useCourts(id);
  const addCourt = useAddCourt(id);
  const [open, setOpen] = useState(false);

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { maxPlayers: 10 },
  });

  const onSubmit = async (data: FormData) => {
    try {
      await addCourt.mutateAsync(data);
      toast.success('Quadra adicionada com sucesso!');
      reset();
      setOpen(false);
    } catch {
      toast.error('Erro ao adicionar quadra.');
    }
  };

  return (
    <div className="flex flex-col gap-4">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold">Quadras</h2>
          <p className="text-xs text-muted-foreground">Gerencie as quadras deste campo</p>
        </div>
        <Button size="sm" onClick={() => setOpen(true)}>
          <Plus className="h-4 w-4 mr-1" />
          Adicionar Quadra
        </Button>
      </div>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Nova Quadra</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4 pt-2">
            <div className="flex flex-col gap-1.5">
              <Label>Nome</Label>
              <Input placeholder="Ex: Quadra 1" {...register('name')} />
              {errors.name && (
                <p className="text-xs text-destructive">{errors.name.message}</p>
              )}
            </div>
            <div className="flex flex-col gap-1.5">
              <Label>Tipo</Label>
              <Input
                placeholder="futsal / society / campo"
                list="court-types"
                {...register('type')}
              />
              <datalist id="court-types">
                {COURT_TYPES.map(t => (
                  <option key={t} value={t} />
                ))}
              </datalist>
              {errors.type && (
                <p className="text-xs text-destructive">{errors.type.message}</p>
              )}
            </div>
            <div className="flex flex-col gap-1.5">
              <Label>Máx. Jogadores</Label>
              <Input
                type="number"
                {...register('maxPlayers', { valueAsNumber: true })}
              />
              {errors.maxPlayers && (
                <p className="text-xs text-destructive">{errors.maxPlayers.message}</p>
              )}
            </div>
            <div className="flex flex-col gap-1.5">
              <Label>Preço/hora (R$) — opcional</Label>
              <Input
                type="number"
                step="0.01"
                placeholder="Ex: 90"
                {...register('pricePerHour', { valueAsNumber: true, setValueAs: v => (isNaN(v) ? null : v) })}
              />
              {errors.pricePerHour && (
                <p className="text-xs text-destructive">{errors.pricePerHour.message}</p>
              )}
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <Button
                type="button"
                variant="outline"
                onClick={() => setOpen(false)}
              >
                Cancelar
              </Button>
              <Button type="submit" disabled={addCourt.isPending}>
                {addCourt.isPending ? 'Criando...' : 'Criar'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {isLoading ? (
        <div className="space-y-2">
          {[1, 2, 3].map(i => <div key={i} className="h-12 rounded-lg bg-muted animate-pulse" />)}
        </div>
      ) : !courts || courts.length === 0 ? (
        <div className="py-12 text-center border-2 border-dashed rounded-xl text-muted-foreground">
          <p className="font-medium">Nenhuma quadra cadastrada.</p>
          <p className="text-sm mt-1">Clique em &quot;Adicionar Quadra&quot; para começar.</p>
        </div>
      ) : (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Nome</TableHead>
              <TableHead>Tipo</TableHead>
              <TableHead>Máx. Jogadores</TableHead>
              <TableHead>Preço/h</TableHead>
              <TableHead>Status</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {courts.map((court: CourtDto) => (
              <TableRow key={court.id}>
                <TableCell className="font-medium">{court.name}</TableCell>
                <TableCell className="capitalize">{court.type}</TableCell>
                <TableCell>{court.maxPlayers}</TableCell>
                <TableCell>
                  {court.pricePerHour != null
                    ? `R$ ${court.pricePerHour.toFixed(2).replace('.', ',')}`
                    : <span className="text-muted-foreground text-xs">—</span>}
                </TableCell>
                <TableCell>
                  <Badge variant={court.isActive ? 'default' : 'secondary'}>
                    {court.isActive ? 'Ativa' : 'Inativa'}
                  </Badge>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}
    </div>
  );
}
