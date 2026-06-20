'use client';
import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import type { SlotData } from '@/hooks/use-availability';

const DAYS = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
const HOURS = Array.from({ length: 17 }, (_, i) => i + 6); // 06–22

function toSlots(grid: boolean[][]): SlotData[] {
  const slots: SlotData[] = [];
  for (let day = 0; day < 7; day++) {
    for (let h = 0; h < HOURS.length; h++) {
      if (grid[day][h]) {
        const hour = HOURS[h];
        slots.push({
          dayOfWeek: day,
          startTime: `${String(hour).padStart(2, '0')}:00`,
          endTime: `${String(hour + 1).padStart(2, '0')}:00`,
          isAvailable: true,
        });
      }
    }
  }
  return slots;
}

interface AvailabilityGridProps {
  onSave: (slots: SlotData[]) => Promise<void>;
  isSaving: boolean;
}

export function AvailabilityGrid({ onSave, isSaving }: AvailabilityGridProps) {
  // grid[day][hourIndex] = isAvailable
  const [grid, setGrid] = useState<boolean[][]>(
    Array.from({ length: 7 }, () =>
      Array.from({ length: HOURS.length }, () => false)
    )
  );

  function toggle(day: number, hourIdx: number) {
    setGrid(prev => {
      const next = prev.map(row => [...row]);
      next[day][hourIdx] = !next[day][hourIdx];
      return next;
    });
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="overflow-x-auto">
        <table className="text-xs border-collapse">
          <thead>
            <tr>
              <th className="w-14 text-right pr-2 font-normal text-muted-foreground" />
              {DAYS.map(d => (
                <th key={d} className="w-12 text-center font-medium pb-2">
                  {d}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {HOURS.map((hour, hIdx) => (
              <tr key={hour}>
                <td className="text-right pr-2 text-muted-foreground py-0.5">
                  {String(hour).padStart(2, '0')}:00
                </td>
                {DAYS.map((_, day) => (
                  <td key={day} className="p-0.5">
                    <button
                      type="button"
                      onClick={() => toggle(day, hIdx)}
                      className={cn(
                        'w-10 h-7 rounded transition-colors border',
                        grid[day][hIdx]
                          ? 'bg-primary border-primary'
                          : 'bg-muted border-transparent hover:bg-accent'
                      )}
                    />
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="flex items-center gap-3">
        <Button onClick={() => onSave(toSlots(grid))} disabled={isSaving}>
          {isSaving ? 'Salvando...' : 'Salvar Disponibilidade'}
        </Button>
        <p className="text-xs text-muted-foreground">Verde = disponível</p>
      </div>
    </div>
  );
}
