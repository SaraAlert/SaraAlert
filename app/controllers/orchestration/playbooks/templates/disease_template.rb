# Types of diseases and largest sets?

module Orchestration::Playbooks::Templates::DiseaseTemplate
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
              description: 'Monitorees who have reported symptoms, which need to be reviewed.'
            },
            non_reporting: {
              label: 'Non-Reporting',
              variant: 'warning',
              tooltip: 'exposure_non_reporting',
              description: 'Monitorees who have failed to report in the last day, and are not symptomatic.'
            },
            asymptomatic: {
              label: 'Asymptomatic',
              variant: 'success',
              tooltip: 'exposure_asymptomatic',
              description: 'Monitorees currently reporting no symptoms, who have reported during the last day.'
            },
            pui: {
              label: 'PUI',
              variant: 'dark',
              tooltip: 'exposure_under_investigation',
              description: 'Monitorees who are currently under investigation.'
            },
            closed: {
              label: 'Closed',
              variant: 'secondary',
              tooltip: 'exposure_closed',
              description: 'Monitorees not currently being monitored.'
            },
            transferred_in: {
              label: 'Transferred In',
              variant: 'info',
              description: 'Monitorees that have been transferred into this jurisdiction during the last 24 hours.'
            },
            transferred_out: {
              label: 'Transferred Out',
              variant: 'info',
              description: 'Monitorees that have been transferred out of this jurisdiction.'
            },
            # This is required
            all: {
              label: 'All Monitorees',
              variant: 'primary',
              description: 'All Monitorees in this jurisdiction, in the Exposure workflow.'
            }
          }
        },
        header_action_buttons: {
          options: {
            enroll: { label: 'Enroll New Monitoree'},
            export: { label: 'Export', options: {
              csv: { label: 'Line list CSV (Exposure)' },
              saf: { label: 'Sara Alert Format(Exposure)' },
              purge_eligible: { label: 'Excel Export for Purge-Eligible Monitorees' },
              all: { label: 'Excel Export For All Monitorees' },
              custom_format: { label: 'Custom Format...'}
            }},
            import: { label: 'Import', options: {
              epix: { label: 'Epi-X (Exposure)' },
              saf: { label: 'Sara Alert Format (Exposure)'}
            }}
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
            description: 'Cases who preliminarily meet the recovery definition and require review.'
          },
          non_reporting: {
            label: 'Non-Reporting',
            variant: 'warning',
            tooltip: 'isolation_non_reporting',
            description: 'Cases who failed to report during the last day and have not yet met recovery definition.'
          },
          reporting: {
            label: 'Reporting',
            variant: 'success',
            tooltip: 'isolation_reporting',
            description: 'Cases who have reported in the last day and have not yet met recovery definition.'
          },
          closed: {
            label: 'Closed',
            variant: 'secondary',
            tooltip: 'isolation_closed',
            description: 'Cases not currently being monitored.'
          },
          transferred_in: {
            label: 'Transferred In',
            variant: 'info',
            description: 'Cases that have been transferred into this jurisdiction during the last 24 hours.'
          },
          transferred_out: {
            label: 'Transferred Out',
            variant: 'info',
            description: 'Cases that have been transferred out of this jurisdiction.'
          },
          all: {
            label: 'All Cases',
            variant: 'primary',
            description: 'All cases in this jurisdiction, in the Isolation workflow.'
          }
        }
        },
        header_action_buttons: {
          options: {
          enroll: { label: 'Enroll New Case'},
          export: { label: 'Export', options: {
            csv: { label: 'Line list CSV (Isolation)' },
            saf: { label: 'Sara Alert Format(Isolation)' },
            purge_eligible: { label: 'Excel Export for Purge-Eligible Monitorees' },
            all: { label: 'Excel Export For All Monitorees' },
            custom_format: { label: 'Custom Format...'}

          }},
          import: { label: 'Import', options: {
            epix: { label: 'Epi-X (Isolation)' },
            saf: { label: 'Sara Alert Format (Isolation)'}
          }}
          }
        }

      }
    },
    general: {

    }
  }
end
