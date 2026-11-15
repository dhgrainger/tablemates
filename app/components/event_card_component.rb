class EventCardComponent < ViewComponent::Base
  with_collection_parameter :event

  def initialize(event:)
    @event = event
  end

  erb_template <<~ERB
    <%= link_to helpers.party_path(@event), class: "card card-side border border-base-300 bg-base-100 transition active:scale-[0.99]" do %>
      <% if helpers.saved_attachment?(@event.cover_image) %>
        <figure class="w-24 shrink-0"><%= image_tag @event.cover_image, alt: "", class: "h-full w-full object-cover" %></figure>
      <% end %>
      <div class="card-body gap-1 p-4">
        <div class="flex items-start justify-between gap-2">
          <h3 class="font-display text-lg font-semibold leading-snug"><%= @event.title %></h3>
          <%= render StatusBadgeComponent.new(status: @event.status) %>
        </div>
        <p class="text-sm opacity-80"><%= helpers.event_when(@event) %></p>
        <% if @event.location.present? %><p class="text-sm opacity-70"><%= @event.location %></p><% end %>
      </div>
    <% end %>
  ERB
end
