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

    # Structure array to be return so each audit encompasses a single change instead of multiple changes
    individual_audits = []
    user.audits.each do |a|
      a.audited_changes.each do |change_name, change_details|
        individual_audits.append(change: change_name, change_details: change_details, user: User.find(a.user_id).email, timestamp: a.created_at)
      end
    end

    # Return audits for user
    render json: individual_audits.to_json
  end
end
