# frozen_string_literal: true

# ApplicationController: base controller, handles password changes
class ApplicationController < ActionController::Base
  before_action :user_must_change_password
  before_action :ensure_authy_enabled
  before_action :set_last_activity_at, if:
    proc { user_signed_in? && (current_user.last_activity_at.nil? || current_user.last_activity_at < 15.minutes.ago) }
  protect_from_forgery prepend: true
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def user_must_change_password
    return unless current_user&.force_password_change

    # First login (and first password change) must occur within three days
    current_user.lock_access! if current_user.password_changed_at < 3.days.ago && current_user&.force_password_change

    return if request.url == edit_user_registration_url || request.url == user_registration_url || request.url == destroy_user_session_url

    return unless current_user&.force_password_change

    redirect_to edit_user_registration_url
  end

  def ensure_authy_enabled
    return if params[:controller] == 'devise_authy' || params[:controller] == 'users/registrations' ||
              (params[:controller] == 'devise/sessions' && params[:action] == 'destroy')

    return unless current_user && !current_user.authy_enabled? && current_user.authy_enforced

    redirect_to user_enable_authy_url
  end

  private

  def record_not_found
    redirect_to '/errors#not_found'
  end

  # While the user is making requests, last_activity_at timestamp is updated every 15 minutes
  # Use touch to skip model validations and reduce overhead
  def set_last_activity_at
    current_user.touch(:last_activity_at) # rubocop:disable Rails/SkipsModelValidations
  end
end
