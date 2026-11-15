class PartiesController < ApplicationController
  include PartyAccess

  def show
    @invitations = @event.invitations.order(:id)
  end
end
