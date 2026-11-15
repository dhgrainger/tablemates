class FormErrorsComponent < ViewComponent::Base
  def initialize(record:)
    @record = record
  end

  def render?
    @record.errors.any?
  end

  erb_template <<~ERB
    <div role="alert" class="alert alert-soft alert-error mb-4 items-start" id="form_errors">
      <ul class="list-inside list-disc text-sm">
        <% @record.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  ERB
end
