
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
