# frozen_string_literal: true

# Types of diseases and largest sets?

module Orchestration::Playbooks::Templates::DiseaseTemplate # rubocop:todo Metrics/ModuleLength
  INFECTIOUS = {
    workflows: {
      exposure: {
        # Public Health Dashboard Configurations
        dashboard_tabs: {
          options: {
            symptomatic: {
              label: 'Symptomatic',
              variant: 'danger',
              tooltip: 'exposure_symptomatic',
              description: 'Monitorees who have reported symptoms, which need to be reviewed.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user end_of_monitoring risk_level monitoring_plan latest_report report_eligibility]
            },
            non_reporting: {
              label: 'Non-Reporting',
              variant: 'warning',
              tooltip: 'exposure_non_reporting',
              description: 'Monitorees who have failed to report in the last day, and are not symptomatic.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user end_of_monitoring risk_level monitoring_plan latest_report report_eligibility]
            },
            asymptomatic: {
              label: 'Asymptomatic',
              variant: 'success',
              tooltip: 'exposure_asymptomatic',
              description: 'Monitorees currently reporting no symptoms, who have reported during the last day.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user end_of_monitoring risk_level monitoring_plan latest_report report_eligibility]
            },
            pui: {
              label: 'PUI',
              variant: 'dark',
              tooltip: 'exposure_under_investigation',
              description: 'Monitorees who are currently under investigation.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user end_of_monitoring risk_level public_health_action latest_report report_eligibility]
            },
            closed: {
              label: 'Closed',
              variant: 'secondary',
              tooltip: 'exposure_closed',
              description: 'Monitorees not currently being monitored.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user expected_purge_date reason_for_closure closed_at]
            },
            transferred_in: {
              label: 'Transferred In',
              variant: 'info',
              description: 'Monitorees that have been transferred into this jurisdiction during the last 24 hours.',
              options: %i[flagged_for_follow_up transferred_from end_of_monitoring risk_level monitoring_plan transferred_at]
            },
            transferred_out: {
              label: 'Transferred Out',
              variant: 'info',
              description: 'Monitorees that have been transferred out of this jurisdiction.',
              options: %i[transferred_to end_of_monitoring risk_level monitoring_plan transferred_at]
            },
            # This is required
            all: {
              label: 'All Monitorees',
              variant: 'primary',
              description: 'All Monitorees in this jurisdiction, in the Exposure workflow.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user end_of_monitoring risk_level monitoring_plan latest_report status report_eligibility]
            }
          }
        },
        header_action_buttons: {
          options: {
            enroll: { label: 'Enroll New Monitoree' },
            export: { label: 'Export', options: {
              csv: { label: 'Line list CSV', workflow_specific: true },
              saf: { label: 'Sara Alert Format', workflow_specific: true },
              purge_eligible: { label: 'Excel Export For Purge-Eligible Monitorees', workflow_specific: false },
              all: { label: 'Excel Export For All Monitorees', workflow_specific: false },
              custom_format: { label: 'Custom Format...', workflow_specific: false }
            } },
            import: { label: 'Import', options: {
              epix: { label: 'Epi-X', workflow_specific: true },
              saf: { label: 'Sara Alert Format', workflow_specific: true },
              sdx: { label: 'SDX', workflow_specific: true }
            } }
          }
        }
      },
      isolation: {
        # Public Health Dashboard Configurations
        dashboard_tabs: {
          options: {
            requiring_review: {
              label: 'Records Requiring Review',
              variant: 'danger',
              tooltip: 'isolation_records_requiring_review',
              description: 'Cases who preliminarily meet the recovery definition and require review.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user extended_isolation first_positive_lab_at symptom_onset monitoring_plan latest_report
                          report_eligibility]
            },
            non_reporting: {
              label: 'Non-Reporting',
              variant: 'warning',
              tooltip: 'isolation_non_reporting',
              description: 'Cases who failed to report during the last day and have not yet met recovery definition.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user extended_isolation first_positive_lab_at symptom_onset monitoring_plan latest_report
                          report_eligibility]
            },
            reporting: {
              label: 'Reporting',
              variant: 'success',
              tooltip: 'isolation_reporting',
              description: 'Cases who have reported in the last day and have not yet met recovery definition.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user extended_isolation first_positive_lab_at symptom_onset monitoring_plan latest_report
                          report_eligibility]
            },
            closed: {
              label: 'Closed',
              variant: 'secondary',
              tooltip: 'isolation_closed',
              description: 'Cases not currently being monitored.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user expected_purge_date reason_for_closure closed_at]
            },
            transferred_in: {
              label: 'Transferred In',
              variant: 'info',
              description: 'Cases that have been transferred into this jurisdiction during the last 24 hours.',
              options: %i[flagged_for_follow_up transferred_from monitoring_plan transferred_at]
            },
            transferred_out: {
              label: 'Transferred Out',
              variant: 'info',
              description: 'Cases that have been transferred out of this jurisdiction.',
              options: %i[transferred_to monitoring_plan transferred_at]
            },
            all: {
              label: 'All Cases',
              variant: 'primary',
              description: 'All cases in this jurisdiction, in the Isolation workflow.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user extended_isolation first_positive_lab_at symptom_onset monitoring_plan latest_report
                          status report_eligibility]
            }
          }
        },
        header_action_buttons: {
          options: {
            enroll: { label: 'Enroll New Case' },
            export: { label: 'Export', options: {
              csv: { label: 'Line list CSV', workflow_specific: true },
              saf: { label: 'Sara Alert Format', workflow_specific: true },
              purge_eligible: { label: 'Excel Export For Purge-Eligible Monitorees', workflow_specific: false },
              all: { label: 'Excel Export For All Monitorees', workflow_specific: false },
              custom_format: { label: 'Custom Format...', workflow_specific: false }

            } },
            import: { label: 'Import', options: {
              epix: { label: 'Epi-X', workflow_specific: true },
              saf: { label: 'Sara Alert Format', workflow_specific: true },
              sdx: { label: 'SDX', workflow_specific: true }
            } }
          }
        }
      },
      global: {
        # Public Health Dashboard Configurations
        dashboard_tabs: {
          options: {
            active: {
              label: 'Active',
              variant: 'success',
              description: 'Monitorees currently being actively monitored across both the exposure and isolation workflows.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user end_of_monitoring monitoring_plan reporter latest_report workflow status
                          report_eligibility]
            },
            priority_review: {
              label: 'Priority Review',
              variant: 'danger',
              description: 'Monitorees who meet the criteria to appear on either the Symptomatic line list (exposure) or '\
              'Records Requiring Review line list (isolation) which need to be reviewed.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user end_of_monitoring monitoring_plan reporter latest_report workflow status
                          report_eligibility]
            },
            non_reporting: {
              label: 'Non-Reporting',
              variant: 'warning',
              description: 'All monitorees who have failed to report in the last day across both the exposure and isolation workflows.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user end_of_monitoring monitoring_plan reporter latest_report workflow status
                          report_eligibility]
            },
            closed: {
              label: 'Closed',
              variant: 'secondary',
              description: 'Monitorees not currently being monitored across both the exposure and isolation workflows.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user expected_purge_date reason_for_closure closed_at workflow]
            },
            all: {
              label: 'All Monitorees',
              variant: 'primary',
              description: 'All Monitorees in this jurisdiction across both the exposure and isolation workflows.',
              options: %i[flagged_for_follow_up jurisdiction assigned_user end_of_monitoring monitoring_plan reporter latest_report workflow status
                          report_eligibility]
            }
          }
        },
        header_action_buttons: {
          options: {
            enroll: { label: 'Enroll New Monitoree' },
            export: { label: 'Export', options: {
              csv: { label: 'Line list CSV', workflow_specific: true },
              saf: { label: 'Sara Alert Format', workflow_specific: true },
              purge_eligible: { label: 'Excel Export For Purge-Eligible Monitorees', workflow_specific: false },
              all: { label: 'Excel Export For All Monitorees', workflow_specific: false },
              custom_format: { label: 'Custom Format...', workflow_specific: false }
            } }
          }
        }
      }
    },
    general: {
      patient_page_sections: {
        options: {
          monitoring_actions: { label: 'Monitoring Actions' },
          assessment_table: { label: 'Reports' },
          lab_results: { label: 'Lab Results' },
          vaccines: { label: 'Vaccinations' },
          close_contacts: { label: 'Close Contacts' },
          history: { label: 'History' }
        }
      },
      monitoring_dashboard_buttons: {
        options: {
          exposure: { label: 'Exposure Monitoring', icon: 'fa-people-arrows' },
          isolation: { label: 'Isolation Monitoring', icon: 'fa-street-view' },
          global: { label: 'Global Dashboard', icon: 'fa-globe' }
        }
      }
    }
  }.freeze
end
