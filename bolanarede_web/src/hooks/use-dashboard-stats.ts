import { useQueries } from '@tanstack/react-query';
import { api } from '@/lib/api';
import { useMyFields, type FieldDto } from './use-fields';
import type { ReservationDto } from './use-reservations';
import type { CourtDto } from './use-courts';
import {
  startOfMonth,
  endOfMonth,
  isWithinInterval,
  addDays,
  format,
  eachDayOfInterval,
} from 'date-fns';

export interface DayBucket {
  label: string;
  date: Date;
  count: number;
}

export interface DashboardStats {
  isLoading: boolean;
  totalFields: number;
  totalCourts: number;
  thisMonthTotal: number;
  thisMonthConfirmed: number;
  thisMonthCancelled: number;
  hoursBooked: number;
  revenueThisMonth: number;
  revenueIsPartial: boolean;
  upcoming: (ReservationDto & { fieldName: string })[];
  byDay: DayBucket[];
}

export function useDashboardStats(): DashboardStats {
  const { data: fields, isLoading: fieldsLoading } = useMyFields();
  const fieldIds: string[] = (fields ?? [] as FieldDto[]).map((f: FieldDto) => f.id);

  const reservationQueries = useQueries({
    queries: fieldIds.map((fieldId: string) => ({
      queryKey: ['reservations', fieldId] as const,
      queryFn: async (): Promise<ReservationDto[]> => {
        const res = await api.get(`/v1/fields/${fieldId}/reservations`);
        return Array.isArray(res.data) ? res.data : (res.data.data ?? []);
      },
      enabled: fieldIds.length > 0,
    })),
  });

  const courtQueries = useQueries({
    queries: fieldIds.map((fieldId: string) => ({
      queryKey: ['courts', fieldId] as const,
      queryFn: async (): Promise<CourtDto[]> => {
        const res = await api.get(`/v1/fields/${fieldId}/courts`);
        return Array.isArray(res.data) ? res.data : (res.data.data ?? []);
      },
      enabled: fieldIds.length > 0,
    })),
  });

  const isLoading =
    fieldsLoading ||
    reservationQueries.some(q => q.isLoading) ||
    courtQueries.some(q => q.isLoading);

  const fieldNameMap = Object.fromEntries(
    (fields ?? [] as FieldDto[]).map((f: FieldDto) => [f.id, f.name])
  );

  const allReservations = reservationQueries.flatMap((q, i) =>
    ((q.data as ReservationDto[] | undefined) ?? []).map(r => ({ ...r, fieldName: fieldNameMap[fieldIds[i]] ?? 'Campo' }))
  );

  const totalCourts = courtQueries.reduce((sum, q) => sum + ((q.data as CourtDto[] | undefined)?.length ?? 0), 0);

  const now = new Date();
  const monthStart = startOfMonth(now);
  const monthEnd = endOfMonth(now);

  const thisMonth = allReservations.filter(r =>
    isWithinInterval(new Date(r.startsAt), { start: monthStart, end: monthEnd })
  );

  const courtPriceMap: Record<string, number | null> = {};
  courtQueries.forEach(q => {
    ((q.data as CourtDto[] | undefined) ?? []).forEach(court => {
      courtPriceMap[court.id] = court.pricePerHour;
    });
  });

  const confirmedThisMonth = thisMonth.filter(r => r.status === 'confirmed');

  let hoursBooked = 0;
  let revenueThisMonth = 0;
  let revenueIsPartial = false;

  for (const r of confirmedThisMonth) {
    const hours =
      (new Date(r.endsAt).getTime() - new Date(r.startsAt).getTime()) / 3_600_000;
    hoursBooked += hours;
    const price = courtPriceMap[r.courtId];
    if (typeof price === 'number') {
      revenueThisMonth += hours * price;
    } else {
      revenueIsPartial = true;
    }
  }
  revenueThisMonth = Math.round(revenueThisMonth * 100) / 100;

  const upcoming = allReservations
    .filter(r => r.status !== 'cancelled' && new Date(r.startsAt) > now)
    .sort((a, b) => new Date(a.startsAt).getTime() - new Date(b.startsAt).getTime())
    .slice(0, 8);

  const last30 = eachDayOfInterval({ start: addDays(now, -29), end: now });
  const byDay: DayBucket[] = last30.map(date => {
    const key = format(date, 'yyyy-MM-dd');
    const count = allReservations.filter(
      r => format(new Date(r.startsAt), 'yyyy-MM-dd') === key
    ).length;
    return { label: format(date, 'dd/MM'), date, count };
  });

  return {
    isLoading,
    totalFields: fields?.length ?? 0,
    totalCourts,
    thisMonthTotal: thisMonth.length,
    thisMonthConfirmed: confirmedThisMonth.length,
    thisMonthCancelled: thisMonth.filter(r => r.status === 'cancelled').length,
    hoursBooked: Math.round(hoursBooked * 10) / 10,
    revenueThisMonth,
    revenueIsPartial,
    upcoming,
    byDay,
  };
}
