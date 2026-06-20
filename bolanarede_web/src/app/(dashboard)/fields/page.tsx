'use client';
import Link from 'next/link';
import { Plus, MapPin, Building2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useMyFields, type FieldDto } from '@/hooks/use-fields';

export default function FieldsPage() {
  const { data: fields, isLoading, error } = useMyFields();

  if (isLoading) return <div className="text-muted-foreground">Carregando...</div>;
  if (error) return <div className="text-destructive">Erro ao carregar campos.</div>;

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Meus Campos</h1>
        <Button render={<Link href="/fields/new" />}>
          <Plus className="h-4 w-4 mr-2" />
          Novo Campo
        </Button>
      </div>

      {(!fields || fields.length === 0) ? (
        <div className="text-center py-16 text-muted-foreground">
          <Building2 className="h-12 w-12 mx-auto mb-4 opacity-30" />
          <p className="text-lg font-medium">Nenhum campo cadastrado</p>
          <p className="text-sm mt-1">Clique em "Novo Campo" para começar.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {fields.map((field: FieldDto) => (
            <Link key={field.id} href={`/fields/${field.id}/courts`}>
              <Card className="hover:ring-2 hover:ring-primary transition-all cursor-pointer h-full">
                <CardHeader>
                  <div className="flex items-start justify-between gap-2">
                    <CardTitle className="text-base">{field.name}</CardTitle>
                    <Badge variant={field.isActive ? 'default' : 'secondary'}>
                      {field.isActive ? 'Ativo' : 'Inativo'}
                    </Badge>
                  </div>
                  {field.description && (
                    <CardDescription>{field.description}</CardDescription>
                  )}
                </CardHeader>
                <CardContent>
                  <div className="flex items-center gap-1.5 text-sm text-muted-foreground">
                    <MapPin className="h-3.5 w-3.5" />
                    <span>{field.city}</span>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">{field.address}</p>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
