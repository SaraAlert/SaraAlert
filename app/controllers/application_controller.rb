# frozen_string_literal: true

# ApplicationController: base controller, handles password changes
class ApplicationController < ActionController::Base
  before_action :user_must_change_password
  protect_from_forgery prepend: true

  def user_must_change_password
    return unless current_user&.force_password_change || (current_user && !current_user&.authy_enabled)

    # First login (and first password change) must occur within three days
    current_user.lock_access! if current_user.password_changed_at < 3.days.ago && current_user&.force_password_change

    if request.url == edit_user_registration_url || request.url == user_registration_url || request.url == destroy_user_session_url
      return
    end

    if current_user&.force_password_change
      redirect_to edit_user_registration_url
      return
    end

    if !current_user&.devise_modules.include?(:authy_authenticatable) || request.url == user_enable_authy_url || request.url == user_verify_authy_url ||
       request.url == user_verify_authy_installation_url || request.url == user_request_sms_url || request.url == user_request_phone_call_url
      return
    end

    redirect_to user_enable_authy_url unless current_user&.authy_enabled || !current_user&.authy_id.nil?
    redirect_to user_verify_authy_installation_url unless current_user&.authy_enabled || current_user&.authy_id.nil?
  end
end
