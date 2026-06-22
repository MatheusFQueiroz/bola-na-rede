'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import dynamic from 'next/dynamic';
import { Loader2, MapPin, Search } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { cn } from '@/lib/utils';

const MapPreview = dynamic(() => import('./map-preview'), {
  ssr: false,
  loading: () => <div className="h-40 w-full animate-pulse rounded-lg bg-muted" />,
});

export interface PickedLocation {
  address: string;
  city: string;
  lat: number;
  lng: number;
}

interface NominatimResult {
  place_id: number;
  display_name: string;
  lat: string;
  lon: string;
  address: {
    city?: string;
    town?: string;
    village?: string;
    municipality?: string;
    county?: string;
  };
}

interface Props {
  onPick: (loc: PickedLocation) => void;
  error?: string;
}

export function LocationPicker({ onPick, error }: Props) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<NominatimResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [picked, setPicked] = useState<PickedLocation | null>(null);
  const [open, setOpen] = useState(false);
  const onPickRef = useRef(onPick);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => { onPickRef.current = onPick; });

  const search = useCallback(async (q: string) => {
    if (q.length < 4) { setResults([]); setOpen(false); return; }
    setLoading(true);
    try {
      const url = new URL('https://nominatim.openstreetmap.org/search');
      url.searchParams.set('q', q);
      url.searchParams.set('format', 'json');
      url.searchParams.set('countrycodes', 'br');
      url.searchParams.set('addressdetails', '1');
      url.searchParams.set('limit', '5');
      const res = await fetch(url.toString(), {
        headers: { 'Accept-Language': 'pt-BR,pt;q=0.9' },
      });
      const data: NominatimResult[] = await res.json();
      setResults(data);
      setOpen(data.length > 0);
    } catch {
      setResults([]);
    } finally {
      setLoading(false);
    }
  }, []);

  function handleChange(value: string) {
    setQuery(value);
    setPicked(null);
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => void search(value), 350);
  }

  function handleSelect(result: NominatimResult) {
    const addr = result.address;
    const city = addr.city ?? addr.town ?? addr.village ?? addr.municipality ?? addr.county ?? '';
    const loc: PickedLocation = {
      address: result.display_name,
      city,
      lat: parseFloat(result.lat),
      lng: parseFloat(result.lon),
    };
    setQuery(result.display_name);
    setPicked(loc);
    setOpen(false);
    setResults([]);
    onPickRef.current(loc);
  }

  useEffect(() => {
    function onClickOutside(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener('mousedown', onClickOutside);
    return () => document.removeEventListener('mousedown', onClickOutside);
  }, []);


  return (
    <div className="flex flex-col gap-1.5">
      <Label>Localização *</Label>

      <div ref={containerRef} className="relative">
        <MapPin className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          value={query}
          onChange={e => handleChange(e.target.value)}
          placeholder="Ex: Rua das Flores, 123, Curitiba"
          className={cn('pl-9 pr-8', error && !picked && 'border-destructive')}
          autoComplete="off"
        />
        {loading ? (
          <Loader2 className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 animate-spin text-muted-foreground" />
        ) : (
          !picked && query.length >= 4 && (
            <Search className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          )
        )}

        {open && results.length > 0 && (
          <div className="absolute left-0 right-0 top-full z-50 mt-1 overflow-hidden rounded-lg border border-border bg-popover shadow-lg">
            {results.map(r => (
              <button
                key={r.place_id}
                type="button"
                onMouseDown={e => { e.preventDefault(); handleSelect(r); }}
                className="flex w-full items-start gap-2 px-3 py-2.5 text-left text-sm transition-colors hover:bg-accent hover:text-accent-foreground"
              >
                <MapPin className="mt-0.5 h-3.5 w-3.5 shrink-0 text-muted-foreground" />
                <span className="line-clamp-2">{r.display_name}</span>
              </button>
            ))}
            <div className="border-t border-border px-3 py-1.5 text-right text-[10px] text-muted-foreground">
              © OpenStreetMap contributors
            </div>
          </div>
        )}
      </div>

      {error && !picked && <p className="text-xs text-destructive">{error}</p>}

      {picked && (
        <div className="flex items-center gap-2 text-xs text-muted-foreground">
          <span className="truncate font-medium text-foreground">{picked.city}</span>
          <span>·</span>
          <span className="shrink-0 font-mono">
            {picked.lat.toFixed(5)}, {picked.lng.toFixed(5)}
          </span>
        </div>
      )}

      {picked && (
        <div className="overflow-hidden rounded-lg border border-border">
          <MapPreview lat={picked.lat} lng={picked.lng} />
        </div>
      )}
    </div>
  );
}
