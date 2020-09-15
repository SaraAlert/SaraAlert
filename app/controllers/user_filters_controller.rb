# frozen_string_literal: true

# UserFiltersController: used to manage user saved advanced filters
class UserFiltersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_role

  def index
    render json: current_user.user_filters
  end

  def create
    redirect_to root_url unless current_user.user_filters.count < 100 # Enforce upper limit per user
    active = params.require(:active).collect do |filter|
      {
        filterOption: filter.require(:filterOption).permit(:name, :title, :description, :type, options: []),
        value: filter.require(:value),
        dateOption: filter.permit(:dateOption)[:dateOption]
      }
    end
    name = params.require(:name)
    render json: UserFilter.create!(contents: active, name: name, user_id: current_user.id)
  end

  def update
    active = params.require(:active).collect do |filter|
      {
        filterOption: filter.require(:filterOption).permit(:name, :title, :description, :type, options: []),
        value: filter.require(:value),
        dateOption: filter.permit(:dateOption)[:dateOption]
      }
    end
    user_filter = current_user.user_filters.find_by(id: params.permit(:id)[:id])
    user_filter.update(contents: active)
    render json: user_filter
  end

  def destroy
    current_user.user_filters.find_by(id: params.permit(:id)[:id]).destroy!
  end

  private

  def check_role
    current_user.can_manage_saved_filters?
  end
end
