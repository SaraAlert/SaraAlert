# frozen_string_literal: true

# UserFiltersController: used to manage user saved advanced filters
class UserFiltersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_role

  def index
    render json: current_user.user_filters.collect { |filter| { contents: JSON.parse(filter.contents), name: filter.name, id: filter.id } }
  end

  def create
    # Enforce upper limit per user
    if current_user.user_filters.count >= ADMIN_OPTIONS['max_user_filters']
      error_message = 'You have reached the maximum allowed number of saved filters for your account. '\
                      'Please delete an existing filter before attempting to add another.'
      render(json: { error: error_message }, status: :bad_request) && return
    end

    active_filter_options = params.require(:activeFilterOptions).collect do |filter|
      {
        filterOption: filter.require(:filterOption).permit(:name, :title, :description, :type, :hasTimestamp, :allowRange, options: []),
        value: filter.permit(:value)[:value] || filter.require(:value) || false,
        numberOption: filter.permit(:numberOption)[:numberOption],
        dateOption: filter.permit(:dateOption)[:dateOption],
        relativeOption: filter.permit(:relativeOption)[:relativeOption],
        additionalFilterOption: filter.permit(:additionalFilterOption)[:additionalFilterOption]
      }
    end
    name = params.require(:name)
    render json: UserFilter.create!(contents: active_filter_options.to_json, name: name, user_id: current_user.id)
  end

  def update
    active_filter_options = params.require(:activeFilterOptions).collect do |filter|
      {
        filterOption: filter.require(:filterOption).permit(:name, :title, :description, :type, :hasTimestamp, :allowRange, options: []),
        value: filter.permit(:value)[:value] || filter.require(:value) || false,
        numberOption: filter.permit(:numberOption)[:numberOption],
        dateOption: filter.permit(:dateOption)[:dateOption],
        relativeOption: filter.permit(:relativeOption)[:relativeOption],
        additionalFilterOption: filter.permit(:additionalFilterOption)[:additionalFilterOption]
      }
    end
    user_filter = current_user.user_filters.find_by(id: params.permit(:id)[:id])
    return if user_filter.nil?

    user_filter.update(contents: active_filter_options.to_json)
    render json: user_filter
  end

  def destroy
    current_user.user_filters.find_by(id: params.permit(:id)[:id])&.destroy!
  end

  private

  def check_role
    current_user.can_manage_saved_filters?
  end
end
