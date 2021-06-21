export const advancedFilterOptions = [

  /* BOOLEAN FILTER OPTIONS */
  {
    name: 'continous-exposure',
    title: 'Continuous Exposure (Boolean)',
    description: 'Monitorees who have continuous exposure enabled',
    type: 'boolean',
  },
  {
    name: 'hoh',
    title: 'Daily Reporters (Boolean)',
    description: 'Monitorees that are a Head of Household or self-reporter',
    type: 'boolean',
  },
  {
    name: 'household-member',
    title: 'Household Member (Boolean)',
    description: 'Monitorees that are in a household but not the Head of Household',
    type: 'boolean',
  },
  {
    name: 'monitoring-status',
    title: 'Active Monitoring (Boolean)',
    description: 'Monitorees who are currently under active monitoring',
    type: 'boolean',
  },
  {
    name: 'never-responded',
    title: 'Never Reported (Boolean)',
    description: 'Monitorees who have no reports',
    type: 'boolean',
  },
  { name: 'paused', title: 'Notifications Paused (Boolean)', description: 'Monitorees who have paused notifications', type: 'boolean' },
  {
    name: 'require-interpretation',
    title: 'Requires Interpretation (Boolean)',
    description: 'Monitorees who require interpretation',
    type: 'boolean',
  },
  {
    name: 'responded-today',
    title: 'Reported in last 24 hours (Boolean)',
    description: 'Monitorees who had a report created in the last 24 hours',
    type: 'boolean',
  },
  {
    name: 'sent-today',
    title: 'Sent Notification in last 24 hours (Boolean)',
    description: 'Monitorees who have been sent a notification in the last 24 hours',
    type: 'boolean',
  },
  {
    name: 'sms-blocked',
    title: 'SMS Blocked (Boolean)',
    description: 'Monitorees that have blocked SMS communications with Sara Alert',
    type: 'boolean',
    tooltip:
      'This filter will return monitorees that have texted “STOP” in response to a Sara Alert text message and cannot receive messages through SMS Preferred Reporting Methods until they text "START".',
  },
  {
    name: 'seven-day-quarantine',
    title: 'Candidate to Reduce Quarantine after 7 Days (Boolean)',
    description:
      'All asymptomatic records that meet CDC criteria to end quarantine after Day 7 (based on last date of exposure and most recent lab result)',
    type: 'boolean',
    tooltip:
      'This filter is based on "Options to Reduce Quarantine for Contacts of Persons with SARS-COV-2 Infection Using Symptom Monitoring and Diagnostic Testing" released by the CDC on December 2, 2020. For more specific information, see Appendix A in the User Guide.',
  },
  {
    name: 'ten-day-quarantine',
    title: 'Candidate to Reduce Quarantine after 10 Days (Boolean)',
    description: 'All asymptomatic records that meet CDC criteria to end quarantine after Day 10 (based on last date of exposure)',
    type: 'boolean',
    tooltip:
      'This filter is based on "Options to Reduce Quarantine for Contacts of Persons with SARS-COV-2 Infection Using Symptom Monitoring and Diagnostic Testing" released by the CDC on December 2, 2020. For more specific information, see Appendix A in the User Guide.',
  },
  {
    name: 'ineligible-for-recovery-definition',
    title: 'Ineligible for any recovery definition (Boolean)',
    description: 'All isolation records ineligible to ever appear on Records Requiring Review line list',
    type: 'boolean',
    tooltip:
      'This filter will return all records in isolation without a Symptom Onset Date or not marked as Asymptomatic or marked as Asymptomatic without a positive lab result',
  },

  /* SEARCH FILTER OPTIONS */
  {
    name: 'address-foreign',
    title: 'Address (outside USA) (Text)',
    description: 'Monitoree Address 1, Town/City, Country, Address 2, Postal Code, Address 3 or State/Province (outside USA)',
    type: 'search',
  },
  {
    name: 'address-usa',
    title: 'Address (within USA) (Text)',
    description: 'Monitoree Address 1, Town/City, State, Address 2, Zip, or County within USA',
    type: 'search',
  },
  {
    name: 'close-contact-with-known-case-id',
    title: 'Close Contact with a Known Case ID (Text)',
    description: 'Monitorees with a known exposure to a probable or confirmed case ID',
    type: 'search',
    options: ['Exact Match', 'Contains'],
  },
  {
    name: 'cohort',
    title: 'Common Exposure Cohort Name (Text)',
    description: 'Monitoree common exposure cohort name or description',
    type: 'search',
  },
  {
    name: 'email',
    title: 'Email (Text)',
    description: 'Monitoree email address',
    type: 'search',
  },
  {
    name: 'first-name',
    title: 'Name (First) (Text)',
    description: 'Monitoree first name',
    type: 'search',
  },
  {
    name: 'last-name',
    title: 'Name (Last) (Text)',
    description: 'Monitoree last name',
    type: 'search',
  },
  {
    name: 'middle-name',
    title: 'Name (Middle) (Text)',
    description: 'Monitoree middle name',
    type: 'search',
  },
  {
    name: 'sara-id',
    title: 'Sara Alert ID (Text)',
    description: 'Monitoree Sara Alert ID',
    type: 'search',
  },
  {
    name: 'telephone-number',
    title: 'Telephone Number (Exact Match) (Text)',
    description: 'Monitorees with specified 10 digit telephone number',
    type: 'search',
  },
  {
    name: 'telephone-number-partial',
    title: 'Telephone Number (Contains) (Text)',
    description: 'Monitorees with a telephone number that contains specified digits',
    type: 'search',
  },

  /* SELECT FILTER OPTIONS */
  {
    name: 'monitoring-plan',
    title: 'Monitoring Plan (Select)',
    description: 'Monitoree monitoring plan',
    type: 'select',
    options: [
      'None',
      'Daily active monitoring',
      'Self-monitoring with public health supervision',
      'Self-monitoring with delegated supervision',
      'Self-observation',
      '',
    ],
  },
  {
    name: 'preferred-contact-method',
    title: 'Preferred Reporting Method (Select)',
    description: 'Monitorees preferred reporting method',
    type: 'select',
    options: ['Unknown', 'E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message', 'Opt-out', ''],
  },
  {
    name: 'preferred-contact-time',
    title: 'Preferred Contact Time (Select)',
    description: 'Monitoree preferred contact time',
    type: 'select',
    options: ['Morning', 'Afternoon', 'Evening', ''],
  },
  {
    name: 'primary-language',
    title: 'Primary Language (Select)',
    description: 'Monitoree primary language',
    type: 'select',
    options: [], // populated asynchronously in the AdvancedFilter component
  },
  {
    name: 'risk-exposure',
    title: 'Exposure Risk Assessment (Select)',
    description: 'Monitoree exposure risk assessment',
    type: 'select',
    options: ['High', 'Medium', 'Low', 'No Identified Risk', ''],
  },
  {
    name: 'flagged-for-follow-up',
    title: 'Flagged for Follow-up (Select)',
    description: 'Monitoree flagged for follow-up',
    type: 'select',
    options: ['Any Reason', 'Deceased', 'Duplicate', 'High-Risk', 'Hospitalized', 'In Need of Follow-up', 'Lost to Follow-up', 'Needs Interpretation', 'Quality Assurance', 'Other'],
    tooltip: 'This will return monitorees that are flagged for follow-up for the selected reason. To return all montitorees flagged for follow-up, select the “Any Reason” option.'
  },

  /* NUMBER FILTER OPTIONS */
  {
    name: 'age',
    title: 'Age (Number)',
    description: 'Current Monitoree Age',
    type: 'number',
    allowRange: true,
  },
  {
    name: 'manual-contact-attempts',
    title: 'Manual Contact Attempts (Number)',
    description: 'All records with the specified number of manual contact attempts',
    type: 'number',
    options: ['Successful', 'Unsuccessful', 'All'],
  },

  /* DATE FILTER OPTIONS */
  {
    name: 'enrolled',
    title: 'Enrolled (Date)',
    description: 'Monitorees enrolled in system during specified date range',
    type: 'date',
  },
  {
    name: 'latest-report',
    title: 'Latest Report (Date)',
    description: 'Monitorees with latest report during specified date range',
    type: 'date',
  },
  {
    name: 'last-date-exposure',
    title: 'Last Date of Exposure (Date)',
    description: 'Monitorees who have a last date of exposure during specified date range',
    type: 'date',
  },
  {
    name: 'symptom-onset',
    title: 'Symptom Onset (Date)',
    description: 'Monitorees who have a symptom onset date during specified date range',
    type: 'date',
  },

  /* RELATIVE DATE FILTER OPTIONS */
  {
    name: 'enrolled-relative',
    title: 'Enrolled (Relative Date)',
    description: 'Monitorees enrolled in system during specified date range (relative to the current date)',
    type: 'relative',
    hasTimestamp: true,
  },
  {
    name: 'latest-report-relative',
    title: 'Latest Report (Relative Date)',
    description: 'Monitorees with latest report during specified date range (relative to the current date)',
    type: 'relative',
    hasTimestamp: true,
  },
  {
    name: 'last-date-exposure-relative',
    title: 'Last Date of Exposure (Relative Date)',
    description: 'Monitorees who have a last date of exposure during specified date range (relative to the current date)',
    type: 'relative',
    hasTimestamp: false,
  },
  {
    name: 'symptom-onset-relative',
    title: 'Symptom Onset (Relative Date)',
    description: 'Monitorees who have a symptom onset date during specified date range (relative to the current date)',
    type: 'relative',
    hasTimestamp: false,
  },

  /* RELATIVE DATE FILTER OPTIONS */
  {
    name: 'enrolled-relative',
    title: 'Enrolled (Relative Date)',
    description: 'Monitorees enrolled in system during specified date range (relative to the current date)',
    type: 'relative',
    hasTimestamp: true
  },
  {
    name: 'latest-report-relative',
    title: 'Latest Report (Relative Date)',
    description: 'Monitorees with latest report during specified date range (relative to the current date)',
    type: 'relative',
    hasTimestamp: true
  },
  {
    name: 'last-date-exposure-relative',
    title: 'Last Date of Exposure (Relative Date)',
    description: 'Monitorees who have a last date of exposure during specified date range (relative to the current date)',
    type: 'relative',
    hasTimestamp: false
  },
  {
    name: 'symptom-onset-relative',
    title: 'Symptom Onset (Relative Date)',
    description: 'Monitorees who have a symptom onset date during specified date range (relative to the current date)',
    type: 'relative',
    hasTimestamp: false
  },

  /* MULTI FILTER OPTIONS */
  {
    name: 'lab-result',
    title: 'Lab Result (Multi-select)',
    description: 'Monitorees with specified Lab Result criteria',
    type: 'multi',
    tooltip: 'Returns records that contain at least one Lab Result entry that meets all user-specified criteria (e.g., searching for a specific Lab Test Type and Report Date will only return records containing at least one Lab Result entry with matching values in both fields).',
    fields: [
      {
        name: 'result',
        title: 'result',
        type: 'select',
        options: ['positive', 'negative', 'indeterminate', 'other']
      },
      {
        name: 'lab-type',
        title: 'test type',
        type: 'select',
        options: ['PCR', 'Antigen', 'Total Antibody', 'IgG Antibody', 'IgM Antibody', 'IgA Antibody', 'Other']
      },
      {
        name: 'specimen-collection',
        title: 'specimen collection date',
        type: 'date'
      },
      {
        name: 'report',
        title: 'report date',
        type: 'date'
      }
    ]
  },
  {
    name: 'vaccination',
    title: 'Vaccination (Multi-select)',
    description: 'Monitorees with specified Vaccination criteria',
    type: 'multi',
    tooltip: 'Returns records that contain at least one Vaccination entry that meets all user-specified criteria (e.g., searching for a specific Vaccination Product Name and Administration Date will only return records containing at least one Vaccination entry with matching values in both fields).',
    fields: [
      {
        name: 'vaccine-group',
        title: 'vaccine group',
        type: 'select',
        options: ['COVID-19']
      },
      {
        name: 'product-name',
        title: 'product name',
        type: 'select',
        options: ['Moderna COVID-19 Vaccine', 'Pfizer-BioNTech COVID-19 Vaccine', 'Janssen (J&J) COVID-19 Vaccine', 'Unknown']
      },
      {
        name: 'administration-date',
        title: 'administration date',
        type: 'date'
      },
      {
        name: 'dose-number',
        title: 'dose number',
        type: 'select',
        options: ['', '1', '2', 'Unknown']
      }
    ]
  }
]
