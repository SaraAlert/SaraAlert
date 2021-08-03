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
          type: 'base',
          config: {}
        },
        header_action_buttons: {
          type: 'base',
          config: {}
        },
        dashboard_table_columns: {
          type: 'base',
          config: {}
        }
      } },
      isolation: { label: 'Isolation', base: INFECTIOUS[:workflows][:isolation], custom_options: {
        dashboard_tabs: {
          type: 'base',
          config: {}
        },
        header_action_buttons: {
          type: 'base',
          config: {}
        },
        dashboard_table_columns: {
          type: 'base',
          config: {}
        }
      } },
      global: { label: 'Global', base: INFECTIOUS[:workflows][:global], custom_options: {
        dashboard_tabs: {
          type: 'base',
          config: {}
        },
        header_action_buttons: {
          type: 'base',
          config: {}
        },
        dashboard_table_columns: {
          type: 'base',
          config: {}
        }
      } }
    },
    general: {
      base: INFECTIOUS[:general], custom_options: {
        patient_page_sections: {
          type: 'base',
          config: {}
        },
        monitoring_dashboard_buttons: {
          type: 'base',
          config: {}
        }
      }
    },
    system: {
      # Define primary, i.e., default, workflow to present on dashboard
      primary_workflow: :exposure,
      continuous_exposure_enabled: true
    }
  }.freeze
end
