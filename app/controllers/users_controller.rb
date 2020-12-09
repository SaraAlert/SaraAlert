# frozen_string_literal: true

require 'will_paginate/array'

# UsersController: user model controller
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_user_role

  def audits
    redirect_to(root_url) && return unless current_user.can_view_user_audits?

    permitted_params = params.permit(:entries, :page, :order, :direction, :id, :cancelToken)
    return head :bad_request unless permitted_params[:id].present?

    # Validate pagination params
    entries = permitted_params[:entries]&.to_i || 25
    page = permitted_params[:page]&.to_i || 0
    return head :bad_request unless entries >= 0 && page >= 0

    # Validate sort params
    order_by = permitted_params[:order]
    return head :bad_request unless order_by.nil? || order_by.blank? || %w[user timestamp].include?(order_by)

    sort_direction = permitted_params[:direction]
    return head :bad_request unless sort_direction.nil? || sort_direction.blank? || %w[asc desc].include?(sort_direction)
    return head :bad_request unless (!order_by.blank? && !sort_direction.blank?) || (order_by.blank? && sort_direction.blank?)

    # Find user
    user = User.find_by(id: permitted_params[:id])
    return head :bad_request if user.nil?

    # Check jurisdiction permissions
    cur_jur = current_user.jurisdiction
    return head :unauthorized unless cur_jur.subtree_ids.include? user.jurisdiction.id

    # Break out audits into all the individual changes
    individual_audits = []
    user.audits.each do |a|
      if a.audited_changes.key?('created_at')
        change = { name: 'created_at', details: a.audited_changes['created_at'] }
        individual_audits.unshift(change: change, user: User.find(a.user_id || user.id).email, timestamp: a.created_at)
      else
        a.audited_changes.each do |change_name, details|
          change = { name: change_name, details: details }
          individual_audits.unshift(change: change, user: User.find(a.user_id || user.id).email, timestamp: a.created_at)
        end
      end
    end

    # Sort
    individual_audits = sort(individual_audits, order_by, sort_direction)

    # Paginate
    individual_audits = individual_audits.paginate(per_page: entries, page: page + 1)

    # Get total count
    total = individual_audits.total_entries

    # Return audits for user
    render json: { audit_rows: individual_audits, total: total }
  end

  # Sort users by a given field either in ascending or descending order.
  def sort(individual_audits, order_by, sort_direction)
    return individual_audits if order_by.nil? || order_by.empty? || sort_direction.nil? || sort_direction.blank?

    # Satisfy brakeman with additional sanitation logic
    dir = sort_direction == 'asc' ? 'asc' : 'desc'

    case order_by
    when 'user'
      individual_audits = if dir == 'asc'
                            individual_audits.sort_by { |a| a[:user] }
                          else
                            individual_audits.sort_by { |a| a[:user] }.reverse
                          end
    when 'timestamp'
      individual_audits = if dir == 'asc'
                            individual_audits.sort_by { |a| a[:timestamp] }
                          else
                            individual_audits.sort_by { |a| a[:timestamp] }.reverse
                          end
    end

    individual_audits
  end

  def authenticate_user_role
    return head :unauthorized unless current_user.admin? || current_user.super_user?
  end
end
