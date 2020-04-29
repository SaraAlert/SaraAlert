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
    user.add_role role.to_sym
    user.save!
    UserMailer.welcome_email(user, password).deliver_later
  end

  def edit_user
    redirect_to(root_url) && return unless current_user.has_role? :admin

    permitted_params = params[:admin].permit(:email, :jurisdiction, :role_title)
    roles = Role.pluck(:name)
    email = permitted_params[:email]
    raise 'EMAIL must be provided' unless email

    role = permitted_params[:role_title]
    raise "ROLE must be provided and one of #{roles}" unless role && roles.include?(role)

    jurisdictions = Jurisdiction.pluck(:id)
    jurisdiction = permitted_params[:jurisdiction]
    puts jurisdiction.to_s + '   ------ '
    raise "JURISDICTION must be provided and one of #{jurisdictions}" unless jurisdiction && jurisdictions.include?(jurisdiction)

    user = User.find_by(email: email)
    cur_jur = current_user.jurisdiction
    redirect_to(root_url) && return unless (cur_jur.descendant_ids + [cur_jur.id]).include? user.jurisdiction.id
    raise 'USER not found' unless user

    user.jurisdiction = Jurisdiction.find_by_id(jurisdiction)
    user.roles = []
    user.add_role role.to_sym
    user.save!
  end

  def lock_user
    redirect_to(root_url) && return unless current_user.has_role? :admin

    permitted_params = params[:admin].permit(:email)
    email = permitted_params[:email]
    user = User.find_by(email: email)
    cur_jur = current_user.jurisdiction
    redirect_to(root_url) && return unless (cur_jur.descendant_ids + [cur_jur.id]).include? user.jurisdiction.id

    user.lock_access!
  end

  def reset_2fa
    redirect_to(root_url) && return unless current_user.has_role? :admin

    permitted_params = params[:admin].permit(:email)
    email = permitted_params[:email]
    user = User.find_by(email: email)
    cur_jur = current_user.jurisdiction
    redirect_to(root_url) && return unless (cur_jur.descendant_ids + [cur_jur.id]).include? user.jurisdiction.id

    user.authy_id = nil
    user.save!
  end

  def unlock_user
    redirect_to(root_url) && return unless current_user.has_role? :admin

    permitted_params = params[:admin].permit(:email)
    email = permitted_params[:email]
    user = User.find_by(email: email)
    cur_jur = current_user.jurisdiction
    redirect_to(root_url) && return unless (cur_jur.descendant_ids + [cur_jur.id]).include? user.jurisdiction.id

    user.unlock_access!
  end

  def reset_password
    redirect_to(root_url) && return unless current_user.has_role? :admin

    permitted_params = params[:admin].permit(:email)
    email = permitted_params[:email]
    user = User.find_by(email: email)
    cur_jur = current_user.jurisdiction
    redirect_to(root_url) && return unless (cur_jur.descendant_ids + [cur_jur.id]).include? user.jurisdiction.id

    user.unlock_access!
    password = SecureRandom.base58(10)
    user.password = password
    user.force_password_change = true
    user.save!
    UserMailer.welcome_email(user, password).deliver_later
  end

  def send_email
    redirect_to(root_url) && return unless current_user.can_send_admin_emails?

    permitted_params = params.permit(:comment)
    comment = permitted_params[:comment]

    return if comment.blank?

    User.all.find_each(batch_size: 5) do |user|
      UserMailer.admin_message_email(user, comment).deliver_now
    end
  end
end
