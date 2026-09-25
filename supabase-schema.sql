-- Northfield Capital Finance — Loan Management
-- Run this once in your Supabase project's SQL editor (Database > SQL Editor > New query).
-- Safe to re-run: each statement either creates something new or is idempotent where noted.

-- ---------- Tables ----------
-- Applications and customers are stored as one jsonb "data" column each, matching the shape
-- the app already builds in the browser (customerName, amountApplied, charges, schedule, ...).
-- status and created_at are pulled out as real columns purely so they can be indexed/ordered on.

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  data jsonb not null default '{}'::jsonb
);

create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  status text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  data jsonb not null default '{}'::jsonb
);

-- Single-row-per-key configuration store. key = 'config' holds System Settings.
create table if not exists public.settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

-- One row per signed-up user. role is 'officer' (default), 'approver', or 'admin'.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null default 'officer' check (role in ('officer','approver','admin')),
  created_at timestamptz not null default now()
);

-- ---------- New-signup trigger: auto-create a profile row ----------
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', new.email), 'officer');
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- Row Level Security ----------
alter table public.customers enable row level security;
alter table public.applications enable row level security;
alter table public.settings enable row level security;
alter table public.profiles enable row level security;

-- Any signed-in staff member can read and write customer and application records.
drop policy if exists "authenticated read customers" on public.customers;
create policy "authenticated read customers" on public.customers for select using (auth.role() = 'authenticated');
drop policy if exists "authenticated write customers" on public.customers;
create policy "authenticated write customers" on public.customers for insert with check (auth.role() = 'authenticated');
drop policy if exists "authenticated update customers" on public.customers;
create policy "authenticated update customers" on public.customers for update using (auth.role() = 'authenticated');

drop policy if exists "authenticated read applications" on public.applications;
create policy "authenticated read applications" on public.applications for select using (auth.role() = 'authenticated');
drop policy if exists "authenticated insert applications" on public.applications;
create policy "authenticated insert applications" on public.applications for insert with check (auth.role() = 'authenticated');
drop policy if exists "authenticated update applications" on public.applications;
create policy "authenticated update applications" on public.applications for update using (auth.role() = 'authenticated');

-- Everyone signed in can read the current rates (needed to calculate new applications).
-- Only administrators can change them — enforced here, not just hidden in the UI.
drop policy if exists "authenticated read settings" on public.settings;
create policy "authenticated read settings" on public.settings for select using (auth.role() = 'authenticated');
drop policy if exists "admin insert settings" on public.settings;
create policy "admin insert settings" on public.settings for insert with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);
drop policy if exists "admin update settings" on public.settings;
create policy "admin update settings" on public.settings for update using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);

drop policy if exists "authenticated read profiles" on public.profiles;
create policy "authenticated read profiles" on public.profiles for select using (auth.role() = 'authenticated');
drop policy if exists "user updates own profile" on public.profiles;
create policy "user updates own profile" on public.profiles for update using (auth.uid() = id);

-- ---------- Realtime ----------
-- Lets onSnapshot-style subscriptions in the app receive live updates.
alter publication supabase_realtime add table public.applications;
alter publication supabase_realtime add table public.customers;
alter publication supabase_realtime add table public.settings;

-- ---------- Making yourself an administrator ----------
-- After you've signed up once through the app, run this (with your email) to grant admin access:
-- update public.profiles set role = 'admin' where id = (select id from auth.users where email = 'you@example.com');
