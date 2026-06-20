import { useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';

export interface SlotData {
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  isAvailable: boolean;
}

async function setAvailability(fieldId: string, courtId: string, slots: SlotData[]): Promise<void> {
  await api.put(`/v1/fields/${fieldId}/courts/${courtId}/availability`, { slots });
}

export function useSetAvailability(fieldId: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ courtId, slots }: { courtId: string; slots: SlotData[] }) =>
      setAvailability(fieldId, courtId, slots),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['courts', fieldId] });
    },
  });
}
