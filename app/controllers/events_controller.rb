# Host-only management of parties. Everything is scoped through the signed-in
# host's own events, so another host's event is simply not found.
class EventsController < ApplicationController
  before_action :set_event, only: %i[ edit update destroy ]

  def new
    @event = Current.user.hosted_events.new(starts_at: 1.week.from_now.change(hour: 19))
  end

  def create
    @event = Current.user.hosted_events.new(event_params)

    if @event.save
      redirect_to party_path(@event), notice: "Party created. Share the invite link to get RSVPs."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to party_path(@event), notice: "Party updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy!
    redirect_to root_path, notice: "Party deleted.", status: :see_other
  end

  private
    def set_event
      @event = Current.user.hosted_events.find(params[:id])
    end

    def event_params
      params.expect(event: [ :title, :starts_at, :location, :description, :cover_image,
        :round_to_whole_dollars, :forgive_under ])
    end
end
