-- ================================================================
--  MIGRATION — Tax Year Lock (confirm refund & close a tax year)
--  Run this once in Supabase → SQL Editor → Run.
--  Safe on a live database — only ADDS a new table/trigger, does not
--  touch or drop anything existing. Safe to re-run (uses IF NOT EXISTS
--  / OR REPLACE throughout).
-- ================================================================

create table if not exists public.tax_year_status (
  user_id       uuid not null references public.profiles(id) on delete cascade,
  tax_year      text not null references public.tax_years(slug),
  refund_amount numeric(10,2) check (refund_amount >= 0),
  locked        boolean not null default true,
  updated_at    timestamptz default now(),
  primary key (user_id, tax_year)
);
alter table public.tax_year_status enable row level security;
drop policy if exists "Users manage own tax year status" on public.tax_year_status;
create policy "Users manage own tax year status"
  on public.tax_year_status for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function public.touch_tax_year_status()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists trg_tax_year_status_updated on public.tax_year_status;
create trigger trg_tax_year_status_updated
  before update on public.tax_year_status
  for each row execute function public.touch_tax_year_status();

-- Server-side enforcement — belt-and-braces alongside the app's own
-- checks, so a closed tax year truly cannot be written to.
create or replace function public.enforce_tax_year_lock()
returns trigger language plpgsql security definer as $$
declare
  affected_user uuid := coalesce(new.user_id, old.user_id);
  affected_year text := case when tg_op = 'DELETE' then old.tax_year else new.tax_year end;
begin
  if exists (
    select 1 from public.tax_year_status
    where user_id = affected_user and tax_year = affected_year and locked = true
  ) then
    raise exception 'Tax year % is closed — unlock it before adding, editing or deleting entries.', affected_year;
  end if;
  if tg_op = 'UPDATE' and exists (
    select 1 from public.tax_year_status
    where user_id = old.user_id and tax_year = old.tax_year and locked = true
  ) then
    raise exception 'Tax year % is closed — unlock it before adding, editing or deleting entries.', old.tax_year;
  end if;
  return coalesce(new, old);
end;
$$;
drop trigger if exists trg_enforce_tax_year_lock on public.expenses;
create trigger trg_enforce_tax_year_lock
  before insert or update or delete on public.expenses
  for each row execute function public.enforce_tax_year_lock();

-- VERIFY — should return the new table with zero rows
select * from public.tax_year_status;
