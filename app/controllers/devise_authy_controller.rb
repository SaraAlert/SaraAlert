class DeviseAuthyController < Devise::DeviseAuthyController
    before_action :verify_enforcement

    def verify_enforcement
      return unless current_user
      redirect_to root_url unless current_user&.authy_enforced
    end
  end