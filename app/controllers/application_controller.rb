class ApplicationController < ActionController::Base
  before_action :new_users_must_change_password
  def new_users_must_change_password
    if current_user && current_user.force_password_change
      # Redirect unless we're already at the change password page or logging out
      unless request.url == edit_user_registration_url || request.url == user_registration_url || request.url == destroy_user_session_url
        redirect_to edit_user_registration_url
      end
    end
  end
end
