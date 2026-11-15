class ContributionRowComponent < ViewComponent::Base
  def initialize(contribution:, viewer:, event:)
    @contribution = contribution
    @viewer = viewer
    @event = event
  end

  def mine?
    @contribution.invitation_id == @viewer.id
  end

  def editable?
    @event.planning? && @contribution.editable_by?(@viewer)
  end

  def claimable?
    @event.planning? && !@contribution.claimed?
  end

  def needs_cost?
    editable? && mine? && @contribution.cost_cents.zero?
  end
end
