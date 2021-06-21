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
            set: %i[symptomatic non_reporting],
            custom_options: {
              symptomatic: {
                label: 'Some random label'
              }
            }
          }
        },
        header_action_buttons: {
          type: 'subset',
          config: {
            set: %i[enroll import],
            custom_options: {
              import: {
                  label: 'Import',
                  type: 'subset',
                  config: {
                    set: %i[saf]
                  }
              },
              export: {
                  label: 'Export',
                  type: 'subset',
                  config: {
                    set: %i[saf]
                  }
              }
            }
          }
        },
        other_properties: {
        }
      } },
      isolation: { label: 'Isolation', base: INFECTIOUS[:workflows][:isolation], custom_options: {
        dashboard_tabs: {
          type: 'base'
        },
        header_action_buttons: {
          type: 'all'
        },
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
