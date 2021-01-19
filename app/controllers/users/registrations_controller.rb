# frozen_string_literal: true

# Users::RegistrationsController: override the default Devise registrations controller: we want
# to allow users to change their password (it's required on first login) but not allow
# them to change their email address.
class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_account_update_params, only: [:update]

  # PUT /resource
  # rubocop:disable Lint/UselessMethodDefinition
  def update
    super
  end
  # rubocop:enable Lint/UselessMethodDefinition

  def password_expired
    redirect_to edit_user_registration_url && return
  end

  protected

  # Remove email from the list of allowed parameters
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, except: [:email])
  end

  # Once the user has updated their password then don't require it to be changed
  def account_update_params
    super.merge(force_password_change: false)
  end
end
