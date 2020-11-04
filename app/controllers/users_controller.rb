# frozen_string_literal: true

# UsersController: user model controller
class UsersController < ApplicationController
  before_action :authenticate_user!

  def audits
    redirect_to(root_url) && return unless current_user.can_view_user_audits?

    # Grab id
    id_param = params.permit(:id)
    return head :bad_request unless id_param.present?

    # Find user
    user = User.find_by(id: id_param[:id])
    return head :bad_request if user.nil?

    # Check jurisdiction permissions
    cur_jur = current_user.jurisdiction
    return head :bad_request unless cur_jur.subtree_ids.include? user.jurisdiction.id

    # Return audits for user
    render json: user.audits.collect { |a| { change: a.audited_changes, user: User.find(a.user_id).email, when: a.created_at } }.to_json
  end
end
