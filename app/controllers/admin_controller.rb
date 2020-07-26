# frozen_string_literal: true

# AdminController: for administration actions
class AdminController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to(root_url) && return unless current_user.has_role? :admin
  end

  def users
    permitted_params = params.permit(:search, :entries, :page, :order_by, :sort_direction)

    # Validate search param
    search = permitted_params[:search]

    # Validate pagination params
    entries = permitted_params[:entries]&.to_i || 25
    page = permitted_params[:page]&.to_i || 0
    return head :bad_request unless entries >= 0 && page >= 0

    # Validate sort params
    order_by = permitted_params[:order_by]
    return head :bad_request unless order_by.nil? || order_by.blank? || %w[id email jurisdiction role].include?(order_by)

    sort_direction = permitted_params[:sort_direction]
    return head :bad_request unless sort_direction.nil? || sort_direction.blank? || %w[asc desc].include?(sort_direction)
    return head :bad_request unless (!order_by.blank? && !sort_direction.blank?) || (order_by.blank? && sort_direction.blank?)

    # Get all users within the current user's jurisdiction
    users = User.all.where(jurisdiction_id: current_user.jurisdiction.subtree_ids)

    # Filter by search text
    users = filter(users, search)

    # Sort
    users = sort(users, order_by, sort_direction)

    # Paginate
    users = users.paginate(per_page: entries, page: page + 1)

    # Get total count
    total = users.total_entries

    linelist = []
    users.each do |user|
      details = {
        id: user.id,
        email: user.email,
        jurisdictionPath: user.jurisdiction_path.join(', ') || [],
        role: user.roles[0].name.split('_').map(&:capitalize).join(' ') || '',
        isLocked: user.locked_at.nil? || false,
        isAPIEnabled: user[:api_enabled] || false,
        is2FAEnabled: user.authy_id.nil? || false,
      }

      linelist << details
    end

    render json: { linelist: linelist, total: total }
  end

  def sort(users, order_by, sort_direction)
    return users if order_by.nil? || order_by.empty? || sort_direction.nil? || sort_direction.blank?

    # Satisfy brakeman with additional sanitation logic
    dir = direction == 'asc' ? 'asc' : 'desc'

    case order_by
    when 'id'
      users = users.order(id: dir)
    when 'email'
      users = users.order(email: dir)
    when 'jurisdiction'
      users = users.order(jurisdiction_path: dir)
    when 'role'
      users = users.order(role: dir)
    end

    users
  end

  def filter(users, search)
    return users if search.nil? || search.blank?

    users.where('id like ?', "#{search}%").or(
      users.where('email like ?', "#{search}%"))
  end

  def create_user
    permitted_params = params[:admin].permit(:email, :jurisdiction, :role_title)
    roles = Role.pluck(:name)
    email = permitted_params[:email].strip
    raise 'EMAIL must be provided' unless email

    address = ValidEmail2::Address.new(email)
    raise 'EMAIL is invalid' unless address.valid? && !address.disposable?

    password = User.rand_gen
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
    user.authy_enabled = false
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
    password = User.rand_gen
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
      UserMailer.admin_message_email(user, comment).deliver_later
    end
  end

  def enable_api
    redirect_to(root_url) && return unless current_user.has_role? :admin

    permitted_params = params[:admin].permit(:email)
    email = permitted_params[:email]
    user = User.find_by(email: email)
    cur_jur = current_user.jurisdiction
    redirect_to(root_url) && return unless (cur_jur.descendant_ids + [cur_jur.id]).include? user.jurisdiction.id

    user.update!(api_enabled: true)
  end

  def disable_api
    redirect_to(root_url) && return unless current_user.has_role? :admin

    permitted_params = params[:admin].permit(:email)
    email = permitted_params[:email]
    user = User.find_by(email: email)
    cur_jur = current_user.jurisdiction
    redirect_to(root_url) && return unless (cur_jur.descendant_ids + [cur_jur.id]).include? user.jurisdiction.id

    user.update!(api_enabled: false)
  end
end
