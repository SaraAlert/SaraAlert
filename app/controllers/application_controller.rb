# frozen_string_literal: true

# ApplicationController: base controller, handles password changes
class ApplicationController < ActionController::Base
  before_action :user_must_change_password
  before_action :ensure_authy_enabled
  protect_from_forgery prepend: true

  def user_must_change_password
    return unless current_user&.force_password_change

    # First login (and first password change) must occur within three days
    current_user.lock_access! if current_user.password_changed_at < 3.days.ago && current_user&.force_password_change

    return if request.url == edit_user_registration_url || request.url == user_registration_url || request.url == destroy_user_session_url

    if current_user&.force_password_change
      redirect_to edit_user_registration_url
      return
    end
  end

  def ensure_authy_enabled
    return if params[:controller] == "devise_authy" || params[:controller] == "users/registrations" || (params[:controller] == "devise/sessions" && params[:action] == 'destroy')
    if current_user and !current_user.authy_enabled? and current_user.authy_enforced
      redirect_to user_enable_authy_url
    end
  end
end
