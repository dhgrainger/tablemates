class ContributionBoardComponent < ViewComponent::Base
  def initialize(event:, viewer:)
    @event = event
    @viewer = viewer
    @contributions = event.contributions.includes(:invitation).with_attached_receipt.order(:id).to_a
  end

  def groups
    grouped = @contributions.group_by(&:category)
    Contribution::CATEGORIES.filter_map { |key, label| [ label, grouped[key] ] if grouped[key] }
  end

  def total_cents
    @contributions.select { |c| c.shared? && c.claimed? }.sum(&:cost_cents)
  end

  def still_needed
    @contributions.count { |c| !c.claimed? }
  end
end
