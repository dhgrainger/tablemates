class FlashComponent < ViewComponent::Base
  STYLES = { "notice" => "alert-success", "alert" => "alert-error" }.freeze

  def initialize(flash:)
    @messages = flash.to_h.slice(*STYLES.keys).select { |_, message| message.present? }
  end

  def render?
    @messages.any?
  end

  erb_template <<~ERB
    <div class="mb-4 flex flex-col gap-2" id="flash">
      <% @messages.each do |type, message| %>
        <div role="alert" class="alert alert-soft <%= STYLES.fetch(type) %>" id="<%= type %>"><%= message %></div>
      <% end %>
    </div>
  ERB
end
