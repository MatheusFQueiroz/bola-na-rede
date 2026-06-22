# Seed + Web Dashboard Fixes

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix HATEOAS double-nesting in 3 frontend hooks (fields, courts, reservations) and run a clean seed.

**Architecture:** All fixes are in `bolanarede_web/src/hooks/`. Root cause: `@HateoasList` wraps each item as `{data: T, _links}`. Frontend extracts `res.data.data` (the array) but misses `.data` on each element. 4th fix corrects `datetime-local` timezone in the reservations form.

**Tech Stack:** Next.js 16, React Query v5, Tailwind v4, shadcn base-nova

---

## Bug Summary

| Bug | File | Line | Symptom |
|-----|------|------|---------|
| fetchMyFields doesn't unwrap items | `use-fields.ts` | 21 | Field cards show undefined names, links broken |
| fetchCourts doesn't unwrap items | `use-courts.ts` | 16 | Court selector blank → no slots → availability grid dead |
| fetchReservations doesn't unwrap items | `use-reservations.ts` | 19 | Reservations table empty/crashes |
| datetime-local no timezone | `reservations/page.tsx` | 88–95 | Reservations created 3h off (UTC vs BRT) |

---

## Task 1: Fix `fetchMyFields` HATEOAS unwrap

**Files:**
- Modify: `bolanarede_web/src/hooks/use-fields.ts:21`

- [ ] **Step 1: Apply fix**

Replace lines 19–22 in `use-fields.ts`:

```ts
// Before
async function fetchMyFields(): Promise<FieldDto[]> {
  const res = await api.get('/v1/fields/mine');
  return Array.isArray(res.data) ? res.data : (res.data.data ?? []);
}

// After
async function fetchMyFields(): Promise<FieldDto[]> {
  const res = await api.get('/v1/fields/mine');
  const items: (FieldDto & { data?: FieldDto })[] = Array.isArray(res.data) ? res.data : (res.data.data ?? []);
  return items.map(item => item.data ?? item);
}
```

- [ ] **Step 2: Verify**

Navigate to `http://localhost:3001/fields`. Field cards should show real names ("Arena Society Xaxim", "Campo do Ze") and link correctly to `/fields/<uuid>/courts`.

---

## Task 2: Fix `fetchCourts` HATEOAS unwrap

**Files:**
- Modify: `bolanarede_web/src/hooks/use-courts.ts:16`

- [ ] **Step 1: Apply fix**

```ts
// Before
async function fetchCourts(fieldId: string): Promise<CourtDto[]> {
  const res = await api.get(`/v1/fields/${fieldId}/courts`);
  return Array.isArray(res.data) ? res.data : (res.data.data ?? []);
}

// After
async function fetchCourts(fieldId: string): Promise<CourtDto[]> {
  const res = await api.get(`/v1/fields/${fieldId}/courts`);
  const items: (CourtDto & { data?: CourtDto })[] = Array.isArray(res.data) ? res.data : (res.data.data ?? []);
  return items.map(item => item.data ?? item);
}
```

- [ ] **Step 2: Verify**

Go to `/fields/<id>/availability`. Court selector should show real court names ("Quadra Society A", "Quadra Futsal B"). After selecting one, the week grid should show available hours (green outline cells for Mon–Fri 18:00–21:00 and Sat–Sun 08:00–21:00).

---

## Task 3: Fix `fetchReservations` HATEOAS unwrap

**Files:**
- Modify: `bolanarede_web/src/hooks/use-reservations.ts:19`

- [ ] **Step 1: Apply fix**

```ts
// Before
async function fetchReservations(fieldId: string): Promise<ReservationDto[]> {
  const res = await api.get(`/v1/fields/${fieldId}/reservations`);
  return Array.isArray(res.data) ? res.data : (res.data.data ?? []);
}

// After
async function fetchReservations(fieldId: string): Promise<ReservationDto[]> {
  const res = await api.get(`/v1/fields/${fieldId}/reservations`);
  const items: (ReservationDto & { data?: ReservationDto })[] = Array.isArray(res.data) ? res.data : (res.data.data ?? []);
  return items.map(item => item.data ?? item);
}
```

- [ ] **Step 2: Verify**

Go to `/fields/<id>/reservations`. Table should show the seed reservations with real dates, court names, channels, and statuses. On `/fields/<id>/availability`, seed reservations should appear as filled (primary-colored) cells on the grid (they're in past dates so they'll be visible but non-clickable past cells).

---

## Task 4: Fix datetime-local timezone in reservations form

**Files:**
- Modify: `bolanarede_web/src/app/(dashboard)/fields/[id]/reservations/page.tsx:88–95`

- [ ] **Step 1: Apply fix**

```ts
// Before
const onSubmit = async (data: FormData) => {
  try {
    await createReservation.mutateAsync(data);

// After
const onSubmit = async (data: FormData) => {
  try {
    await createReservation.mutateAsync({
      ...data,
      startsAt: new Date(data.startsAt).toISOString(),
      endsAt: new Date(data.endsAt).toISOString(),
    });
```

- [ ] **Step 2: Verify**

Create a manual reservation from the reservations table for tomorrow at 19:00 local time. In the agenda view, it should appear at 19:00 (not 22:00 or 16:00).

---

## Task 5: Run clean seed

- [ ] **Step 1: Ensure all Docker containers are up**

```bash
cd /c/bola-na-rede/bolanarede_api
docker compose ps
```

All services should be running (identity, team, field, open-game, social, matchmaking, game, ranking, notification, nginx).

- [ ] **Step 2: Run seed**

```bash
chmod +x seed.sh && ./seed.sh
```

Expected output:
- All DBs truncated
- 13 users registered (dono + 12 players)
- 2 fields with 3 courts total
- Availability slots set for all courts
- 13 reservations created across both fields
- 3 teams created with members
- 7 peladas created
- 5 completed games (for ranking history)
- 2 open match requests

- [ ] **Step 3: Verify seed output**

```bash
# Check field was created
curl -s http://localhost:3000/v1/fields?city=Curitiba | jq '.data | length'
# Should return 2

# Check ranking was populated
curl -s http://localhost:3000/v1/rankings/players | jq '.data | length'
# Should return > 0
```

- [ ] **Step 4: Login to web dashboard**

Navigate to `http://localhost:3001`, login with `dono@bolanarede.com` / `senha123`.
Verify: 2 field cards visible with correct names.

---

## Verification Checklist

After all tasks:

1. Fields list: 2 cards with names
2. Courts tab: lists real courts with names
3. Availability tab: court selector works, week grid shows colored cells for available hours
4. Availability tab: clicking a future available cell opens dialog → clicking "Confirmar reserva" creates the reservation and it appears as primary-colored cell
5. Reservations tab: table shows seed reservations with dates, courts, statuses
6. Reservations tab: "Nova Reserva" dialog → fill form → created reservation appears in table
