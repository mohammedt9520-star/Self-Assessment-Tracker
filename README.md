# ☪ Ministry Expense Tracker

Professional expense tracking for ministers, imams and faith leaders.

A single-file PWA (no build step) backed by Supabase (auth + Postgres),
designed to be hosted on Cloudflare Pages.

## Getting started

This repo ships without any Supabase project wired up. Follow
`docs/SETUP_STEPS.md` (or `docs/REBUILD_PROMPT.md` for a Claude Code
walkthrough) to create your own free Supabase project, run
`supabase/schema.sql`, and drop your project's URL/anon key into the
`CFG` object near the top of the `<script>` block in `index.html`.

## For future Claude edits
Upload index.html + docs/HANDOVER.md to Claude and describe your change,
or open this repo directly in Claude Code.
