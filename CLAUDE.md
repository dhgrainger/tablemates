# CLAUDE.md

Tablemates — a mobile-first web app for hosting dinner parties and potlucks: invite link → account-less RSVP → live contribution board → cost logging → fewest-payments settle-up with Venmo links. The original brief is `tablemates_context.md`.

## Commands

```bash
bin/setup               # starts Postgres (docker compose), installs gems, prepares DB, starts server
bin/dev                 # web + tailwind watcher (needs `docker compose up -d --wait db` first)
bin/rails test          # unit / controller / component tests
bin/rails test:system   # headless Chrome system tests
bin/rubocop             # style (rails-omakase)
bin/brakeman            # security scan
```

Ruby is pinned in `.ruby-version` (rbenv). Postgres runs from `compose.yml` on `localhost:5432`; override with `DATABASE_HOST/PORT/USER/PASSWORD`.

All four checks (test, test:system, rubocop, brakeman) must pass before committing.

## Stack (do not deviate without asking)

- Rails 8, PostgreSQL, Importmap — **no Node build step**
- Hotwire: Turbo Drive / Frames / Streams + Stimulus. Live updates use `broadcasts_refreshes` + Turbo morphing, not hand-written stream templates.
- ERB views + ViewComponent (`app/components`) for reusable UI
- Tailwind CSS v4 + daisyUI 5. daisyUI is vendored as `app/assets/tailwind/daisyui*.js` and loaded with `@plugin`; the custom `tablemates` theme lives in `app/assets/tailwind/application.css`.
- Solid Queue / Solid Cache / Solid Cable, Active Storage
- Minitest, including system tests for key flows
- Rails 8 authentication generator for hosts (`Authentication` concern, `Current.user`)

## Domain model

- `User` — a host account. Guests never have accounts.
- `Event` — a party. `invite_token` is the shareable link secret. Status: `planning → closed → settled`.
- `Invitation` — one person at one event (the host has one too, so all split logic works on invitations). `access_token` is that guest's personal secret.
- `Contribution` — an item someone brings; `cost_cents`; `shared: false` means a gift, excluded from the split.
- `Settlement` — a fixed payment between two invitations, created when the host closes out the party.

## Money rules

- All money is **integer cents, USD**. Never use floats for money — not in models, services, helpers or views.
- Parse user-entered dollar amounts and format cents for display in one place only (`Money`).
- Fair shares use `divmod`; balances must always sum to exactly zero (asserted in `FairShares`).
- Venmo is the only payment provider. There is no Venmo API: build pre-filled links in `PaymentsHelper#venmo_pay_url` only. Do not add a payment-provider abstraction.

## Security rules

- Authorize **every** controller action: host (User session) vs. guest (Invitation access token) vs. stranger.
- Party-scoped controllers load records through the viewer's event (`PartyAccess` concern), never by bare id.
- Tokens come from `has_secure_token`. Never render one guest's `access_token` to anyone else (views, JSON, broadcasts, logs).
- Strong params everywhere (`params.expect`).
- Validate amounts (non-negative, sane max), Venmo usernames (`VenmoUsername` concern), and uploads (images only, size limit).
- No secrets in code — Rails credentials / ENV. Demo credentials live only in `db/seeds.rb` and the README.
- Any new guest-facing action needs a test proving a guest of another event, and a different guest of the same event, cannot use it.

## Conventions

- Mobile-first: design at 375px wide, big tap targets (`btn-lg`, `input-lg` for primary actions).
- Use daisyUI component classes and theme colours (`primary`, `base-200`, …) rather than raw palette colours.
- Small vertical slices; tests alongside each change.
- Work happens on the `mvp` branch; `main` is merged by the owner.

## Out of scope for the MVP

SMS invites, push notifications, native apps, payment providers other than Venmo, in-app payments, recurring dinner clubs, dietary-preference tracking.
