# frozen_string_literal: true

# DashboardController: Actions associated with presenting dasbhoards
class DashboardController < ApplicationController
  include Orchestration::Orchestrator

  before_action :authenticate_user!
  before_action :authenticate_user_role

  def dashboard
    @path_params = request.path_parameters

    playbook = @path_params[:playbook].parameterize.underscore.to_sym
    workflow = @path_params[:workflow].parameterize.underscore.to_sym

    @playbook_label = playbook_label(playbook)
    @workflow_label = PLAYBOOKS.dig(playbook, :workflows, workflow, :label)

    redirect_to('/404') && return if @playbook_label.nil? || @workflow_label.nil?

    tabs = workflow_configuration(playbook, workflow, :dashboard_tabs)
    @tabs = tabs[:options]
    button = workflow_configuration(playbook, workflow, :header_action_buttons)
    @header_action_buttons = button.nil? ? nil : button[:options]
    dashboard_buttons = workflow_configuration(playbook, nil, :monitoring_dashboard_buttons)
    @monitoring_dashboard_buttons = dashboard_buttons.nil? ? nil : dashboard_buttons[:options]
    @available_workflows = available_workflows(playbook, filter_out_global: false)
    @available_line_lists = available_line_lists(playbook)
  end

  def index
    @path_params = request.path_parameters

    if @path_params[:playbook].nil?
      # Request the playbook to use as the default from the orchestrator
      playbook = default_playbook
    else
      playbook = @path_params[:playbook].parameterize.underscore.to_sym
      # return error if playbook doesn't exist
      redirect_to('/404') && return if PLAYBOOKS[playbook].nil?
    end

    # Select the workflow to present as the default
    workflow = default_workflow(playbook)

    redirect_to('/404') && return if workflow.nil?

    redirect_to("/dashboard/#{playbook}/" + workflow[:name].to_s)
  end

  def authenticate_user_role
    # TODO: Role restriction with current_user, but we don't know if this is configurable yet
    # For now, stick with public health

    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?
  end
end
