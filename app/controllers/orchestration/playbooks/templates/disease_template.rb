# Types of diseases and largest sets?

module Orchestration::Playbooks::Templates::DiseaseTemplate
  INFECTIOUS = {
    workflows: {
      exposure: {
        dashboard_tabs: {
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
          all: {
            label: 'All Monitorees',
            variant: 'primary',
            description: 'All Monitorees in this jurisdiction, in the Exposure workflow.'
          }
        }
      },
      isolation: {
        dashboard_tabs: {
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
      }
    }
  }
end
