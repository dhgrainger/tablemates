class RsvpBadgeComponent < ViewComponent::Base
  STYLES = {
    "yes" => [ "Going", "badge-success" ],
    "maybe" => [ "Maybe", "badge-warning" ],
    "no" => [ "Can't make it", "badge-ghost" ],
    "pending" => [ "No reply yet", "badge-ghost" ]
  }.freeze

  def initialize(status:)
    @label, @style = STYLES.fetch(status.to_s)
  end

  erb_template <<~ERB
    <span class="badge <%= @style %> badge-sm whitespace-nowrap font-medium"><%= @label %></span>
  ERB
end
