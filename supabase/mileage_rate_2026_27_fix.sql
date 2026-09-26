-- ================================================================
--  ONE-OFF FIX — HMRC raised the mileage rate 45p -> 55p (first
--  10,000 miles) from 6 April 2026, i.e. for the 2026-2027 tax year.
--
--  This corrects any mileage entries already saved for 2026-2027 at
--  the old 45p rate. It does NOT touch entries already saved at 0.25
--  (the over-10,000-miles rate, which HMRC did not change).
--
--  Run the PREVIEW first. If the rows look right, run the UPDATE.
--  Safe to re-run — it only ever matches rows still sitting at 0.45.
-- ================================================================

-- 1) PREVIEW — see exactly what will change, with before/after values
select
  id, date, description, miles,
  mileage_rate as old_rate,
  amount       as old_amount,
  0.55                              as new_rate,
  round(miles * 0.55, 2)            as new_amount
from public.expenses
where category   = 'mileage'
  and tax_year   = '2026-2027'
  and mileage_rate = 0.45
order by date;

-- 2) UPDATE — uncomment and run once you're happy with the preview above
-- update public.expenses
-- set
--   mileage_rate = 0.55,
--   claim        = round(miles * 0.55, 2),
--   amount       = round(miles * 0.55, 2)
-- where category   = 'mileage'
--   and tax_year   = '2026-2027'
--   and mileage_rate = 0.45;

-- 3) VERIFY — confirm nothing is left on the old rate for this tax year
-- select count(*) from public.expenses
-- where category = 'mileage' and tax_year = '2026-2027' and mileage_rate = 0.45;
-- (should return 0)
