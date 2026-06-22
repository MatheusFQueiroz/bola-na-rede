'use client';
import Link from 'next/link';
import { Plus, MapPin, Building2, ChevronRight } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { useMyFields, type FieldDto } from '@/hooks/use-fields';

export default function FieldsPage() {
  const { data: fields, isLoading, error } = useMyFields();

  if (isLoading) {
    return (
      <div className="flex flex-col gap-6">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold tracking-tight">Meus Campos</h1>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {[1, 2, 3].map(i => (
            <div key={i} className="h-44 rounded-xl bg-muted animate-pulse" />
          ))}
        </div>
      </div>
    );
  }

  if (error) return <div className="text-destructive text-sm">Erro ao carregar campos.</div>;

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Meus Campos</h1>
          <p className="text-sm text-muted-foreground mt-0.5">
            {fields?.length
              ? `${fields.length} campo${fields.length !== 1 ? 's' : ''} cadastrado${fields.length !== 1 ? 's' : ''}`
              : 'Nenhum campo cadastrado ainda'}
          </p>
        </div>
        <Button nativeButton={false} render={<Link href="/fields/new" />}>
          <Plus className="h-4 w-4 mr-1.5" />
          Novo Campo
        </Button>
      </div>

      {(!fields || fields.length === 0) ? (
        <div className="text-center py-20 text-muted-foreground border-2 border-dashed rounded-xl">
          <Building2 className="h-12 w-12 mx-auto mb-4 opacity-20" />
          <p className="text-base font-medium">Nenhum campo cadastrado</p>
          <p className="text-sm mt-1 mb-4">Clique em &quot;Novo Campo&quot; para começar.</p>
          <Button nativeButton={false} render={<Link href="/fields/new" />} variant="outline" size="sm">
            <Plus className="h-4 w-4 mr-1.5" />
            Novo Campo
          </Button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {fields.map((field: FieldDto) => (
            <Link key={field.id} href={`/fields/${field.id}/courts`}>
              <div className="group flex flex-col rounded-xl bg-card ring-1 ring-foreground/10 hover:ring-primary hover:ring-2 transition-all cursor-pointer h-full overflow-hidden">
                {/* Colored accent strip */}
                <div className="h-1.5 bg-primary shrink-0" />
                <div className="p-4 flex flex-col gap-3 flex-1">
                  <div className="flex items-start justify-between gap-2">
                    <h2 className="font-semibold text-base leading-tight">{field.name}</h2>
                    <Badge
                      variant={field.isActive ? 'default' : 'secondary'}
                      className="shrink-0 text-[10px]"
                    >
                      {field.isActive ? 'Ativo' : 'Inativo'}
                    </Badge>
                  </div>
                  {field.description && (
                    <p className="text-sm text-muted-foreground line-clamp-2">{field.description}</p>
                  )}
                  <div className="mt-auto pt-2 border-t border-border/60 flex items-center justify-between">
                    <div className="flex flex-col gap-0.5">
                      <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                        <MapPin className="h-3 w-3 shrink-0" />
                        <span className="font-medium">{field.city}</span>
                      </div>
                      <p className="text-xs text-muted-foreground/70 pl-4.5 line-clamp-1">{field.address}</p>
                    </div>
                    <ChevronRight className="h-4 w-4 text-muted-foreground/40 group-hover:text-primary transition-colors shrink-0" />
                  </div>
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
