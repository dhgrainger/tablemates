class DashboardController < ApplicationController
  allow_unauthenticated_access

  def show
    return render :welcome unless authenticated?

    @upcoming = Current.user.hosted_events.upcoming.with_attached_cover_image
    @past = Current.user.hosted_events.past.with_attached_cover_image
  end
end
