'use client';
import { use, useState } from 'react';
import { useCourts, type CourtDto } from '@/hooks/use-courts';
import { useSetAvailability, useCourtWeeklySlots } from '@/hooks/use-availability';
import { AvailabilityGrid } from '@/components/fields/availability-grid';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Label } from '@/components/ui/label';
import { toast } from 'sonner';
import type { SlotData } from '@/hooks/use-availability';

export default function AvailabilityPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { data: courts, isLoading } = useCourts(id);
  const [selectedCourtId, setSelectedCourtId] = useState<string>('');
  const setAvailability = useSetAvailability(id);
  const { data: initialSlots = [], isLoading: slotsLoading } = useCourtWeeklySlots(id, selectedCourtId);

  async function handleSave(slots: SlotData[]) {
    if (!selectedCourtId) return;
    try {
      await setAvailability.mutateAsync({ courtId: selectedCourtId, slots });
      toast.success('Disponibilidade salva com sucesso!');
    } catch {
      toast.error('Erro ao salvar disponibilidade.');
    }
  }

  if (isLoading) {
    return <p className="text-muted-foreground text-sm">Carregando quadras...</p>;
  }

  return (
    <div className="flex flex-col gap-6">
      <h2 className="text-lg font-medium">Disponibilidade Semanal</h2>

      <div className="flex flex-col gap-1.5 max-w-xs">
        <Label>Selecionar Quadra</Label>
        <Select value={selectedCourtId} onValueChange={(v) => setSelectedCourtId(v as string)}>
          <SelectTrigger>
            <SelectValue placeholder="Escolha uma quadra" />
          </SelectTrigger>
          <SelectContent>
            {courts?.map((court: CourtDto) => (
              <SelectItem key={court.id} value={court.id}>{court.name}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {selectedCourtId ? (
        slotsLoading ? (
          <p className="text-sm text-muted-foreground">Carregando disponibilidade...</p>
        ) : (
          <AvailabilityGrid
            key={selectedCourtId}
            onSave={handleSave}
            isSaving={setAvailability.isPending}
            initialSlots={initialSlots}
          />
        )
      ) : (
        <p className="text-sm text-muted-foreground">
          Selecione uma quadra para definir a disponibilidade.
        </p>
      )}
    </div>
  );
}
