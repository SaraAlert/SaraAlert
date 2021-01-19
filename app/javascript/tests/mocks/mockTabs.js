const mockExposureTabs = {
  all: {
    description: 'All Monitorees in this jurisdiction, in the Exposure workflow.',
    label: 'All Monitorees',
    variant: 'primary'
  },
  asymptomatic: {
    description: 'Monitorees currently reporting no symptoms, who have reported during the last day.',
    label: 'Asymptomatic',
    tooltip: 'exposure_asymptomatic',
    variant: 'success'
  },
  closed: {
    description: 'Monitorees not currently being monitored.',
    label: 'Closed',
    tooltip: 'exposure_closed',
    variant: 'secondary'
  },
  non_reporting: {
    label: 'Non-Reporting',
    variant: 'warning',
    tooltip: 'exposure_non_reporting',
    description: 'Monitorees who have failed to report in the last day, and are not symptomatic.'
  },
  pui: {
    description: 'Monitorees who are currently under investigation.',
    label: 'PUI',
    tooltip: 'exposure_under_investigation',
    variant: 'dark'
  },
  symptomatic: {
    description: 'Monitorees who have reported symptoms, which need to be reviewed.',
    label: 'Symptomatic',
    tooltip: 'exposure_symptomatic',
    variant: 'danger'
  },
  transferred_in: {
    description: 'Monitorees that have been transferred into this jurisdiction during the last 24 hours.',
    label: 'Transferred In',
    variant: 'info'
  },
  transferred_out: {
    description: 'Monitorees that have been transferred out of this jurisdiction.',
    label: 'Transferred Out',
    variant: 'info'
  }
};

const mockIsolationTabs = {
  all: {
    description: 'All cases in this jurisdiction, in the Isolation workflow.',
    label: 'All Cases',
    variant: 'primary'
  },
  closed: {
    description: 'Cases not currently being monitored.',
    label: 'Closed',
    tooltip: 'isolation_closed',
    variant: 'secondary'
  },
  non_reporting: {
    description: 'Cases who failed to report during the last day and have not yet met recovery definition.',
    label: 'Non-Reporting',
    tooltip: 'isolation_non_reporting',
    variant: 'warning'
  },
  reporting: {
    description: 'Cases who have reported in the last day and have not yet met recovery definition.',
    label: 'Reporting',
    tooltip: 'isolation_reporting',
    variant: 'success'
  },
  requiring_review: {
    description: 'Cases who preliminarily meet the recovery definition and require review.',
    label: 'Records Requiring Review',
    tooltip: 'isolation_records_requiring_review',
    variant: 'danger'
  },
  transferred_in: {
    description: 'Cases that have been transferred into this jurisdiction during the last 24 hours.',
    label: 'Transferred In',
    variant: 'info'
  },
  transferred_out: {
    description: 'Cases that have been transferred out of this jurisdiction.',
    label: 'Transferred Out',
    variant: 'info'
  }
}

export {
  mockExposureTabs,
  mockIsolationTabs
}