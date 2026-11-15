class DashboardController < ApplicationController
  allow_unauthenticated_access

  def show
    render :welcome unless authenticated?
  end
end
