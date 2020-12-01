# frozen_string_literal: true

require 'will_paginate/array'

# UsersController: user model controller
class UsersController < ApplicationController
  before_action :authenticate_user!

  def audits
    redirect_to(root_url) && return unless current_user.can_view_user_audits?
    permitted_params = params.permit(:entries, :page, :id, :cancelToken)
    return head :bad_request unless permitted_params[:id].present?

    # Validate pagination params
    entries = permitted_params[:entries]&.to_i || 15
    page = permitted_params[:page]&.to_i || 0
    return head :bad_request unless entries >= 0 && page >= 0

    # Find user
    user = User.find_by(id: permitted_params[:id])
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

    # Paginate
    individual_audits = individual_audits.paginate(per_page: entries, page: page + 1)

    # Get total count
    total = individual_audits.total_entries

    # Return audits for user
    render json: { audit_rows: individual_audits, total: total }
  end
end
