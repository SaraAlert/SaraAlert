# frozen_string_literal: true

# ApplicationController: base controller, handles password changes
class ApplicationController < ActionController::Base
  before_action :user_must_change_password
  protect_from_forgery prepend: true

  def user_must_change_password
    return unless current_user&.force_password_change

    return if request.url == edit_user_registration_url || request.url == user_registration_url || request.url == destroy_user_session_url

    redirect_to edit_user_registration_url
  end
end
