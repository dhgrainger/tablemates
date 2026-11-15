# Receipt photos are streamed through the party's own access check rather
# than linked by a public Active Storage URL.
class ReceiptsController < ApplicationController
  include PartyAccess
  include ActiveStorage::Streaming

  def show
    contribution = @event.contributions.find(params[:contribution_id])
    raise ActiveRecord::RecordNotFound unless contribution.receipt.attached?

    response.headers["Cache-Control"] = "private, max-age=300"
    send_blob_stream contribution.receipt.blob, disposition: :inline
  end
end
