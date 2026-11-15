# The Tablemates mark: two place settings sharing one table.
class LogoComponent < ViewComponent::Base
  def initialize(size: 32)
    @size = size
  end

  erb_template <<~ERB
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="<%= @size %>" height="<%= @size %>" aria-hidden="true">
      <rect width="64" height="64" rx="18" class="fill-primary" />
      <circle cx="25" cy="32" r="13" fill="none" stroke-width="4" class="stroke-primary-content" />
      <circle cx="39" cy="32" r="13" fill="none" stroke-width="4" class="stroke-accent" />
    </svg>
  ERB
end
