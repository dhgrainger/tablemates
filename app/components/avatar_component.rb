# Initials in a coloured circle. The colour is derived from the name so a
# person keeps the same colour everywhere.
class AvatarComponent < ViewComponent::Base
  PALETTE = %w[
    bg-primary text-primary-content
    bg-secondary text-secondary-content
    bg-accent text-accent-content
    bg-neutral text-neutral-content
  ].each_slice(2).map { |pair| pair.join(" ") }.freeze

  SIZES = { sm: "w-8 text-xs", md: "w-10 text-sm", lg: "w-14 text-lg" }.freeze

  def initialize(name:, size: :md)
    @name = name.to_s
    @size = size
  end

  def initials
    @name.split.first(2).map { |word| word[0] }.join.upcase.presence || "?"
  end

  def color_classes
    PALETTE[@name.sum % PALETTE.size]
  end

  erb_template <<~ERB
    <div class="avatar avatar-placeholder" title="<%= @name %>">
      <div class="<%= SIZES.fetch(@size) %> <%= color_classes %> rounded-full font-semibold">
        <span><%= initials %></span>
      </div>
    </div>
  ERB
end
