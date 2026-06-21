import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';

export interface FieldDto {
  id: string;
  name: string;
  description: string | null;
  city: string;
  address: string;
  lat: number;
  lng: number;
  ownerUserId: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

async function fetchMyFields(): Promise<FieldDto[]> {
  const res = await api.get('/v1/fields/mine');
  // Handle HATEOAS wrapper: { data: [...] } or raw array
  return Array.isArray(res.data) ? res.data : (res.data.data ?? []);
}

export function useMyFields() {
  return useQuery({
    queryKey: ['fields', 'mine'],
    queryFn: fetchMyFields,
  });
}

export function useField(id: string) {
  return useQuery({
    queryKey: ['fields', id],
    queryFn: async () => {
      const res = await api.get(`/v1/fields/${id}`);
      return (res.data.data ?? res.data) as FieldDto;
    },
    enabled: !!id,
  });
}

export interface CreateFieldData {
  name: string;
  description?: string;
  city: string;
  address: string;
  lat: number;
  lng: number;
}

async function createField(data: CreateFieldData): Promise<FieldDto> {
  const res = await api.post('/v1/fields', data);
  return res.data.data ?? res.data;
}

export function useCreateField() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: createField,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['fields', 'mine'] });
    },
  });
}
