# frozen_string_literal: true

# AdminController: for administration actions
class AdminController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to(root_url) && return unless current_user.has_role? :admin
  end

  def create_user
    permitted_params = params[:admin].permit(:email, :jurisdiction, :role_title)
    roles = Role.pluck(:name)
    email = permitted_params[:email]
    raise 'EMAIL must be provided' unless email

    password = SecureRandom.base58(10) # About 58 bits of entropy
    role = permitted_params[:role_title]
    raise "ROLE must be provided and one of #{roles}" unless role && roles.include?(role)

    jurisdictions = Jurisdiction.pluck(:id)
    jurisdiction = permitted_params[:jurisdiction]
    raise "JURISDICTION must be provided and one of #{jurisdictions}" unless jurisdiction && jurisdictions.include?(jurisdiction)

    user = User.create!(
      email: email,
      password: password,
      jurisdiction: Jurisdiction.find_by_id(jurisdiction),
      force_password_change: true # Require user to change password on first login
    )
    user.add_role role
    user.save!
    UserMailer.welcome_email(user, password).deliver_later
  end
end
