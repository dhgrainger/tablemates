class CopyButtonComponent < ViewComponent::Base
  def initialize(text:, label:, style: "btn-sm")
    @text = text
    @label = label
    @style = style
  end

  erb_template <<~ERB
    <button type="button" class="btn <%= @style %>"
            data-controller="clipboard" data-action="clipboard#copy"
            data-clipboard-text-value="<%= @text %>" data-clipboard-label-value="<%= @label %>">
      <%= @label %>
    </button>
  ERB
end
