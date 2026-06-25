-- ================================================================
--  MINISTRY EXPENSE TRACKER — Supabase Schema v3
--  Run this entire file in Supabase → SQL Editor → Run
-- ================================================================

-- Extensions
create extension if not exists "uuid-ossp";

-- ── Clean slate (safe to re-run) ────────────────────────────────
drop table if exists public.evidence      cascade;
drop table if exists public.activity_logs cascade;
drop table if exists public.expenses      cascade;
drop table if exists public.profiles      cascade;
drop table if exists public.tax_years     cascade;

-- ================================================================
--  PROFILES — auto-created when user signs up
-- ================================================================
create table public.profiles (
  id             uuid primary key references auth.users(id) on delete cascade,
  email          text,
  full_name      text,
  mileage_rate   numeric(5,4) default 0.45,
  created_at     timestamptz  default now(),
  updated_at     timestamptz  default now()
);

alter table public.profiles enable row level security;
create policy "Users own their profile"
  on public.profiles for all
  using  (auth.uid() = id)
  with check (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ================================================================
--  TAX YEARS — reference table
-- ================================================================
create table public.tax_years (
  slug       text primary key,  -- e.g. '2023-2024'
  label      text not null,     -- e.g. '6 April 2023 – 5 April 2024'
  start_date date not null,
  end_date   date not null
);

insert into public.tax_years values
  ('2021-2022', '6 April 2021 – 5 April 2022', '2021-04-06', '2022-04-05'),
  ('2022-2023', '6 April 2022 – 5 April 2023', '2022-04-06', '2023-04-05'),
  ('2023-2024', '6 April 2023 – 5 April 2024', '2023-04-06', '2024-04-05'),
  ('2024-2025', '6 April 2024 – 5 April 2025', '2024-04-06', '2025-04-05'),
  ('2025-2026', '6 April 2025 – 5 April 2026', '2025-04-06', '2026-04-05'),
  ('2026-2027', '6 April 2026 – 5 April 2027', '2026-04-06', '2027-04-05'),
  ('2027-2028', '6 April 2027 – 5 April 2028', '2027-04-06', '2028-04-05');

-- ================================================================
--  EXPENSES — core table
-- ================================================================
create table public.expenses (
  id               uuid        primary key default uuid_generate_v4(),
  user_id          uuid        not null references public.profiles(id) on delete cascade,

  -- Core fields
  category         text        not null
    check (category in ('mileage','parking','books','software','phone','internet',
                        'home','training','stationery','postage','equipment','other')),
  description      text        not null check (char_length(description) <= 500),
  amount           numeric(10,2) not null check (amount >= 0),
  date             date        not null,
  tax_year         text        not null references public.tax_years(slug),
  notes            text        check (char_length(notes) <= 1000),

  -- Mileage
  start_location   text,
  end_location     text,
  miles            numeric(8,2) check (miles >= 0),
  mileage_rate     numeric(5,4) check (mileage_rate > 0),
  claim            numeric(10,2),

  -- Proportional (phone / home / equipment)
  ministry_pct     numeric(5,2) check (ministry_pct between 1 and 100),

  -- Software
  subscription_type text check (subscription_type in ('monthly','annual','one-off')),

  -- Audit
  created_at       timestamptz default now(),
  updated_at       timestamptz default now()
);

-- Indexes for performance
create index idx_expenses_user    on public.expenses(user_id);
create index idx_expenses_date    on public.expenses(date desc);
create index idx_expenses_tax_yr  on public.expenses(tax_year);
create index idx_expenses_cat     on public.expenses(category);

-- RLS — users see only their own data
alter table public.expenses enable row level security;
create policy "Users manage own expenses"
  on public.expenses for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Auto-update updated_at
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
create trigger trg_expenses_updated
  before update on public.expenses
  for each row execute function public.touch_updated_at();

-- ================================================================
--  EVIDENCE — receipt/invoice attachments (future)
-- ================================================================
create table public.evidence (
  id           uuid primary key default uuid_generate_v4(),
  expense_id   uuid not null references public.expenses(id) on delete cascade,
  user_id      uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null,
  file_name    text,
  file_type    text,
  file_size    integer check (file_size > 0),
  created_at   timestamptz default now()
);
create index idx_evidence_expense on public.evidence(expense_id);
alter table public.evidence enable row level security;
create policy "Users manage own evidence"
  on public.evidence for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ================================================================
--  ACTIVITY LOGS — auto-created from mileage entries
-- ================================================================
create table public.activity_logs (
  id            uuid primary key default uuid_generate_v4(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  expense_id    uuid references public.expenses(id) on delete set null,
  activity_type text not null,
  location      text,
  notes         text,
  date          date not null,
  created_at    timestamptz default now()
);
create index idx_activity_user on public.activity_logs(user_id);
create index idx_activity_date on public.activity_logs(date desc);
alter table public.activity_logs enable row level security;
create policy "Users manage own activity logs"
  on public.activity_logs for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Auto-create activity log from mileage expense
create or replace function public.auto_activity_log()
returns trigger language plpgsql security definer as $$
begin
  if new.category = 'mileage' and new.description is not null then
    insert into public.activity_logs (user_id, expense_id, activity_type, location, notes, date)
    values (new.user_id, new.id, new.description, new.end_location, new.notes, new.date);
  end if;
  return new;
end;
$$;
create trigger trg_auto_activity
  after insert on public.expenses
  for each row execute function public.auto_activity_log();

-- ================================================================
--  USEFUL VIEWS
-- ================================================================

-- Tax year summary per user
create or replace view public.v_summary as
select
  e.user_id,
  e.tax_year,
  e.category,
  count(*)::integer       as entries,
  sum(e.amount)           as total,
  sum(e.miles)            as total_miles
from public.expenses e
group by e.user_id, e.tax_year, e.category;

-- ================================================================
--  STORAGE BUCKET FOR RECEIPTS (run separately in dashboard)
-- ================================================================
-- In Supabase dashboard: Storage → New bucket → Name: "evidence" → Private
-- Then add these policies in Storage → Policies:
--
-- INSERT policy:  auth.uid()::text = (storage.foldername(name))[1]
-- SELECT policy:  auth.uid()::text = (storage.foldername(name))[1]
-- DELETE policy:  auth.uid()::text = (storage.foldername(name))[1]

-- ================================================================
--  VERIFY SETUP
-- ================================================================
-- Run this after setup to confirm everything is working:
-- select table_name from information_schema.tables where table_schema = 'public';
-- select * from public.tax_years order by slug;
