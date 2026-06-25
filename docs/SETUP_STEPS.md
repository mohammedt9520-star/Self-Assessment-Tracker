# Ministry Tracker — Setup Steps
## From zero to live in ~30 minutes

---

## PART 1 — SUPABASE (10 minutes)

### Step 1.1 — Create account
1. Go to **https://supabase.com**
2. Click **Start your project** → sign up with Google or email
3. Click **New project**
4. Fill in:
   - **Name:** ministry-tracker
   - **Database password:** choose something strong — save it somewhere
   - **Region:** Europe West (London)
5. Click **Create new project** — takes about 2 minutes to spin up

### Step 1.2 — Run the database schema
1. In your Supabase project, click **SQL Editor** in the left sidebar
2. Click **New query**
3. Open the file `supabase/schema.sql` from your download
4. Select all the text → paste it into the SQL editor
5. Click **Run** (green button)
6. You should see: "Success. No rows returned"

### Step 1.3 — Get your credentials
1. Click **Project Settings** (cog icon, bottom left sidebar)
2. Click **API**
3. Copy these two things — you'll need them in a moment:
   - **Project URL** — looks like `https://abcdefgh.supabase.co`
   - **anon / public** key — long string starting with `eyJ...`

### Step 1.4 — Enable email auth
1. In left sidebar: **Authentication** → **Providers**
2. Make sure **Email** is enabled (it is by default)
3. Optional: Under **Authentication** → **Settings** → turn off "Confirm email" 
   so you don't need to verify your email when you first sign up

---

## PART 2 — CONFIGURE THE APP (5 minutes)

### Step 2.1 — Add your Supabase credentials
1. Open `index.html` in any text editor (Notepad, TextEdit, VS Code)
2. Press **Ctrl+F** (or Cmd+F on Mac) and search for: `YOUR_SUPABASE_URL`
3. You'll find this block near the top of the `<script>` section:

```javascript
const CFG = {
  sbUrl: 'YOUR_SUPABASE_URL',
  sbKey: 'YOUR_SUPABASE_ANON_KEY',
  rate:  0.45,
};
```

4. Replace `YOUR_SUPABASE_URL` with your Project URL
5. Replace `YOUR_SUPABASE_ANON_KEY` with your anon key
6. **Save the file**

It should look like:
```javascript
const CFG = {
  sbUrl: 'https://abcdefgh.supabase.co',
  sbKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  rate:  0.45,
};
```

---

## PART 3 — GITHUB (5 minutes)

GitHub stores your code so Claude can access it later, and it auto-deploys to Cloudflare.

### Step 3.1 — Create GitHub account
1. Go to **https://github.com** → Sign up (free)

### Step 3.2 — Create repository
1. Click the **+** button → **New repository**
2. Fill in:
   - **Repository name:** ministry-tracker
   - **Visibility:** Private (recommended)
3. Click **Create repository**

### Step 3.3 — Upload your files
1. On your new empty repo page, click **uploading an existing file**
2. Drag and drop ALL the files from your download folder:
   - index.html
   - sw.js
   - manifest.json
   - _headers
   - _redirects
   - The `supabase/` folder
   - The `docs/` folder
   - The `.github/` folder
3. Scroll down → click **Commit changes**

---

## PART 4 — CLOUDFLARE PAGES (10 minutes)

### Step 4.1 — Create account
1. Go to **https://cloudflare.com** → Sign up (free)

### Step 4.2 — Create Pages project
1. In Cloudflare dashboard, click **Workers & Pages** in the left sidebar
2. Click **Create** → **Pages** tab → **Connect to Git**
3. Click **Connect GitHub** → Authorize Cloudflare
4. Select your **ministry-tracker** repository
5. Click **Begin setup**
6. Settings:
   - **Project name:** ministry-tracker
   - **Production branch:** main
   - **Build command:** (leave empty)
   - **Build output directory:** /
7. Click **Save and Deploy**
8. Wait ~1 minute → you'll get a URL like `ministry-tracker.pages.dev`

### Step 4.3 — Add GitHub secrets for auto-deploy
So that every time you update the code it auto-deploys:

**Get Cloudflare API Token:**
1. Cloudflare → top right avatar → **My Profile** → **API Tokens**
2. Click **Create Token** → Use template **Edit Cloudflare Pages**
3. Click **Continue to summary** → **Create Token**
4. Copy the token

**Get Cloudflare Account ID:**
1. Cloudflare dashboard → any page → right sidebar shows **Account ID**
2. Copy it

**Add to GitHub:**
1. Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** → Name: `CLOUDFLARE_API_TOKEN` → paste token → Save
3. Click **New repository secret** → Name: `CLOUDFLARE_ACCOUNT_ID` → paste ID → Save

Now whenever you push changes to GitHub, it auto-deploys live.

---

## PART 5 — PWA ICONS (5 minutes)

The app needs icons to install on your phone.

### Step 5.1 — Generate icons
1. Go to **https://maskable.app/editor**
2. Design a simple icon:
   - Background colour: `#0f2318` (dark forest green)
   - Add a ☪ symbol or crescent in gold `#c8a84b`
3. Export at 512×512 → save as `icon-512.png`

Or use any online "favicon generator" — upload any image, it'll create all sizes.

### Step 5.2 — Create icons folder
1. In your GitHub repo, create a folder called `icons`
2. Upload: `icon-72.png`, `icon-96.png`, `icon-192.png`, `icon-512.png`

---

## PART 6 — INSTALL ON YOUR PHONE

### Android (Chrome):
1. Open Chrome → go to your `ministry-tracker.pages.dev` URL
2. Chrome will show a banner "Add to Home screen" — tap it
3. Or: tap the 3-dot menu → "Add to Home screen"
4. Long-press the icon for quick shortcuts (Add Mileage, Add Parking, Add Expense)

### iPhone (Safari):
1. Open Safari → go to your URL
2. Tap the Share button (box with arrow)
3. Scroll down → "Add to Home Screen"

---

## PART 7 — FIRST LOGIN

1. Open the app
2. Tap **Create account** link at the bottom
3. Enter your email and a password
4. If email confirmation is on: check your email and click the link
5. You're in — start adding expenses

---

## GIVING CLAUDE ACCESS LATER

When you want Claude to edit the app:

**Option A — Upload the file:**
1. Download `index.html` from your GitHub repo
2. Upload it to Claude and say "here is the current Ministry Tracker app, please [your change]"
3. Claude will give you back the updated file
4. Upload the new file to GitHub → auto-deploys

**Option B — Claude Code (advanced):**
Install Claude Code CLI and connect it to your GitHub repo for direct access.

**Always include** the `docs/HANDOVER.md` file when asking Claude for help — it contains all the technical context Claude needs.

---

## TROUBLESHOOTING

**App stuck on loading screen:**
- Check your Supabase URL and key are correct in index.html
- Make sure you ran schema.sql in Supabase

**Can't log in:**
- Check email confirmation is disabled in Supabase Auth settings
- Try "Create account" first

**Expenses not saving:**
- Check Supabase is running (supabase.com → your project)
- Check browser console for errors (F12 → Console)

**Excel export not downloading:**
- Allow downloads in your browser settings

---

## YOUR LIVE URL

After Cloudflare deploys:
```
https://ministry-tracker.pages.dev
```

Or if you add a custom domain:
```
https://tracker.yourdomain.com
```
