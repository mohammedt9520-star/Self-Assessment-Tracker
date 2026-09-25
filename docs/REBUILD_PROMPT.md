# Rebuild Prompt — paste this into a new Claude Code session

This file is written so it can be copy-pasted, as-is, as the **first message**
in a brand-new Claude Code session (with this repository — or just this
`docs/` folder plus the other files listed below — attached/checked out).
It contains no personal data, live credentials, or account details: every
secret has been replaced with a placeholder that Claude Code will help you
fill in during setup.

---

## Prompt to paste

> I want you to set up and deploy a web app called **Ministry Expense
> Tracker**. The full source code already exists in this repository — it's
> a complete, working app — but it has no backend wired up yet. Your job is
> to get it running end-to-end for me.
>
> **What the app is:**
> A single-page Progressive Web App (installable on phone home screens) for
> ministers, imams and other faith leaders to track ministry-related
> expenses for UK Self Assessment (HMRC) tax returns, across tax years, and
> export a professional Excel/CSV/PDF report to send to an accountant.
>
> **Stack (already implemented, do not change frameworks):**
> - Plain HTML/CSS/JavaScript in a single file, `index.html` — no build
>   step, no bundler, no framework.
> - Supabase for auth (email/password) and Postgres storage, loaded via the
>   Supabase JS CDN script.
> - `sw.js` service worker for offline caching + `manifest.json` for PWA
>   installability.
> - Designed to host as static files on Cloudflare Pages (or any static
>   host) with `.github/workflows/deploy.yml` auto-deploying `main` on push.
>
> **Files you should find in the repo:**
> - `index.html` — the entire app (styles + markup + JS in one file)
> - `sw.js`, `manifest.json`, `_headers`, `_redirects`
> - `supabase/schema.sql` — full DB schema, RLS policies, triggers
> - `docs/HANDOVER.md` — technical map of `index.html`'s structure and the
>   business rules (tax-year logic, mileage rate, proportional expense
>   calculations) — read this fully before changing any code
> - `docs/SETUP_STEPS.md` — plain-English setup walkthrough
> - `.github/workflows/deploy.yml` — Cloudflare Pages deploy action
>
> **What I need you to actually do:**
> 1. Read `docs/HANDOVER.md` in full so you understand the app's structure
>    and business rules before touching anything.
> 2. Help me create a new Supabase project (ask me for the project URL and
>    anon/public API key once I've created it, or use the Supabase MCP
>    tools if they're available to you), then run `supabase/schema.sql`
>    against it exactly as-is.
> 3. Replace the placeholder values in the `CFG` object near the top of the
>    `<script>` block in `index.html` (`sbUrl: 'YOUR_SUPABASE_URL'` and
>    `sbKey: 'YOUR_SUPABASE_ANON_KEY'`) with the real values from step 2.
>    Never hard-code a database password or service-role key anywhere — only
>    the public anon key belongs in client-side code.
> 4. Confirm email auth is enabled in Supabase (Authentication → Providers),
>    and ask me whether I want "Confirm email" on or off.
> 5. Generate or ask me for four PWA icon files (`icon-72.png`,
>    `icon-96.png`, `icon-192.png`, `icon-512.png`) in an `icons/` folder —
>    dark forest green background (`#0f2318`) with a gold (`#c8a84b`)
>    crescent/☪ mark, per `manifest.json`.
> 6. Set up hosting: either walk me through connecting this repo to
>    Cloudflare Pages (build command: none, output directory: `/`), or ask
>    which static host I'd prefer, and wire up the GitHub Action secrets it
>    needs (`CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`) if using
>    Cloudflare.
> 7. Once deployed, do a smoke test: sign up a test account, add one of
>    each expense category (mileage, parking, phone, home, software,
>    equipment, other), confirm the dashboard totals and tax-year grouping
>    are correct, and run each export format (Excel, CSV, PDF, accountant).
> 8. Tell me the final live URL and summarize anything I still need to do
>    manually (e.g. a custom domain).
>
> **Ground rules while you work:**
> - This is a single-file app on purpose — keep all app logic in
>   `index.html` unless I explicitly ask you to split it up.
> - Every place user-supplied text is inserted into the DOM must go through
>   the existing `esc()` helper — never use raw `innerHTML` with unescaped
>   user data.
> - Don't change the UK tax-year logic in the `taxYear()` function — it's
>   deliberately simple (6 April cutoff) and already correct.
> - Every Supabase table must keep Row Level Security enabled with
>   `auth.uid() = user_id` policies — don't weaken this.
> - Don't invent new npm dependencies or a build pipeline; this app is
>   intentionally zero-build.
> - If you make any change to `index.html`, run `node --check` (extract the
>   `<script>` contents or use a quick regex) to catch syntax errors before
>   telling me it's done.

---

## If you're starting from *only* this prompt (no source files)

If for some reason the rest of the repository isn't available and you only
have this document, tell Claude Code that explicitly and ask it to
regenerate `index.html`, `sw.js`, `manifest.json`, `supabase/schema.sql`,
`_headers` and `_redirects` from the structural description and business
rules in `docs/HANDOVER.md` (copy that file's contents into the chat too —
it documents every function, screen, and data rule the app needs). This is
a fallback path only; handing over the real source files is far more
reliable than asking an LLM to reconstruct ~3,000 lines of working code
from a spec.
