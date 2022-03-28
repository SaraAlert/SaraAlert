# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength

# Options for Advanced Filter
module AdvancedFilterOptions
  SUPPORTED_LANGUAGES = Languages.all_languages.values.sort_by do |lang|
    [lang[:supported].blank? ? 1 : 0,
     lang[:supported].present? && lang[:supported][:sms] && lang[:supported][:phone] && lang[:supported][:email] ? 0 : 1,
     lang[:display]]
  end.pluck(:display)

  # rubocop:disable Metrics/MethodLength
  def advanced_filter_options(current_user)
    [
      # BOOLEAN FILTER OPTIONS
      {
        name: 'continuous-exposure',
        title: 'Continuous Exposure (Boolean)',
        description: 'Monitorees who have continuous exposure enabled',
        type: 'boolean'
      },
      {
        name: 'hoh',
        title: 'Daily Reporters (Boolean)',
        description: 'Monitorees that are a Head of Household or self-reporter',
        type: 'boolean'
      },
      {
        name: 'household-member',
        title: 'Household Member (Boolean)',
        description: 'Monitorees that are in a household but not the Head of Household',
        type: 'boolean'
      },
      {
        name: 'ineligible-for-recovery-definition',
        title: 'Ineligible for any recovery definition (Boolean)',
        description: 'All isolation records ineligible to ever appear on Records Requiring Review line list',
        type: 'boolean',
        tooltip:
          'This filter will return all records in the Isolation workflow that both do not have a Symptom Onset Date and do not have a '\
          'positive lab result with a Specimen Collection Date'
      },
      {
        name: 'monitoring-status',
        title: 'Active Monitoring (Boolean)',
        description: 'Monitorees who are currently under active monitoring',
        type: 'boolean'
      },
      {
        name: 'never-responded',
        title: 'Never Reported (Boolean)',
        description: 'Monitorees who have no reports',
        type: 'boolean'
      },
      { name: 'paused', title: 'Notifications Paused (Boolean)', description: 'Monitorees who have paused notifications', type: 'boolean' },
      {
        name: 'require-interpretation',
        title: 'Requires Interpretation (Boolean)',
        description: 'Monitorees who require interpretation',
        type: 'boolean'
      },
      {
        name: 'responded-today',
        title: 'Reported in last 24 hours (Boolean)',
        description: 'Monitorees who had a report created in the last 24 hours',
        type: 'boolean'
      },
      {
        name: 'sent-today',
        title: 'Sent Notification in last 24 hours (Boolean)',
        description: 'Monitorees who have been sent a notification in the last 24 hours',
        type: 'boolean'
      },
      {
        name: 'sms-blocked',
        title: 'SMS Blocked (Boolean)',
        description: 'Monitorees that have blocked SMS communications with Sara Alert',
        type: 'boolean',
        tooltip:
          'This filter will return monitorees that have texted “STOP” in response to a Sara Alert text message and cannot receive messages through '\
          'SMS Preferred Reporting Methods until they text "START".'
      },
      {
        name: 'unenrolled-close-contact',
        title: 'Unenrolled Close Contact (Boolean)',
        description: 'All records with at least one unenrolled Close Contact',
        type: 'boolean'
      },

      # SEARCH FILTER OPTIONS
      {
        name: 'close-contact-with-known-case-id',
        title: 'Close Contact with a Known Case ID (Text)',
        description: 'Monitorees with a known exposure to a probable or confirmed case ID',
        type: 'search',
        options: ['Exact Match', 'Contains'],
        tooltip: {
          'Exact Match':
            'Returns records with an exact match to one or more of the user-entered search values when the known Case ID is specified for '\
            'monitorees with “Close Contact with a Known Case”. Use commas to separate multiple values (ex: “12, 45” will return records where known Case ID '\
            'is “45” or “45, 12”). Leaving this field blank will return monitorees with missing and null values.',
          Contains:
            'Returns records that contain a user-entered search value when the known Case ID is specified for monitorees with “Close Contact with '\
            'a Known Case”. Use commas to separate multiple values (ex: “12, 45” will return records where known Case ID is “123, 90” or “12” or “1451). '\
            'Leaving this field blank will return monitorees with missing and null values.'
        }
      },
      {
        name: 'email',
        title: 'Primary Contact Email (Text)',
        description: 'Monitoree primary contact email address',
        type: 'search'
      },
      {
        name: 'sara-id',
        title: 'Sara Alert ID (Text)',
        description: 'Monitoree Sara Alert ID',
        type: 'search'
      },
      {
        name: 'telephone',
        title: 'Primary Contact Telephone Number (Text)',
        description: 'Monitorees with a primary contact telephone number',
        type: 'search',
        options: ['Exact Match', 'Contains']
      },

      # SELECT FILTER OPTIONS
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
          ''
        ]
      },
      {
        name: 'preferred-contact-method',
        title: 'Primary Contact Preferred Reporting Method (Select)',
        description: 'Monitoree primary contact preferred reporting method',
        type: 'select',
        options: ['Unknown', 'E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message', 'Opt-out', '']
      },
      {
        name: 'preferred-contact-time',
        title: 'Primary Contact Preferred Contact Time (Select)',
        description: 'Monitoree primary contact preferred contact time',
        type: 'select',
        options: ['Early Morning', 'Morning', 'Afternoon', 'Evening', 'Late Night', ''],
        tooltip: ['Early Morning (Midnight - 7:00)', 'Morning (8:00 - 11:00)', 'Afternoon (Noon - 15:00)', 'Evening (16:00 - 19:00)',
                  'Late Night (20:00 - 23:00)']
      },
      {
        name: 'primary-language',
        title: 'Primary Language (Select)',
        description: 'Monitoree primary language',
        type: 'select',
        options: SUPPORTED_LANGUAGES
      },
      {
        name: 'risk-exposure',
        title: 'Exposure Risk Assessment (Select)',
        description: 'Monitoree exposure risk assessment',
        type: 'select',
        options: ['High', 'Medium', 'Low', 'No Identified Risk', '']
      },
      {
        name: 'flagged-for-follow-up',
        title: 'Flagged for Follow-up (Select)',
        description: 'Monitoree flagged for follow-up',
        type: 'select',
        options: [
          'Any Reason',
          'Deceased',
          'Duplicate',
          'High-Risk',
          'Hospitalized',
          'In Need of Follow-up',
          'Lost to Follow-up',
          'Needs Interpretation',
          'Quality Assurance',
          'Refused Active Monitoring',
          'Other'
        ],
        tooltip:
          'This will return monitorees that are flagged for follow-up for the selected reason. To return all montitorees flagged for follow-up, '\
          'select the “Any Reason” option.'
      },

      # MULTI-SELECT OPTIONS
      {
        name: 'assigned-user',
        title: 'Assigned User (Multi-select)',
        description: 'Monitorees who have a specific assigned user',
        type: 'multi',
        options: current_user.patients.where.not(assigned_user: nil).pluck(:assigned_user).uniq.sort.map { |option| { label: option, value: option } },
        tooltip:
          'If multiple Assigned Users are selected, records assigned to any of those users will be returned. Only Assigned User values currently listed '\
          'in a record are selectable. Leaving this field blank will not filter out any monitorees.'
      },
      {
        name: 'contact-type',
        title: 'Primary Contact Relationship (Multi-select)',
        description: 'Monitoree primary contact relationship',
        type: 'multi',
        options: [
          'Self',
          'Parent/Guardian',
          'Spouse/Partner',
          'Caregiver',
          'Healthcare Provider',
          'Facility Representative',
          'Group Home Manager/Administrator',
          'Surrogate/Proxy',
          'Other',
          'Unknown'
        ].map { |option| { label: option, value: option } },
        tooltip:
          'If multiple Contact Relationships are selected, records with any of those options as their Primary Contact Relationship will be returned. Leaving '\
          'this field blank will not filter out any monitorees.'
      },
      {
        name: 'jurisdiction',
        title: 'Jurisdiction (Multi-select)',
        description: 'Monitorees of a specific jurisdiction',
        type: 'multi',
        options: current_user.jurisdiction.subtree.pluck(:id, :path).to_h.map { |key, value| { label: value, value: key } },
        tooltip:
          'If multiple Jurisdictions are selected, records assigned to any of those Jurisdictions will be returned. All Jurisdictions that you have access to '\
          'are selectable. Leaving this field blank will not filter out any monitorees.'
      },

      # NUMBER FILTER OPTIONS
      {
        name: 'age',
        title: 'Age (Number)',
        description: 'Current Monitoree Age',
        type: 'number',
        allow_range: true,
        support_blank: true
      },
      {
        name: 'manual-contact-attempts',
        title: 'Manual Contact Attempts (Number)',
        description: 'All records with the specified number of manual contact attempts',
        type: 'number',
        options: %w[Successful Unsuccessful All]
      },

      # DATE FILTER OPTIONS
      {
        name: 'enrolled',
        title: 'Enrolled (Date)',
        description: 'Monitorees enrolled in system during specified date range',
        type: 'date',
        support_blank: false
      },
      {
        name: 'latest-report',
        title: 'Latest Report (Date)',
        description: 'Monitorees with latest report during specified date range',
        type: 'date',
        support_blank: true
      },
      {
        name: 'last-date-exposure',
        title: 'Last Date of Exposure (Date)',
        description: 'Monitorees who have a last date of exposure during specified date range',
        type: 'date',
        support_blank: true
      },
      {
        name: 'symptom-onset',
        title: 'Symptom Onset (Date)',
        description: 'Monitorees who have a Symptom Onset Date during specified date range',
        type: 'date',
        support_blank: true
      },

      # RELATIVE DATE FILTER OPTIONS
      {
        name: 'enrolled-relative',
        title: 'Enrolled (Relative Date)',
        description: 'Monitorees enrolled in system during specified date range (relative to the current date)',
        type: 'relative',
        has_timestamp: true
      },
      {
        name: 'latest-report-relative',
        title: 'Latest Report (Relative Date)',
        description: 'Monitorees with latest report during specified date range (relative to the current date)',
        type: 'relative',
        has_timestamp: true
      },
      {
        name: 'last-date-exposure-relative',
        title: 'Last Date of Exposure (Relative Date)',
        description: 'Monitorees who have a last date of exposure during specified date range (relative to the current date)',
        type: 'relative',
        has_timestamp: false
      },
      {
        name: 'symptom-onset-relative',
        title: 'Symptom Onset (Relative Date)',
        description: 'Monitorees who have a Symptom Onset Date during specified date range (relative to the current date)',
        type: 'relative',
        has_timestamp: false
      },

      # COMBINATION OPTIONS
      {
        name: 'address',
        title: 'Address (Combination)',
        description: 'Monitorees with specified address',
        type: 'combination',
        tooltip: 'Leaving this field blank will return monitorees with blank address fields.',
        fields: [
          {
            name: 'address-usa',
            title: 'within USA',
            type: 'search'
          },
          {
            name: 'address-foreign',
            title: 'outside USA',
            type: 'search'
          }
        ]
      },
      {
        name: 'common-exposure-cohort',
        title: 'Common Exposure Cohort (Combination)',
        description: 'Monitorees with specified Common Exposure Cohort criteria',
        type: 'combination',
        tooltip:
          'Returns records that contain at least one Common Exposure Cohort entry that meets all user-specified criteria (e.g., searching for a '\
          'specific Common Exposure Cohort Type and Name/Description will only return records containing at least one Common Exposure Cohort entry '\
          'with matching values in both fields). Leaving these fields blank will not filter out any monitorees.',
        fields: [
          {
            name: 'cohort-type',
            title: 'cohort type',
            type: 'multi',
            options: [
              'Adult Congregate Living Facility',
              'Child Care Facility',
              'Community Event or Mass Gathering',
              'Correctional Facility',
              'Group Home',
              'Healthcare Facility',
              'Place of Worship',
              'School or University',
              'Shelter',
              'Substance Abuse Treatment Center',
              'Workplace',
              'Other'
            ].map { |option| { label: option, value: option } }
          },
          {
            name: 'cohort-name',
            title: 'cohort name/description',
            type: 'multi',
            options: current_user.jurisdiction.all_common_exposure_cohort_names.map { |option| { label: option, value: option } }
          },
          {
            name: 'cohort-location',
            title: 'cohort location',
            type: 'multi',
            options: current_user.jurisdiction.all_common_exposure_cohort_locations.map { |option| { label: option, value: option } }
          }
        ]
      },
      {
        name: 'lab-result',
        title: 'Lab Result (Combination)',
        description: 'Monitorees with specified Lab Result criteria',
        type: 'combination',
        tooltip:
          'Returns records that contain at least one Lab Result entry that meets all user-specified criteria (e.g., searching for a '\
          'specific Lab Test Type and Report Date will only return records containing at least one Lab Result entry with matching '\
          'values in both fields).',
        fields: [
          {
            name: 'result',
            title: 'result',
            type: 'select',
            options: ['positive', 'negative', 'indeterminate', 'other', '']
          },
          {
            name: 'lab-type',
            title: 'test type',
            type: 'select',
            options: ['PCR', 'Antigen', 'Total Antibody', 'IgG Antibody', 'IgM Antibody', 'IgA Antibody', 'Other', '']
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
        name: 'name',
        title: 'Name (Combination)',
        description: 'Monitoree name',
        type: 'combination',
        fields: [
          {
            name: 'first-name',
            title: 'first',
            type: 'search'
          },
          {
            name: 'last-name',
            title: 'last',
            type: 'search'
          },
          {
            name: 'middle-name',
            title: 'middle',
            type: 'search'
          }
        ]
      },
      {
        name: 'vaccination',
        title: 'Vaccination (Combination)',
        description: 'Monitorees with specified Vaccination criteria',
        type: 'combination',
        tooltip:
          'Returns records that contain at least one Vaccination entry that meets all user-specified criteria (e.g., searching for a specific '\
          'Vaccination Product Name and Administration Date will only return records containing at least one Vaccination entry with matching '\
          'values in both fields).',
        fields: [
          {
            name: 'vaccine-group',
            title: 'vaccine group',
            type: 'select',
            options: Vaccine.group_name_options
          },
          {
            name: 'product-name',
            title: 'product name',
            type: 'select',
            options: Vaccine.all_product_name_options
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
            options: Vaccine::DOSE_OPTIONS.filter { |option| !option.nil? }.sort
          }
        ]
      }
    ].freeze
  end
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/ModuleLength
