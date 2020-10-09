# frozen_string_literal: true

# AdminController: for administration actions
class AdminController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to(root_url) && return unless current_user.has_role? :admin
  end

  # Retrieve users for the admin user table.
  def users
    redirect_to(root_url) && return unless current_user.has_role? :admin

    permitted_params = params.permit(:search, :entries, :page, :orderBy, :sortDirection)

    # Validate search param
    search = permitted_params[:search]

    # Validate pagination params
    entries = permitted_params[:entries]&.to_i || 25
    page = permitted_params[:page]&.to_i || 0
    return head :bad_request unless entries >= 0 && page >= 0

    # Validate sort params
    order_by = permitted_params[:orderBy]
    return head :bad_request unless order_by.nil? || order_by.blank? || %w[id email jurisdiction_path num_failed_logins].include?(order_by)

    sort_direction = permitted_params[:sortDirection]
    return head :bad_request unless sort_direction.nil? || sort_direction.blank? || %w[asc desc].include?(sort_direction)
    return head :bad_request unless (!order_by.blank? && !sort_direction.blank?) || (order_by.blank? && sort_direction.blank?)

    # Get all users within the current user's jurisdiction
    users = User.where(jurisdiction_id: current_user.jurisdiction.subtree_ids).joins(:jurisdiction).select(
      'users.id, users.email, users.api_enabled, users.locked_at, users.authy_id, users.failed_attempts, jurisdictions.path'
    )

    # Filter by search text
    users = filter(users, search)

    # Sort
    users = sort(users, order_by, sort_direction)

    # Paginate
    users = users.paginate(per_page: entries, page: page + 1)

    # Get total count
    total = users.total_entries

    user_rows = []
    users.each do |user|
      details = {
        id: user.id,
        email: user.email,
        jurisdiction_path: user.path || '',
        role_title: user.roles[0].name.split('_').map(&:capitalize).join(' ') || '',
        is_locked: !user.locked_at.nil? || false,
        is_api_enabled: user[:api_enabled] || false,
        is_2fa_enabled: !user.authy_id.nil? || false,
        num_failed_logins: user.failed_attempts
      }

      user_rows << details
    end

    render json: { user_rows: user_rows, total: total }
  end

  # Sort users by a given field either in ascending or descending order.
  def sort(users, order_by, sort_direction)
    return users if order_by.nil? || order_by.empty? || sort_direction.nil? || sort_direction.blank?

    # Satisfy brakeman with additional sanitation logic
    dir = sort_direction == 'asc' ? 'asc' : 'desc'

    case order_by
    when 'id'
      users = users.order(id: dir)
    when 'email'
      users = users.order(email: dir)
    when 'jurisdiction_path'
      users = users.order(path: dir)
    when 'num_failed_logins'
      users = users.order(failed_attempts: dir)
    end

    users
  end

  # Filter users with a search query.
  def filter(users, search)
    return users if search.nil? || search.blank?

    users.where('users.id like ?', "#{search}%").or(
      users.where('users.email like ?', "#{search}%").or(
        users.where('jurisdictions.path like ?', "#{search}%")
      )
    )
  end

  # Create and save a new user. Triggers welcome email to be sent.
  def create_user
    redirect_to(root_url) && return unless current_user.has_role? :admin

    permitted_params = params[:admin].permit(:email, :jurisdiction, :role_title, :is_api_enabled)
    email = permitted_params[:email]
    return head :bad_request if email.nil? || email.blank?

    email = email.strip
    address = ValidEmail2::Address.new(email)
    return head :bad_request unless address.valid? && !address.disposable?

    role = permitted_params[:role_title]
    return head :bad_request if role.nil? || role.blank?

    # Parse back to format in records
    role = role.split(' ').map(&:downcase).join('_')
    return head :bad_request unless User.ROLES.include?(role)

    jurisdiction = permitted_params[:jurisdiction]

    # New jurisdiction should only be from the subset of jurisdictions available to the current user
    allowed_jurisdictions = current_user.jurisdiction.subtree.pluck(:id)
    return head :bad_request unless allowed_jurisdictions.include?(jurisdiction)

    is_api_enabled = permitted_params[:is_api_enabled]
    return head :bad_request unless [true, false].include? is_api_enabled

    # Generate initial password for user
    password = User.rand_gen

    # Create user
    # - require user to change password on first login
    user = User.create!(
      email: email,
      password: password,
      jurisdiction: Jurisdiction.find_by_id(jurisdiction),
      force_password_change: true,
      api_enabled: is_api_enabled,
      role: role
    )
    user.save!
    UserMailer.welcome_email(user, password).deliver_later
  end

  # Edit existing user.
  def edit_user
    redirect_to(root_url) && return unless current_user.has_role? :admin

    permitted_params = params[:admin].permit(:id, :email, :jurisdiction, :role_title, :is_api_enabled, :is_locked)

    id = permitted_params[:id]
    user_ids = User.pluck(:id)
    return head :bad_request unless user_ids.include?(id)

    email = permitted_params[:email]
    return head :bad_request if email.nil? || email.blank?

    email = email.strip
    address = ValidEmail2::Address.new(email)
    return head :bad_request unless address.valid? && !address.disposable?

    role = permitted_params[:role_title]
    return head :bad_request if role.nil? || role.blank?

    # Parse back to format in records
    role = role.split(' ').map(&:downcase).join('_')
    return head :bad_request unless User.ROLES.include?(role)

    jurisdiction = permitted_params[:jurisdiction]

    # New jurisdiction should only be from the subset of jurisdictions available to the current user
    allowed_jurisdictions = current_user.jurisdiction.subtree.pluck(:id)
    return head :bad_request unless allowed_jurisdictions.include?(jurisdiction)

    is_api_enabled = permitted_params[:is_api_enabled]
    return head :bad_request unless [true, false].include? is_api_enabled

    is_locked = permitted_params[:is_locked]
    return head :bad_request unless [true, false].include? is_locked

    # Find user
    user = User.find_by(id: id)
    return head :bad_request unless user

    # Verify user current jurisdiction access
    cur_jur = current_user.jurisdiction
    redirect_to(root_url) && return unless cur_jur.subtree_ids.include? user.jurisdiction.id

    # Update email
    user.email = email

    # Update jurisdiction
    user.jurisdiction = Jurisdiction.find_by_id(jurisdiction)

    # Update API access
    user.update!(api_enabled: is_api_enabled, role: role)

    # Update locked status
    if user.locked_at.nil? && is_locked
      user.lock_access!
    elsif !user.locked_at.nil? && !is_locked
      user.unlock_access!
    end

    user.save!
  end

  # Resets 2FA for the users with ids in params.
  def reset_2fa
    redirect_to(root_url) && return unless current_user.has_role? :admin

    permitted_params = params[:admin].permit({ ids: [] })
    ids = permitted_params[:ids]
    return head :bad_request unless ids.is_a?(Array)

    users = User.where(id: ids)
    cur_jur = current_user.jurisdiction

    # This should never happen, but if there is a user who is not underneath the current user's jurisdiction
    # this is a bad request.
    users.each { |u| return head :bad_request unless cur_jur.subtree_ids.include? u.jurisdiction.id }

    users.each do |user|
      user.authy_id = nil
      user.authy_enabled = false
      user.save!
    end
  end

  # Resets passwords of the users with ids in params.
  def reset_password
    redirect_to(root_url) && return unless current_user.has_role? :admin

    permitted_params = params[:admin].permit({ ids: [] })
    ids = permitted_params[:ids]
    return head :bad_request unless ids.is_a?(Array)

    users = User.where(id: ids)
    cur_jur = current_user.jurisdiction

    # This should never happen, but if there is a user who is not underneath the current user's jurisdiction
    # this is a bad request.
    users.each { |u| return head :bad_request unless cur_jur.subtree_ids.include? u.jurisdiction.id }

    users.each do |user|
      user.unlock_access!
      password = User.rand_gen
      user.password = password
      user.force_password_change = true
      user.save!
      UserMailer.welcome_email(user, password).deliver_later
    end
  end

  # Sends email to all users in this admin's jurisdiction.
  def email_all
    redirect_to(root_url) && return unless current_user.can_send_admin_emails?

    permitted_params = params[:admin].permit(:comment)
    comment = permitted_params[:comment]
    return head :bad_request if comment.nil? || comment.blank?

    # Get all users within the current user's jurisdiction that are not locked
    users = User.where(jurisdiction_id: current_user.jurisdiction.subtree_ids).where(locked_at: nil)

    users.each do |user|
      UserMailer.admin_message_email(user, comment).deliver_later
    end
  end
end
