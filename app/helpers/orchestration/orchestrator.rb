# frozen_string_literal: true

# Orchestrator: Methods for managing active playbook context
module Orchestration::Orchestrator # rubocop:todo Metrics/ModuleLength
  include Orchestration::Playbooks

  available = Orchestration::Playbooks.constants.reject { |m| m == :Templates }
  modules = available.map { |m| ('Orchestration::Playbooks::' + m.to_s).constantize }

  playbooks = {}
  modules.each { |m| playbooks[m::NAME] = m::PLAYBOOK }

  PLAYBOOKS = playbooks.freeze

  def workflow_configuration(playbook, workflow, option)
    # For now, assume that if no workflow (ie it is nil, it is a general option)
    base_configuration = workflow.nil? ? PLAYBOOKS.dig(playbook, :general, :base, option) : PLAYBOOKS.dig(playbook, :workflows, workflow, :base, option)
    custom_options = workflow.nil? ? PLAYBOOKS.dig(playbook, :general, :custom_options,
                                                   option) : PLAYBOOKS.dig(playbook, :workflows, workflow, :custom_options, option)

    return if base_configuration.nil? # UNNECESSARY?
    return base_configuration if custom_options.nil?

    # return EMPTY if (base_config or custom_options) is nil?

    nested_configuration(base_configuration, custom_options)
  end

  # 'base': Return the whole base configuration. Do not follow nested configurations
  # 'all': Return the base configuration options, but also follow the nested configurations
  # 'subset': Select the given keys from the options, but also follow the nested configurations
  # 'remove': Reject the given keys from the options, but also follow the nested configurations
  # 'custom': Overwrite the whole configuration
  def nested_configuration(base_configuration, playbook_configuration)
    # Replace label first if available
    unless base_configuration[:label].nil?
      base_configuration[:label] =
        playbook_configuration[:label].nil? ? base_configuration[:label] : playbook_configuration[:label]
    end
    selected_configuration = {}
    selected_configuration[:label] = base_configuration[:label] if base_configuration[:label].present?

    # If playbook has no type, then we'll assume everything since we don't know what to do
    type = playbook_configuration[:type] || 'base'

    case type
    when 'base'
      # Return entirety of the base configuration
      return base_configuration
    when 'all'
      # Select the base configuration
      selected_configuration = base_configuration
    when 'subset'
      # If a subset, then look into the configuration and only return the wanted fields
      selected_configuration[:options] = base_configuration[:options].select { |key| playbook_configuration[:config][:set].include?(key) }
    when 'remove'
      # If remove, then look into the configuration and reject the listed fields
      selected_configuration[:options] = base_configuration[:options].reject { |key| playbook_configuration[:config][:set].include?(key) }
    when 'custom'
      # TODO: This is here as a catch all, but this isn't really being implemented
      # For now the assumption is if you choose custom you need to write the whole configuration
      # including the nested configuration
      return playbook_configuration[:config]
    end

    nested_options = playbook_configuration.dig(:config, :custom_options)

    # If there are no custom options... just return!
    return selected_configuration if nested_options.nil?

    # Otherwise we'll checkout the children
    nested_options.each do |key, value|
      next if base_configuration[:options][key].nil?

      selected_configuration[:options][key] = nested_configuration(base_configuration[:options][key], value)
    end

    selected_configuration
  end

  def system_configuration(playbook, option)
    PLAYBOOKS.dig(playbook, :system, option)
  end

  def available_playbooks
    PLAYBOOKS.keys.collect { |key| { name: key, label: PLAYBOOKS[key][:label] } }
  end

  def available_workflows(playbook, filter_out_global: true)
    workflows = PLAYBOOKS[playbook][:workflows].keys.collect { |key| { name: key, label: PLAYBOOKS[playbook][:workflows][key][:label] } }
    workflows = workflows.reject { |key| key[:name] == :global } if filter_out_global

    workflows
  end

  # NOTE: Since we're currently assuming that really we just have exposure/isolation
  # and isolation is being treated as special, this function is useful
  def isolation_available?(playbook)
    PLAYBOOKS.dig(playbook, :workflows, :isolation).present?
  end

  def continuous_exposure_enabled?(playbook)
    enabled = ActiveModel::Type::Boolean.new.cast(system_configuration(playbook, :continuous_exposure_enabled))
    enabled = true if enabled.nil?
    enabled
  end

  # Returns array of hashes (for each available workflow that lists the available line lists.
  def available_line_lists(playbook)
    workflows = available_workflows(playbook)

    line_lists = {}
    workflows.each do |wf|
      line_lists[wf[:name]] = workflow_configuration(playbook, wf[:name], :dashboard_tabs)
    end

    line_lists
  end

  def default_workflow(playbook)
    available_workflows = available_workflows(playbook)

    if available_workflows.size == 1
      default = available_workflows[0]
    else
      primary_workflow_key = PLAYBOOKS.dig(playbook, :system, :primary_workflow)

      # No workflows were marked as primary. Prefer one named exposure
      if primary_workflow_key.blank?
        workflow_name = :exposure
        workflow = PLAYBOOKS.dig(playbook, :workflows, workflow_name)
        if workflow.blank?
          # NOTE: This does not guarantee the same workflow is selected every time.
          workflow = available_workflows[0]
          workflow_name = workflow[:name]
        end
        default = { name: workflow_name, label: workflow[:label].nil? ? '' : workflow[:label].to_s }
      else
        label = PLAYBOOKS.dig(playbook, :workflows, primary_workflow_key, :label)
        default = { name: (':' + primary_workflow_key.to_s).parameterize.underscore.to_sym,
                    label: (label.nil? ? '' : label.to_s) }
      end
    end
    default
  end

  # Return the symbol to the default playbook
  def default_playbook
    # Sara Alert is always expected to have a covid_19 playbook
    playbook_name = ADMIN_OPTIONS['playbook_name'] || 'covid_19'

    default_playbook = playbook_name.parameterize.underscore.to_sym
    redirect_to('/404') && return if PLAYBOOKS[default_playbook].nil?

    default_playbook
  end

  # Return the label for the specified playbook (symbol)
  def playbook_label(playbook)
    PLAYBOOKS.dig((playbook.nil? ? default_playbook : playbook), :label)
  end
end
