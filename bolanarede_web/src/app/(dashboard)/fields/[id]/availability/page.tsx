'use client';
import { use, useState } from 'react';
import { useCourts, type CourtDto } from '@/hooks/use-courts';
import { useSetAvailability } from '@/hooks/use-availability';
import { AvailabilityGrid } from '@/components/fields/availability-grid';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Label } from '@/components/ui/label';
import type { SlotData } from '@/hooks/use-availability';

export default function AvailabilityPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { data: courts, isLoading } = useCourts(id);
  const [selectedCourtId, setSelectedCourtId] = useState<string>('');
  const setAvailability = useSetAvailability(id);

  async function handleSave(slots: SlotData[]) {
    if (!selectedCourtId) return;
    await setAvailability.mutateAsync({ courtId: selectedCourtId, slots });
  }

  if (isLoading) {
    return <p className="text-muted-foreground text-sm">Carregando quadras...</p>;
  }

  return (
    <div className="flex flex-col gap-6">
      <h2 className="text-lg font-medium">Disponibilidade Semanal</h2>

      <div className="flex flex-col gap-1.5 max-w-xs">
        <Label>Selecionar Quadra</Label>
        <Select
          value={selectedCourtId}
          onValueChange={(value) => setSelectedCourtId(value as string)}
        >
          <SelectTrigger>
            <SelectValue placeholder="Escolha uma quadra" />
          </SelectTrigger>
          <SelectContent>
            {courts?.map((court: CourtDto) => (
              <SelectItem key={court.id} value={court.id}>
                {court.name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {selectedCourtId ? (
        <AvailabilityGrid
          onSave={handleSave}
          isSaving={setAvailability.isPending}
        />
      ) : (
        <p className="text-sm text-muted-foreground">
          Selecione uma quadra para definir a disponibilidade.
        </p>
      )}
    </div>
  );
}
