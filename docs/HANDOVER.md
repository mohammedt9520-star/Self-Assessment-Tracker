# Ministry Expense Tracker — Master Handover Document

## Project Summary
Single-file PWA for Imam/faith leader expense tracking.
Built for UK self-assessment (HMRC) — tracks ministry expenses across tax years.
Stack: vanilla HTML/CSS/JS + Supabase (auth + PostgreSQL) + Cloudflare Pages.

---

## Live Architecture

```
Browser (PWA)
  └── index.html          Single file — all CSS, HTML and JS
  └── sw.js               Service worker (offline caching)
  └── manifest.json       PWA installability
  └── _headers            Cloudflare security headers
  └── _redirects          SPA routing fallback

Cloudflare Pages          Hosting (free tier, global CDN)
  └── Auto-deploy         GitHub main branch → live

Supabase                  Database + Auth
  └── auth.users          Managed by Supabase Auth
  └── public.profiles     Auto-created on signup
  └── public.expenses     All expense records (RLS secured)
  └── public.evidence     Receipt attachments (future)
  └── public.activity_logs Auto-created from mileage
  └── public.tax_years    Reference table (2021-2028)
```

---

## File: index.html — Structure

The entire app is one HTML file. Key sections in order:

```
<head>
  Meta tags, CSP, fonts, Supabase CDN, XLSX CDN
<style>
  All CSS — design system variables, component styles
<body>
  #ld              Loading screen
  #toast           Toast notification
  #auth-wrap       Login / signup screen
  #app-wrap        Main app shell
    #s-dashboard   Dashboard screen
    #s-history     History screen  
    #s-analytics   Analytics screen
    #s-export      Export screen
    #s-settings    Settings screen
    #nav            Bottom navigation
  Overlays:
    #ov-cat        Category picker sheet
    #ov-form       Expense form sheet
    #ov-det        Expense detail sheet
    #ov-set        Settings edit sheet
<script>
  -- Configuration --
  function esc()           HTML escape (security — use on ALL user data)
  CFG object               sbUrl, sbKey, rate
  
  -- State --
  _db, me, expenses[]      Core state variables
  hFilter, dashYear, anYear, expSelYear
  
  -- UK Tax Year Logic --
  function taxYear(date)   Returns '2024-2025' from any date
  function tyLabel(ty)     '6 Apr 2024 – 5 Apr 2025'
  function tyShort(ty)     '24/25'
  function nowYear()       Current tax year slug
  function allYears()      All years with data + current
  
  -- Supabase --
  function initDb()        Creates _db client
  async function boot()    Entry point — checks session
  
  -- Screen routing --
  function showApp()       Show main app, hide auth
  function showAuth()      Show login screen
  function showSetup()     Show config error (no credentials)
  function hideLoad()      Remove loading spinner
  function showScreen(name, navIdx)
  
  -- Auth --
  async function doAuth()  Login or signup
  async function doSignOut()
  function toggleAuth()    Switch login ↔ signup mode
  
  -- Data --
  async function fetchExp()         Load all expenses from Supabase
  async function saveExp(payload)   Insert expense (auto-assigns tax year)
  async function delExp(id)         Delete expense
  
  -- Dashboard --
  function refreshDash()    Rebuild all dashboard UI
  function setDashYear(y)   Switch tax year tab
  function jumpHist(cat)    Navigate to history filtered by category
  
  -- History --
  function renderHistory()  Rebuild history list
  function setHF(f, btn)    Set history filter
  
  -- Analytics --
  function renderAnalytics()
  function setAnYear(y)
  
  -- Export --
  function renderExport()
  function setExpYear(y)
  function doExport(format)         'xlsx'|'csv'|'pdf'|'accountant'
  
  -- Excel export (main) --
  XL_COLORS               ARGB colour palette
  function buildCoverSheet(data, years, name, email)
  function buildYearSheet(yd, ty)
  function buildMileageSheet(data)
  function exportXlsx(data, label)
  
  -- Other exports --
  function exportCsv()
  function exportPdf()
  function exportAccountant()
  
  -- Forms --
  function openCatPicker()
  function openForm(cat)
  function buildForm(cat)   Returns HTML string for each category
  function onDateChange()   Updates tax year hint when date changes
  function calcClaim()      Miles × rate = claim
  async function calcDist() Simulated distance (connect Worker for real)
  async function submitForm(cat)
  
  -- Settings --
  function loadSettingsDisplay()
  function editRate() / saveRate()
  function editName() / saveName()
  
  -- Overlays --
  function openOv(id) / closeOv(id)
  
  -- Helpers --
  function fmt(n)       '£12.50'
  function fmtK(n)      '£1.2k'
  function fmtDate(ds)  'Today' | 'Yesterday' | 'Mon 3 January 2024'
  function shortDate(ds) '3 Jan'
  catIcon(c) / catLabel(c)   Category icon emoji / label
```

---

## Key Business Rules

### Tax Year Assignment
Every expense is assigned on save via `taxYear(date)`:
- On or after 6 April of year Y → `Y-(Y+1)` e.g. `2025-2026`
- Before 6 April of year Y → `(Y-1)-Y` e.g. `2024-2025`
- **The date field in the form drives this — backdated entries work automatically**

### HMRC Mileage
- Default rate: 45p (0.45) per mile — first 10,000 miles
- Over 10,000 miles: 25p (0.25) — user changes rate in Settings
- Claim = miles × rate, stored in `expenses.amount`

### Proportional Expenses (Phone / Home / Equipment)
- User enters total bill + ministry use %
- `amount` stored = `total × (pct / 100)` — only the claimable portion

### Row Level Security
Every Supabase table has RLS. Users can only read/write rows where `user_id = auth.uid()`.
This is enforced at database level — even if someone manipulates the JS they cannot access other users' data.

---

## Excel Export Structure

When user taps Export → Excel, `exportXlsx()` builds:

**Sheet 1: Summary**
- Your name + generation date header
- Tax year × category cross-tab table (one row per year, one col per category group)
- Grand total row
- HMRC notes for accountant

**Sheets 2-N: Per Tax Year** (e.g. "24/25", "23/24")
- Year total header
- Category subtotals block (colour-coded by category)
- Full expense log sorted by date (category-colour-banded rows)

**Final Sheet: Mileage Log**
- Every journey across all years
- Grouped by tax year with subtotals
- All HMRC-required fields: Date, Purpose, From, To, Miles, Rate, Claim

---

## Supabase Setup Reference

**Project settings needed:**
- Region: eu-west-2 (London) recommended
- Auth: Email provider enabled, Confirm email: optional (disable for easier testing)

**Tables:** profiles, expenses, evidence, activity_logs, tax_years

**Key policies:** All via RLS — `auth.uid() = user_id`

**Triggers:**
- `on_auth_user_created` → creates profile row
- `trg_expenses_updated` → updates `updated_at`
- `trg_auto_activity` → creates activity log from mileage entries

---

## Cloudflare Pages Setup Reference

**Build settings:**
- Framework: None
- Build command: (empty)
- Build output: `/` (root)
- Root: `/`

**Environment variables:** None needed (credentials are in index.html)

**Custom domain:** Add in Pages → Custom domains

---

## GitHub Repository Structure

```
ministry-tracker/          ← repo root
├── index.html             ← THE APP (edit this)
├── sw.js                  ← Service worker
├── manifest.json          ← PWA manifest
├── _headers               ← Cloudflare headers
├── _redirects             ← SPA routing
├── icons/                 ← PWA icons (add these)
│   ├── icon-72.png
│   ├── icon-96.png
│   ├── icon-192.png
│   └── icon-512.png
├── supabase/
│   └── schema.sql         ← Database schema
├── docs/
│   └── HANDOVER.md        ← This file
└── .github/
    └── workflows/
        └── deploy.yml     ← Auto-deploy to Cloudflare
```

---

## GitHub Secrets Required

In GitHub repo → Settings → Secrets → Actions:

| Secret | Where to get it |
|--------|----------------|
| `CLOUDFLARE_API_TOKEN` | Cloudflare dashboard → My Profile → API Tokens → Create Token → "Edit Cloudflare Pages" template |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare dashboard → right sidebar on any page |

---

## Giving Claude Access for Future Edits

When starting a new Claude conversation:
1. Upload `index.html` and say "this is the current Ministry Tracker app"
2. Reference this HANDOVER.md for context
3. Claude will read the file fully before making any changes

Or connect via Claude Code (CLI) for direct file access.

**Key things to tell Claude:**
- It's a single-file PWA — all changes go in index.html
- Supabase credentials are in the CFG object at the top of the script
- Tax year logic is in the `taxYear()` function — don't change it
- Always use `esc()` on user data before innerHTML
- Run `node --check` on the extracted JS before delivering

---

## Pending / Future Work

- [ ] Add real Google Maps distance (Cloudflare Worker proxy — see worker.js in original package)
- [ ] Receipt photo uploads (Supabase Storage bucket — SQL commented in schema.sql)
- [ ] Push notifications for expense reminders
- [ ] HMRC SA105 export template
- [ ] Multiple users / organisation sharing

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1 | Jun 2025 | Initial build |
| v2 | Jun 2025 | UI redesign, tax year logic, basic export |
| v3 | Jun 2025 | Security audit, auth fixes, professional Excel export |
