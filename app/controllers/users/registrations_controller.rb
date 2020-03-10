# frozen_string_literal: true

# Users: users controller
class Users
  # RegistrationsController: override the default Devise registrations controller: we want
  # to allow users to change their password (it's required on first login) but not allow
  # them to change their email address.
  class RegistrationsController < Devise::RegistrationsController
    before_action :configure_account_update_params, only: [:update]

    # PUT /resource
    def update
      super
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
end
