import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';

export interface ReservationDto {
  id: string;
  fieldId: string;
  courtId: string;
  courtName?: string;
  startsAt: string;
  endsAt: string;
  channel: string;
  playerUserId?: string;
  status: string;
  notes?: string;
}

async function fetchReservations(fieldId: string): Promise<ReservationDto[]> {
  const res = await api.get(`/v1/fields/${fieldId}/reservations`);
  return Array.isArray(res.data) ? res.data : (res.data.data ?? []);
}

export function useReservations(fieldId: string) {
  return useQuery({
    queryKey: ['reservations', fieldId],
    queryFn: () => fetchReservations(fieldId),
    enabled: !!fieldId,
  });
}

export interface CreateReservationData {
  courtId: string;
  startsAt: string;
  endsAt: string;
  notes?: string;
}

async function createReservation(fieldId: string, data: CreateReservationData): Promise<ReservationDto> {
  const res = await api.post(`/v1/fields/${fieldId}/reservations`, { ...data, channel: 'manual' });
  return res.data.data ?? res.data;
}

export function useCreateReservation(fieldId: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateReservationData) => createReservation(fieldId, data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['reservations', fieldId] }),
  });
}

async function cancelReservation(fieldId: string, reservationId: string): Promise<void> {
  await api.delete(`/v1/fields/${fieldId}/reservations/${reservationId}`);
}

export function useCancelReservation(fieldId: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (reservationId: string) => cancelReservation(fieldId, reservationId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['reservations', fieldId] }),
  });
}
