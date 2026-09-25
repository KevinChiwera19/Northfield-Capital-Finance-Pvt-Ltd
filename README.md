# Northfield Capital Finance — Loan Management

A single-page loan origination and disbursement system built for Northfield Capital Finance (Pvt) Ltd,
modelled directly on a Salary Based Loan Application Form and a Disbursement Form /
Loan Schedule workbook.

## What's in this repo

- `index.html` — the application. All markup, styles, and logic live in this one file; the only
  external code it loads is the Supabase client library from a CDN.
- `supabase-schema.sql` — the database schema, permissions, and realtime setup for Supabase. Run
  once, in the Supabase SQL editor, before pointing `index.html` at your project (see below).

## Architecture, even though it's one file

The script is organised into clearly separated modules rather than one large block of code:

- `LoanCalculator` — the calculation engine. Establishment fee, application fee, insurance fee,
  bank charges, IMTT, net loan, flat-rate interest, and the repayment schedule all live here as
  pure functions, matching the workbook's formulas. No calculation logic lives in the UI code.
- `Validation` — business-rule validation for a loan application (amount limits, tenure limits,
  approved-vs-applied amount, required fields), returning plain human-readable messages.
- `Format` — currency and date formatting, driven by the System Preferences settings.
- `DEFAULT_CONFIG` — the one place default rates and limits are defined, used only until an
  administrator has saved real configuration.
- Page renderers (`pageDashboard`, `pageApplications`, `pageNewApp`, `pageDetail`, `pageCustomers`,
  `pageSettings`) — each owns one screen and nothing else.

## Data and identity

The app supports three backends, chosen automatically at startup, no code path to switch by hand:

1. **Claude's artifact runtime** (`db`/`user` capabilities), when running inside a Claude artifact.
2. **Supabase**, a real hosted Postgres database with authentication and Row Level Security, once
   you've set it up (see below). This is what makes the system genuinely multi-user.
3. **Local fallback** (`LocalDB`/`LocalUser`, backed by `localStorage`), used automatically when
   neither of the above is available — for example, opening `index.html` straight from GitHub
   Pages without having configured Supabase yet. This keeps the app fully functional for one
   person in one browser, with a visible banner saying so, rather than failing or pretending to be
   a shared system.

All three speak the exact same `doc()` / `collection()` / `onSnapshot()` / `get()` / `set()` /
`update()` interface, so the calculation engine, validation, and every page are identical
regardless of which one is active.

### Setting up Supabase (recommended for real use)

1. Create a free project at [supabase.com](https://supabase.com).
2. Open **SQL Editor** in the Supabase dashboard, paste in the contents of `supabase-schema.sql`
   from this repo, and run it. This creates the `applications`, `customers`, `settings`, and
   `profiles` tables, the Row Level Security policies, and enables realtime updates.
3. In **Project Settings > API**, copy your **Project URL** and **anon public key**.
4. In `index.html`, near the top of the `<script>` block, replace:
   ```js
   const SUPABASE_URL = "YOUR_SUPABASE_PROJECT_URL";
   const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
   ```
   with your actual values.
5. Push and open the site. You'll see a sign-in screen — create an account. New accounts default
   to the "Loan Officer" role.
6. To make yourself (or anyone) an Administrator, run the last line in `supabase-schema.sql`
   (with the right email) from the SQL Editor. Administrators can edit System Settings and are
   treated as Approvers as well.
7. To change someone's role to Approver, run: `update public.profiles set role = 'approver' where id = (select id from auth.users where email = '...');`

By default, Supabase requires email confirmation before sign-in works. For quick internal testing
you can turn this off under **Authentication > Providers > Email > Confirm email**, or just
confirm the email from the link Supabase sends.

## Suggested repo structure

```
.
├── index.html
├── supabase-schema.sql
└── README.md
```

Nothing else is required to open and read the file locally.
