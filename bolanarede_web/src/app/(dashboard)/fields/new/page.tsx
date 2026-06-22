'use client';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { ArrowLeft } from 'lucide-react';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useCreateField } from '@/hooks/use-fields';
import { LocationPicker } from '@/components/fields/location-picker';
import { toast } from 'sonner';

const schema = z.object({
  name: z.string().min(1, 'Nome obrigatório'),
  description: z.string().optional(),
  city: z.string().min(1, 'Selecione um endereço no mapa'),
  address: z.string().min(1, 'Selecione um endereço no mapa'),
  lat: z.number({ error: 'Selecione um endereço no mapa' }),
  lng: z.number({ error: 'Selecione um endereço no mapa' }),
});

type FormData = z.infer<typeof schema>;

export default function NewFieldPage() {
  const router = useRouter();
  const createField = useCreateField();

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({ resolver: zodResolver(schema) });

  const onSubmit = async (data: FormData) => {
    try {
      await createField.mutateAsync({
        name: data.name,
        description: data.description || undefined,
        city: data.city,
        address: data.address,
        lat: data.lat,
        lng: data.lng,
      });
      toast.success('Campo criado com sucesso!');
      router.push('/fields');
    } catch {
      toast.error('Erro ao criar campo.');
    }
  };

  const locationError =
    errors.city?.message ??
    errors.address?.message ??
    errors.lat?.message ??
    errors.lng?.message;

  return (
    <div className="flex flex-col gap-6 max-w-lg">
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="sm" nativeButton={false} render={<Link href="/fields" />}>
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <h1 className="text-2xl font-bold tracking-tight">Novo Campo</h1>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Informações do Campo</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4">
            <div className="flex flex-col gap-1.5">
              <Label htmlFor="name">Nome *</Label>
              <Input id="name" placeholder="Ex: Arena Central" {...register('name')} />
              {errors.name && <p className="text-xs text-destructive">{errors.name.message}</p>}
            </div>

            <div className="flex flex-col gap-1.5">
              <Label htmlFor="description">Descrição</Label>
              <Input id="description" placeholder="Opcional" {...register('description')} />
            </div>

            <LocationPicker
              error={locationError}
              onPick={loc => {
                setValue('address', loc.address, { shouldValidate: true });
                setValue('city', loc.city, { shouldValidate: true });
                setValue('lat', loc.lat, { shouldValidate: true });
                setValue('lng', loc.lng, { shouldValidate: true });
              }}
            />

            {createField.error && (
              <p className="text-sm text-destructive">Erro ao criar campo. Tente novamente.</p>
            )}

            <div className="flex gap-3 pt-2">
              <Button type="submit" disabled={isSubmitting || createField.isPending}>
                {createField.isPending ? 'Criando...' : 'Criar Campo'}
              </Button>
              <Button variant="outline" type="button" onClick={() => router.push('/fields')}>
                Cancelar
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
