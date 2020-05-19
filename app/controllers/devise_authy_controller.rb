class DeviseAuthyController < Devise::DeviseAuthyController
    before_action :check_enforcement

    def check_enforcement
      return unless current_user

      redirect_to root_url unless current_user&.authy_enforced
    end
  end