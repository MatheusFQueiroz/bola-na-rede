import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';

export interface CourtDto {
  id: string;
  fieldId: string;
  name: string;
  type: string;
  maxPlayers: number;
  isActive: boolean;
}

async function fetchCourts(fieldId: string): Promise<CourtDto[]> {
  const res = await api.get(`/v1/fields/${fieldId}/courts`);
  return Array.isArray(res.data) ? res.data : (res.data.data ?? []);
}

export function useCourts(fieldId: string) {
  return useQuery({
    queryKey: ['courts', fieldId],
    queryFn: () => fetchCourts(fieldId),
    enabled: !!fieldId,
  });
}

export interface CreateCourtData {
  name: string;
  type: string;
  maxPlayers: number;
}

async function createCourt(fieldId: string, data: CreateCourtData): Promise<CourtDto> {
  const res = await api.post(`/v1/fields/${fieldId}/courts`, data);
  return res.data.data ?? res.data;
}

export function useAddCourt(fieldId: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateCourtData) => createCourt(fieldId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['courts', fieldId] });
    },
  });
}
