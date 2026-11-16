
Build "Tablemates" — a dinner party app (MVP)
Working name is "Tablemates" — rename freely.

What we're building
A mobile-first web app for hosting dinner parties and potlucks. It combines event invites + RSVPs with automatic cost splitting:

A host creates a party and shares an invite link.
Guests open the link, RSVP without creating an account, and add their Venmo username.
The host lists what's needed (mains, wine, dessert…); guests claim items or add their own on a live contribution board.
After shopping, everyone logs what they actually spent (with an optional receipt photo).
The host closes out the party and the app calculates the fewest possible payments to settle up, each with a one-tap "Pay on Venmo" button.
The app must have its own original name, branding and visual design — do not copy the look of any existing app.

Tech stack (do not deviate without asking)
Rails 8, Ruby 3.3+, PostgreSQL (rails new tablemates --database=postgresql --css=tailwind)
Hotwire: Turbo Drive / Frames / Streams + Stimulus. Use broadcasts_refreshes_to + Turbo morphing for live updates.
ERB views + ViewComponent for reusable UI pieces
Tailwind CSS + daisyUI, mobile-first
Importmap — no Node build step
Solid Queue / Solid Cache / Solid Cable (Rails 8 defaults)
Active Storage for cover images and receipt photos
Minitest (Rails default) for tests, including system tests for key flows
Rails 8 built-in authentication generator for hosts (bin/rails generate authentication)
PWA manifest + service worker (Rails 8 defaults) so it can be added to a home screen
Data model
User          email_address, password_digest, name, venmo_username
Event         host (User), title, description, starts_at, location, invite_token (unique),
              status (planning | closed | settled), round_to_whole_dollars:boolean,
              forgive_under_cents:integer (default 0)
Invitation    event, user (optional), guest_name, email (optional),
              access_token (unique), rsvp_status (pending | yes | no | maybe), venmo_username
Contribution  event, invitation (who claimed it, optional), name, category,
              cost_cents:integer (default 0), shared:boolean (default true — false = gift, excluded from split),
              receipt (Active Storage attachment)
Settlement    event, from_invitation, to_invitation, amount_cents:integer,
              paid_at, confirmed_at
The host is also represented by an Invitation on their own event (rsvp yes) so all split logic works on Invitations.
All money is integer cents, USD. Never use floats for money.
Use has_secure_token for invite_token and access_token.
Guest access (no accounts)
GET /i/:invite_token → public invite page: event details + RSVP form (name, optional email, Venmo username).
On RSVP, create an Invitation and redirect to /p/:access_token — the guest's personal party page. Store the access token in a signed, permanent cookie so they stay "logged in" on that device.
Every guest action is authorized by looking up the Invitation from the access token and checking it belongs to the event. Hosts are authorized via their User session.
Write tests proving a guest cannot see or modify another event's data, or edit another guest's contributions.
Settle-up logic
Put this in app/services/settle_up.rb (plus a FairShares calculator) with thorough unit tests.

Who splits: invitations with rsvp_status: yes.
Total: sum of cost_cents for contributions where shared: true.
Fair shares without losing pennies:
base, remainder = total_cents.divmod(attendees.size)
# first `remainder` attendees (ordered by id) pay 1 extra cent
Balance per person = cents they paid − their fair share. Balances must always sum to exactly 0 (assert this).
Minimize payments:
Pass 1: pair any debtor and creditor with exactly equal amounts.
Pass 2: greedy — largest debtor pays largest creditor, repeat until settled.
Result: at most (n − 1) payments; return Payment = Data.define(:from, :to, :amount_cents).
Options (event-level): round each payment to whole dollars (host absorbs difference), and forgive payments under forgive_under_cents.
Settle-up is live/estimated while planning, and becomes fixed Settlement records when the host taps "Close out party". Allow the host to reopen until any settlement is marked paid.
Required test cases: even split, uneven pennies (e.g. $100 / 3), one person paid everything, nobody owes anything, gifts excluded, exact-match pairing, rounding option, forgive-small-debts option, guest with $0 contribution.

Venmo (only payment provider for now)
There is no Venmo API — use pre-filled links only, in a single helper:

# app/helpers/payments_helper.rb
def venmo_pay_url(username:, amount_cents:, note:)
  params = { txn: "pay", recipients: username,
             amount: format("%.2f", amount_cents / 100.0), note: note }.to_query
  "https://account.venmo.com/pay?#{params}"
end
Normalize usernames: strip whitespace and a leading @. Show a "Check it's you" link to https://venmo.com/u/USERNAME.
Note text: e.g. "🍝 Dinner at Alex's – Nov 22".
Payment status is manual: payer taps "I paid" (paid_at), recipient taps "Got it" (confirmed_at).
If a creditor has no Venmo username, block their settlement and prompt them to add one.
Do not build a generic payment-provider abstraction yet.
Screens (mobile-first)
Home / dashboard (host): my upcoming & past parties, "New party" button
Create / edit party: title, date/time, location, description, cover image
Party page (host + guests): details, guest list with RSVP status, live contribution board, copy-invite-link button (Stimulus)
Public invite page /i/:invite_token: details + RSVP form
Contribution board: grouped by category; "I'll bring it" claim button; add your own item; mark as gift; log actual cost + receipt photo. Updates live for everyone via Turbo.
Settle up: each person sees only their own action ("You owe Alex $25.00 → Pay on Venmo" or "Bea owes you $5.00"), with an expandable "Why?" breakdown. Host sees all settlements and their status.
Add an .ics download / "Add to Google Calendar" link on the party page.
Design: clean, warm, friendly; big tap targets; works great at 375px wide. Use daisyUI components and a custom theme.

Security & quality rules
Strong params everywhere; authorize every controller action (host vs. guest vs. stranger).
Tokens must be unguessable (has_secure_token); never expose one guest's access token to another.
No secrets in code — use Rails credentials / ENV.
Validate amounts (non-negative, sane max), Venmo usernames (format), and file uploads (images only, size limit).
Seed file (db/seeds.rb) with a demo host, a party, 4 guests, contributions and costs so I can click around immediately. Record any demo login credentials in the seed file / README, not in chat.
bin/rails test and bin/rails test:system must pass; run bin/rubocop and bin/brakeman and fix issues.
How to work
Start in plan mode. Read this whole brief, then propose a step-by-step implementation plan and wait for my approval before writing code.
Create a CLAUDE.md in the project capturing the stack, conventions, money rules, and security rules above so future sessions follow them.
Build in small vertical slices, committing after each with a clear message:
App skeleton, auth, Tailwind/daisyUI theme, layout
Events CRUD (host)
Invite link + guest RSVP + access-token sessions
Contribution board with live updates
Cost logging + receipts
FairShares + SettleUp services (test-first)
Close out party + Settlements + Venmo buttons + paid/confirmed
Calendar links, PWA, seeds, polish
Write tests alongside each slice; run the suite before each commit.
When done, give me the exact commands to run it locally (bin/setup, bin/dev) and a short summary of what's built and what's left.
Out of scope for the MVP
SMS/text invites, push notifications, native apps (Hotwire Native later), payment providers other than Venmo, in-app payments, recurring dinner clubs, dietary-preference tracking. Keep the code structured so these can be added later, but don't build them now.


---

# Working notes for this repo (maintained as the app is built)

### Commands

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

### Stack (do not deviate without asking)

- Rails 8, PostgreSQL, Importmap — **no Node build step**
- Hotwire: Turbo Drive / Frames / Streams + Stimulus. Live updates use `broadcasts_refreshes` + Turbo morphing, not hand-written stream templates.
- ERB views + ViewComponent (`app/components`) for reusable UI
- Tailwind CSS v4 + daisyUI 5. daisyUI is vendored as `app/assets/tailwind/daisyui*.js` and loaded with `@plugin`; the custom `tablemates` theme lives in `app/assets/tailwind/application.css`.
- Solid Queue / Solid Cache / Solid Cable, Active Storage
- Minitest, including system tests for key flows
- Rails 8 authentication generator for hosts (`Authentication` concern, `Current.user`)

### Domain model

- `User` — a host account. Guests never have accounts.
- `Event` — a party. `invite_token` is the shareable link secret. Status: `planning → closed → settled`.
- `Invitation` — one person at one event (the host has one too, so all split logic works on invitations). `access_token` is that guest's personal secret.
- `Contribution` — an item someone brings; `cost_cents`; `shared: false` means a gift, excluded from the split.
- `Settlement` — a fixed payment between two invitations, created when the host closes out the party.

### Money rules

- All money is **integer cents, USD**. Never use floats for money — not in models, services, helpers or views.
- Parse user-entered dollar amounts and format cents for display in one place only (`Money`).
- Fair shares use `divmod`; balances must always sum to exactly zero (asserted in `FairShares`).
- Venmo is the only payment provider. There is no Venmo API: build pre-filled links in `PaymentsHelper#venmo_pay_url` only. Do not add a payment-provider abstraction.

### Security rules

- Authorize **every** controller action: host (User session) vs. guest (Invitation access token) vs. stranger.
- Party-scoped controllers load records through the viewer's event (`PartyAccess` concern), never by bare id.
- Tokens come from `has_secure_token`. Never render one guest's `access_token` to anyone else (views, JSON, broadcasts, logs).
- Strong params everywhere (`params.expect`).
- Validate amounts (non-negative, sane max), Venmo usernames (`VenmoUsername` concern), and uploads (images only, size limit).
- No secrets in code — Rails credentials / ENV. Demo credentials live only in `db/seeds.rb` and the README.
- Any new guest-facing action needs a test proving a guest of another event, and a different guest of the same event, cannot use it.

### Conventions

- Mobile-first: design at 375px wide, big tap targets (`btn-lg`, `input-lg` for primary actions).
- Use daisyUI component classes and theme colours (`primary`, `base-200`, …) rather than raw palette colours.
- Small vertical slices; tests alongside each change.
- Work happens on the `mvp` branch; `main` is merged by the owner.

### Out of scope for the MVP

SMS invites, push notifications, native apps, payment providers other than Venmo, in-app payments, recurring dinner clubs, dietary-preference tracking.

---

# Build results (MVP built 2026-11-15)

All eight slices from the brief are built and committed on the `mvp` branch. `main` holds only the original brief until the owner merges.

### Status of checks (last run)

| Check | Result |
|---|---|
| `bin/rails test` | 181 tests, 0 failures |
| `bin/rails test:system` | 3 tests, 0 failures (headless Chrome, phone viewport; stable over 10 consecutive runs) |
| `bin/rubocop` | no offenses |
| `bin/brakeman` | 0 warnings; 1 documented false positive in `config/brakeman.ignore` (Google Calendar link href) |

### Commits on `mvp`

| Commit | Slice |
|---|---|
| `fa5d03b` | 1 — app skeleton, host auth, daisyUI theme, layout |
| `b51ff12` | 2 — events CRUD for hosts |
| `c007db5` | 3 — invite link, guest RSVP, access-token sessions |
| `e40af4b` | 4–5 — live contribution board, cost logging, receipts (one commit) |
| `71c6f2b` | 6 — FairShares and SettleUp services (test-first) |
| `75cc711` | 7 — close out, settlements, Venmo links, paid/confirmed |
| `9767c66` | 8 — calendar links, PWA, seeds, system tests, polish |

### Environment that was set up

- Ruby 3.4.12 via rbenv (pinned in `.ruby-version`), Rails 8.1.4.1.
- PostgreSQL 17 in Docker via `compose.yml` (`localhost:5432`). Docker Desktop must be running and signed in.
- daisyUI 5.8.1 vendored as `app/assets/tailwind/daisyui.js` and `daisyui-theme.js` — no Node.
- ViewComponent 4 added to the Gemfile.

### What was built

**Hosts**
- Sign-up (`RegistrationsController`), sign-in and password reset (Rails 8 authentication generator). `User` has `name` and optional `venmo_username`.
- Dashboard (`/`) listing the host's upcoming and past parties; strangers see a welcome page.
- Create / edit / delete a party (`EventsController`, scoped through `Current.user.hosted_events`) with title, date/time, location, description, cover image, and the two splitting options.

**Guests (no accounts)**
- `GET /i/:invite_token` — public invite page with details and RSVP form (name, optional email, Venmo username, yes/maybe/no).
- `GET /p/:access_token` — personal link. It stores the token in a signed, permanent, http-only cookie (keyed by event id, so one device can attend several parties) and redirects to `/parties/:id`.
- `PartyAccess` concern resolves the viewer's own `Invitation` from the host session or the guest cookie and 404s for anyone else. Every party-scoped controller uses it and loads records through `@event`.
- Guests can change their own RSVP and details; replies freeze after close-out, but a Venmo username can still be added.

**Party page (`/parties/:id`)**
- Details, the viewer's own RSVP card, invite link with copy button (host only), contribution board, settle-up summary, guest list with RSVP badges.
- Live updates: `Event` uses `broadcasts_refreshes`; invitations, contributions and settlements `touch` the event; the page subscribes with `turbo_stream_from` and morphs in place. Verified in two browser tabs.
- The Action Cable connection is open to guests; subscriptions are authorised by Turbo's signed stream names.

**Contribution board**
- Grouped by category (mains, sides, drinks, dessert, everything else) with a running shared total.
- Host lists needed items; guests tap "I'll bring it", add their own, hand an item back, or remove it.
- Cost entered in dollars and stored as integer cents (max $10,000); "It's a gift" excludes it from the split; optional receipt photo.
- Only the person bringing an item, or the host, can edit it. The board is frozen once the party is closed out.
- Receipts are streamed through `ReceiptsController` behind the party access check, not linked by public Active Storage URL.

**Settle-up**
- `app/services/fair_shares.rb` — divmod split, extra cents to the first attendees by id, balances asserted to sum to zero.
- `app/services/settle_up.rb` — exact-match pairing, then greedy largest-debtor-pays-largest-creditor; at most n−1 payments; returns `SettleUp::Payment`.
- Options: round to whole dollars (host absorbs the difference) and forgive payments under a threshold.
- Live estimate while planning. "Close out party" (host) writes fixed `Settlement` records; the host can reopen until any settlement is marked paid. A party with nothing owed goes straight to `settled`.
- Settle-up screen: each person sees only their own payments plus an expandable "Why?" breakdown; the host also sees everyone's payments and their status.

**Venmo**
- `PaymentsHelper#venmo_pay_url` builds the pre-filled link; `venmo_profile_url` powers "Check it's …"; note text is "🍝 <title> – <Mon D>".
- Usernames are normalised (whitespace and leading `@` stripped) and format-validated in the `VenmoUsername` concern.
- Payer taps "I paid" (`paid_at`), recipient taps "Got it" (`confirmed_at`); when all are confirmed the party becomes `settled`.
- If the creditor has no Venmo username the settlement is blocked: the payer sees a notice, the creditor a prompt to add one.

**Other**
- `.ics` download and "Add to Google Calendar" link (`EventCalendar`, `CalendarsController`).
- PWA: manifest, app icon, network-only service worker registered from `application.js`.
- Original "tablemates" daisyUI theme (cream / terracotta / olive / saffron), two-plates logo, serif display headings, mobile-first single column.
- ViewComponents in `app/components`: logo, flash, form errors, avatar, card, status badge, RSVP badge, event card, copy button, contribution board and row, settlement line, why.
- Seeds: demo host, a party in planning (4 guests, costs, a gift, unclaimed items) and a past party part-way through settling up. Demo credentials are in `db/seeds.rb` and the README only.

### Routes at a glance

| Path | Who | Purpose |
|---|---|---|
| `/` | anyone | welcome page, or the host's dashboard |
| `/registration/new`, `/session/new`, `/passwords/new` | anyone | host sign-up, sign-in, password reset |
| `/events/new`, `/events/:id/edit` | host | create / edit / delete a party |
| `/i/:invite_token` | anyone with the link | invite page and RSVP |
| `/p/:access_token` | that guest | personal link → remembers the guest, redirects to the party |
| `/parties/:id` | host + guests | party page |
| `/parties/:id/rsvp/edit` | host + guests | own RSVP and details |
| `/parties/:id/contributions/…` | host + guests | add, edit, claim, unclaim, remove; `/receipt` to view a photo |
| `/parties/:id/settle_up` | host + guests | estimate or settlements |
| `/parties/:id/close_out` | host | POST closes out, DELETE reopens |
| `/parties/:id/settlements/:id/pay`, `/confirm` | payer / recipient | "I paid" / "Got it" |
| `/parties/:id/calendar.ics` | host + guests | calendar download |

### Decisions that differ from, or go beyond, the brief

- **Personal link redirects.** `/p/:access_token` sets the cookie and redirects to `/parties/:id` instead of rendering the party itself, so the token doesn't stay in the address bar, history or screenshots.
- **Rounding is applied to balances, not payments.** Each non-host balance is rounded to the nearest dollar and the host's balance takes the slack. Every payment is then a whole dollar and the host really does absorb the difference.
- **Venmo amount is built from integer cents** (`Money.decimal`) rather than `amount_cents / 100.0`, to keep the no-floats rule. Same output.
- **Forms live on their own pages** (add/edit item, edit RSVP) so a live refresh can't disturb a form mid-typing.
- **Non-attending payers** — someone who paid for a shared item but isn't marked as going has no share and is reimbursed in full.
- **Unclaimed items can't carry a cost**, and an item with a logged cost can't be handed back until the cost is cleared.
- **Uploads are sniffed from their bytes** (`ImageAttachmentValidator`); the filename and the browser's claimed content type are not trusted. Cover ≤ 5 MB, receipt ≤ 10 MB; PNG, JPEG, WebP, GIF.
- **A party is capped at 150 invitations**, and RSVP / personal-link endpoints are rate-limited.
- **Project context lives in this file.** The repo's `CLAUDE.md` is only a pointer here.

### Things to know

- **Parallel test crash on macOS.** The unit suite hung once and segfaulted once (libpq GSS negotiation in forked workers). `gssencmode: disable` was added to the local database config; it passed every run afterwards, but the crash was intermittent so that is not proof.
- **System-test flakiness, fixed.** Chrome's password-manager and autofill popups were swallowing clicks; they are disabled in `test/application_system_test_case.rb`.
- **Time zone.** Party times are entered and shown in one app-wide zone, default US Eastern (`APP_TIME_ZONE`).
- **Images are served at original size** — libvips isn't installed, so no variants are generated.
- **Adding a new top-level directory under `app/`** (as happened with `app/services` and `app/validators`) needs a dev-server restart.
- **Re-running `bin/rails db:seed`** rebuilds the demo parties, so previously printed guest links stop working.

### Not built yet

- The host can't remove a guest.
- Nothing is emailed to guests (the optional email is only stored); password-reset mail has no delivery configured.
- A payer can't undo "I paid".
- Per-party or per-viewer time zones.
- Image resizing / thumbnails.
- Production deployment: the Kamal config and production settings are the generated defaults.
- Everything listed as out of scope in the brief (SMS invites, push notifications, native apps, other payment providers, in-app payments, recurring clubs, dietary tracking).
