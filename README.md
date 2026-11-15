# Tablemates

A mobile-first web app for hosting dinner parties and potlucks.

1. A host creates a party and shares an invite link.
2. Guests open the link and RSVP — no account — and add their Venmo username.
3. Everyone uses a live board to claim what they're bringing.
4. After shopping, people log what they spent (with an optional receipt photo).
5. The host closes out the party and Tablemates works out the fewest payments
   to settle up, each with a "Pay on Venmo" button.

The full brief and the project's conventions live in [`tablemates_context.md`](tablemates_context.md).

## Requirements

- Ruby (version in `.ruby-version`, e.g. via rbenv)
- Docker (for PostgreSQL — see `compose.yml`)
- Google Chrome (system tests only)

## Run it locally

```bash
bin/setup            # starts Postgres, installs gems, prepares the database, starts the app
bin/rails db:seed    # optional demo data (prints guest links)
```

After the first time, `docker compose up -d --wait db && bin/dev` is enough.
The app runs at http://localhost:3000.

### Demo login

`bin/rails db:seed` creates a demo host — **local development only**:

- Email: `demo@tablemates.test`
- Password: `tablemates-demo` (or whatever you set in `DEMO_PASSWORD` when seeding)

Guests don't have accounts; the seed prints a personal link for each demo guest.
Open one in a private window to see the party as that guest.

## Tests and checks

```bash
bin/rails test          # models, services, controllers, components
bin/rails test:system   # headless Chrome, 375px wide
bin/rubocop
bin/brakeman
```

## How it's put together

- **Rails 8** with PostgreSQL, Hotwire (Turbo + Stimulus), Importmap — no Node build step.
- **Tailwind CSS + daisyUI** (vendored in `app/assets/tailwind/`) with a custom `tablemates` theme.
- **ViewComponent** for reusable UI in `app/components`.
- **Live updates**: `Event` broadcasts page refreshes; the party page morphs in place.
- **Guest access**: `/i/:invite_token` to RSVP, `/p/:access_token` as a personal link.
  Tokens are remembered in a signed, http-only cookie. See `PartyAccess` and `GuestAccess`.
- **Money** is integer cents everywhere (`Money`, `FairShares`, `SettleUp`).
- **Venmo** has no API; `PaymentsHelper#venmo_pay_url` builds pre-filled links.

## Configuration

| ENV | Purpose | Default |
|---|---|---|
| `DATABASE_HOST` / `DATABASE_PORT` / `DATABASE_USER` / `DATABASE_PASSWORD` | Dev/test Postgres | `localhost` / `5432` / `postgres` / `postgres` |
| `APP_TIME_ZONE` | Zone party times are entered and shown in | `Eastern Time (US & Canada)` |
| `DEMO_PASSWORD` | Password for the seeded demo host | `tablemates-demo` |
