import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';

export interface PlanDto {
  id: string;
  fieldId: string;
  courtId: string;
  courtName?: string;
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  playerUserId?: string;
  isActive: boolean;
}

async function fetchPlans(fieldId: string): Promise<PlanDto[]> {
  const res = await api.get(`/v1/fields/${fieldId}/plans`);
  return Array.isArray(res.data) ? res.data : (res.data.data ?? []);
}

export function usePlans(fieldId: string) {
  return useQuery({
    queryKey: ['plans', fieldId],
    queryFn: () => fetchPlans(fieldId),
    enabled: !!fieldId,
  });
}

export interface CreatePlanData {
  courtId: string;
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  playerUserId?: string;
}

async function createPlan(fieldId: string, data: CreatePlanData): Promise<PlanDto> {
  const res = await api.post(`/v1/fields/${fieldId}/plans`, data);
  return res.data.data ?? res.data;
}

export function useCreatePlan(fieldId: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreatePlanData) => createPlan(fieldId, data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['plans', fieldId] }),
  });
}

async function releaseSlot(fieldId: string, slotId: string): Promise<void> {
  await api.delete(`/v1/fields/${fieldId}/plans/slots/${slotId}/release`);
}

export function useReleaseSlot(fieldId: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (slotId: string) => releaseSlot(fieldId, slotId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['plans', fieldId] }),
  });
}
