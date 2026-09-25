# Northfield Capital Finance — Loan Management

A single-page loan origination and disbursement system built for Northfield Capital Finance (Pvt) Ltd,
modelled directly on a Salary Based Loan Application Form and a Disbursement Form /
Loan Schedule workbook.

## What's in this repo

- `index.html` — the application. Everything (markup, styles, and logic) is in this one file by
  design: there is no build step, no bundler, and no external JS dependencies to install.

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

This app was built and is currently running inside Claude's artifact runtime, which provides two
things this code depends on directly:

- A small document/collection data store (`window.claude.use("db")`), used for `applications`,
  `customers`, and `settings/config`.
- Viewer identity (`window.claude.use("user")`), used to know who's acting and whether they have
  edit-level access (this is what the Administrator gate in System Settings actually checks).

**This is the one thing to know before you push it to GitHub Pages or any other static host:**
those two calls only resolve inside that runtime. Hosted as a plain static file, `claude.use` will
be undefined, so the app will fail to load data. This code is not wired to a general-purpose
backend (Firebase, Supabase, a REST API, etc.) — that layer would need to be written and swapped
in for `db` and `userCap` at the top of the script if you want this running independently of
Claude. The `LoanCalculator`, `Validation`, and all the UI code have no such dependency and would
carry over unchanged.

If you mainly want this on GitHub as source control / a portfolio reference rather than a live
deployed backend, pushing it as-is is perfectly reasonable — just don't expect GitHub Pages to
serve a working data layer without that swap.

## Suggested repo structure

```
.
├── index.html
└── README.md
```

Nothing else is required to open and read the file locally.
