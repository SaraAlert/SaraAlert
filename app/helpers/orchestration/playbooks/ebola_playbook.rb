# frozen_string_literal: true

# Playbook Configuration for Ebola Monitoring
module Orchestration::Playbooks::EbolaPlaybook
  include Orchestration::Playbooks::Templates::DiseaseTemplate

  NAME = :ebola

  PLAYBOOK = {
    label: 'Ebola',
    workflows: {
      exposure: { label: 'Exposure', base: INFECTIOUS[:workflows][:exposure], custom_options: {
        dashboard_tabs: {
          type: 'all'
        },
        other_properties: {
        }
      } }
    },
    system: {
      continuous_exposure_enabled: false
    },
    other_properties: {
    }
  }.freeze
end
