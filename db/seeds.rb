# Demo data so you can click around straight away: bin/rails db:seed
#
# Demo host login (local development only — never use in production):
#   email:    demo@tablemates.test
#   password: tablemates-demo   (override with DEMO_PASSWORD)
#
# Guests have no accounts. Their personal links are printed when this runs.
# Safe to run more than once: it rebuilds the demo host's parties.

abort "Seeds are demo data for development only." if Rails.env.production?

demo_password = ENV.fetch("DEMO_PASSWORD", "tablemates-demo")

host = User.find_or_initialize_by(email_address: "demo@tablemates.test")
host.update!(name: "Alex Rivera", password: demo_password, venmo_username: "alex-rivera-demo")
host.hosted_events.destroy_all

# --- An upcoming party, still being planned --------------------------------
dinner = host.hosted_events.create!(
  title: "Pasta Night at Alex's",
  starts_at: 6.days.from_now.change(hour: 19),
  location: "12 Orchard Lane, Apt 3",
  description: "Fresh pasta, good wine, bad karaoke.\nClaim something from the board or add your own."
)
alex = dinner.host_invitation
bea = dinner.invitations.create!(guest_name: "Bea Baker", email: "bea@example.com", rsvp_status: "yes", venmo_username: "bea-baker-demo")
cal = dinner.invitations.create!(guest_name: "Cal Cook", rsvp_status: "yes", venmo_username: "cal-cook-demo")
dee = dinner.invitations.create!(guest_name: "Dee Diner", rsvp_status: "yes")
eli = dinner.invitations.create!(guest_name: "Eli Eats", rsvp_status: "maybe", venmo_username: "eli-eats-demo")

dinner.contributions.create!(name: "Fresh pasta and ragù", category: "mains", invitation: alex, cost_cents: 64_50)
dinner.contributions.create!(name: "Two bottles of red", category: "drinks", invitation: bea, cost_cents: 38_00)
dinner.contributions.create!(name: "Tiramisu", category: "dessert", invitation: cal, cost_cents: 22_75)
dinner.contributions.create!(name: "Garlic bread", category: "sides", invitation: dee)
dinner.contributions.create!(name: "Flowers for the table", category: "other", invitation: bea, cost_cents: 15_00, shared: false)
dinner.contributions.create!(name: "Green salad", category: "sides")
dinner.contributions.create!(name: "Sparkling water", category: "drinks")

# --- A past party, closed out and part-way through settling up --------------
brunch = host.hosted_events.create!(
  title: "Sunday Brunch",
  starts_at: 2.weeks.ago.change(hour: 11),
  location: "Alex's place",
  description: "Pancakes and too much coffee."
)
b_alex = brunch.host_invitation
b_bea = brunch.invitations.create!(guest_name: "Bea Baker", rsvp_status: "yes", venmo_username: "bea-baker-demo")
b_cal = brunch.invitations.create!(guest_name: "Cal Cook", rsvp_status: "yes", venmo_username: "cal-cook-demo")
b_dee = brunch.invitations.create!(guest_name: "Dee Diner", rsvp_status: "yes")

brunch.contributions.create!(name: "Pancakes, eggs and bacon", category: "mains", invitation: b_alex, cost_cents: 52_40)
brunch.contributions.create!(name: "Coffee and oat milk", category: "drinks", invitation: b_bea, cost_cents: 18_60)
brunch.contributions.create!(name: "Fruit salad", category: "sides", invitation: b_cal, cost_cents: 9_00)
brunch.close_out!
brunch.settlements.where(from_invitation: b_cal).each(&:mark_paid!)

guest_link = ->(invitation) { Rails.application.routes.url_helpers.guest_access_path(invitation.access_token) }

puts <<~SUMMARY

  Seeded Tablemates demo data.

  Host:   sign in as demo@tablemates.test (password is in db/seeds.rb)
  Invite: /i/#{dinner.invite_token}

  Guest personal links for "#{dinner.title}" (open in a private window):
  #{[ bea, cal, dee, eli ].map { |guest| "  #{guest.guest_name.ljust(10)} #{guest_link.(guest)}" }.join("\n")}

  Guest personal links for "#{brunch.title}" (closed out, settling up):
  #{[ b_bea, b_cal, b_dee ].map { |guest| "  #{guest.guest_name.ljust(10)} #{guest_link.(guest)}" }.join("\n")}

SUMMARY
