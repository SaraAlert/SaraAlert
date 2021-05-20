# frozen_string_literal: true

#  Playbook Configuration for COVID-19 Monitoring
module Orchestration::Playbooks::Covid19Playbook
  include Orchestration::Playbooks::Templates::DiseaseTemplate

  NAME = :covid_19

  PLAYBOOK = {
    label: 'COVID-19',
    workflows: {
      exposure: { label: 'Exposure', base: INFECTIOUS[:workflows][:exposure], custom_options: {
        dashboard_tabs: {
          type: 'all',
          config: {
            set: %i[symptomatic non_reporting]
          }
        },
        other_properties: {
        }
      } },
      isolation: { label: 'Isolation', base: INFECTIOUS[:workflows][:isolation], custom_options: {
        dashboard_tabs: {
          type: 'all'
        }
      } }
    },
    system: {
      # Define primary, i.e., default, workflow to present on dashboard
      primary_workflow: :exposure,
      continuous_exposure_enabled: true
    },
    other_properties: {
    }
  }
end
