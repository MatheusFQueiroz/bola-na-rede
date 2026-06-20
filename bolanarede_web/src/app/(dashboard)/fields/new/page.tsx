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

const schema = z.object({
  name: z.string().min(1, 'Nome obrigatório'),
  description: z.string().optional(),
  city: z.string().min(1, 'Cidade obrigatória'),
  address: z.string().min(1, 'Endereço obrigatório'),
  lat: z.number({ error: 'Latitude inválida' }),
  lng: z.number({ error: 'Longitude inválida' }),
});

type FormData = z.infer<typeof schema>;

export default function NewFieldPage() {
  const router = useRouter();
  const createField = useCreateField();

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { lat: -23.5505, lng: -46.6333 }, // São Paulo defaults
  });

  const onSubmit = async (data: FormData) => {
    await createField.mutateAsync({
      name: data.name,
      description: data.description || undefined,
      city: data.city,
      address: data.address,
      lat: data.lat,
      lng: data.lng,
    });
    router.push('/fields');
  };

  return (
    <div className="flex flex-col gap-6 max-w-lg">
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="sm" render={<Link href="/fields" />}>
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <h1 className="text-2xl font-semibold">Novo Campo</h1>
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

            <div className="flex flex-col gap-1.5">
              <Label htmlFor="city">Cidade *</Label>
              <Input id="city" placeholder="Ex: São Paulo" {...register('city')} />
              {errors.city && <p className="text-xs text-destructive">{errors.city.message}</p>}
            </div>

            <div className="flex flex-col gap-1.5">
              <Label htmlFor="address">Endereço *</Label>
              <Input id="address" placeholder="Rua, número, bairro" {...register('address')} />
              {errors.address && <p className="text-xs text-destructive">{errors.address.message}</p>}
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="flex flex-col gap-1.5">
                <Label htmlFor="lat">Latitude *</Label>
                <Input id="lat" type="number" step="any" {...register('lat', { valueAsNumber: true })} />
                {errors.lat && <p className="text-xs text-destructive">{errors.lat.message}</p>}
              </div>
              <div className="flex flex-col gap-1.5">
                <Label htmlFor="lng">Longitude *</Label>
                <Input id="lng" type="number" step="any" {...register('lng', { valueAsNumber: true })} />
                {errors.lng && <p className="text-xs text-destructive">{errors.lng.message}</p>}
              </div>
            </div>

            {createField.error && (
              <p className="text-sm text-destructive">
                Erro ao criar campo. Tente novamente.
              </p>
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
