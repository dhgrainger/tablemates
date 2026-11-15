# The contribution board. Anyone at the party can add an item or claim an
# unclaimed one; changing an item is limited to whoever is bringing it and
# the host. The board is frozen once the party is closed out.
class ContributionsController < ApplicationController
  include PartyAccess

  before_action :require_planning
  before_action :set_contribution, only: %i[ edit update destroy claim unclaim ]
  before_action :require_editor, only: %i[ edit update destroy unclaim ]

  def new
    @contribution = @event.contributions.new(invitation: current_invitation)
  end

  def create
    @contribution = @event.contributions.new(invitation: listing_as_needed? ? nil : current_invitation)
    @contribution.assign_attributes(contribution_params)

    if @contribution.save
      redirect_to party_path(@event, anchor: "board"), notice: "Added to the board."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @contribution.assign_attributes(contribution_params)

    if @contribution.save
      @contribution.receipt.purge if remove_receipt?
      redirect_to party_path(@event, anchor: "board"), notice: "Saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contribution.destroy!
    redirect_to party_path(@event, anchor: "board"), notice: "Removed from the board.", status: :see_other
  end

  def claim
    claimed = @contribution.with_lock do
      @contribution.update!(invitation: current_invitation) unless @contribution.claimed?
    end

    if claimed
      redirect_to party_path(@event, anchor: "board"), notice: "It's yours — thanks!"
    else
      redirect_to party_path(@event, anchor: "board"), alert: "Someone else is already bringing that."
    end
  end

  def unclaim
    if @contribution.cost_cents.zero?
      @contribution.update!(invitation: nil)
      redirect_to party_path(@event, anchor: "board"), notice: "Back on the list for someone else."
    else
      redirect_to edit_party_contribution_path(@event, @contribution), alert: "Clear the cost first."
    end
  end

  private
    def set_contribution
      @contribution = @event.contributions.find(params[:id])
    end

    def require_editor
      raise ActiveRecord::RecordNotFound unless @contribution.editable_by?(current_invitation)
    end

    # Only the host can list something as needed without bringing it themselves.
    def listing_as_needed?
      hosting? && params.dig(:contribution, :mine) != "1"
    end

    def contribution_params
      permitted = params.expect(contribution: [ :name, :category, :cost, :gift, :receipt, :remove_receipt, :mine ])
      permitted = permitted.except(:remove_receipt, :mine) # handled by the controller, not model attributes
      permitted = permitted.except(:cost, :gift, :receipt) unless @contribution.claimed?
      permitted
    end

    def remove_receipt?
      params.dig(:contribution, :remove_receipt) == "1" && params.dig(:contribution, :receipt).blank?
    end
end
