class StatusBadgeComponent < ViewComponent::Base
  STYLES = {
    "planning" => [ "Planning", "badge-accent" ],
    "closed" => [ "Settling up", "badge-primary" ],
    "settled" => [ "All settled", "badge-success" ]
  }.freeze

  def initialize(status:)
    @label, @style = STYLES.fetch(status.to_s)
  end

  erb_template <<~ERB
    <span class="badge <%= @style %> badge-sm font-medium"><%= @label %></span>
  ERB
end
