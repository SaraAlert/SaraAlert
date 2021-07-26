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
            set: %i[symptomatic non_reporting all],
            custom_options: {
              symptomatic: {
                label: 'Symptomatic'
              }
            }
          }
        },
        header_action_buttons: {
          type: 'all',
          config: {
            set: %i[enroll import],
            custom_options: {
              import: {
                label: 'Import',
                type: 'all',
                config: {
                  set: %i[saf]
                }
              }
            }
          }
        },
        dashboard_table_columns: {
          type: 'all',
          config: {
            custom_options: {
              symptomatic: {
                type: 'all',
                config: {
                  set: %i[jurisdiction end_of_monitoring risk_level]
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
        }
      } },
      global: { label: 'Global', base: INFECTIOUS[:workflows][:global], custom_options: {
      } }
    },
    general: {
      base: INFECTIOUS[:general], custom_options: {
        patient_page_sections: {
          type: 'all',
          config: {
            custom_options: {
            }
          }
        }
      }
    },
    system: {
      # Define primary, i.e., default, workflow to present on dashboard
      primary_workflow: :exposure,
      continuous_exposure_enabled: true
    },
    other_properties: {

    }
  }.freeze
end
