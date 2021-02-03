import moment from 'moment';

const mockFilterDefaultBoolOption = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: {
    description: 'Monitorees who are currently under active monitoring',
    name: 'monitoring-status',
    title: 'Active Monitoring (Boolean)',
    type: 'boolean'
  },
  numberOption: null,
  relativeOption: null,
  value: true
}

const mockFilterBoolOption = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: {
    description: 'Monitorees who are currently under active monitoring',
    name: 'monitoring-status',
    title: 'Active Monitoring (Boolean)',
    type: 'boolean'
  },
  numberOption: null,
  relativeOption: null,
  value: false
}

const mockFilterOptionsOption = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: {
    name: 'preferred-contact-time',
    title: 'Preferred Contact Time (Select)',
    description: 'Monitoree preferred contact time',
    type: 'option',
    options: ['Morning', 'Afternoon', 'Evening', '']
  },
  numberOption: null,
  relativeOption: null,
  value: 'Morning'
}

const mockFilterDefaultNumberOption = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: {
    name: 'age',
    title: 'Age (Number)',
    description: 'Current Monitoree Age',
    type: 'number',
    allowRange: true
  },
  numberOption: 'equal',
  relativeOption: null,
  value: 0
}

const mockFilterNumberOption = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: {
    name: 'age',
    title: 'Age (Number)',
    description: 'Current Monitoree Age',
    type: 'number',
    allowRange: true
  },
  numberOption: 'between',
  relativeOption: null,
  value: {firstBound: 20, secondBound: 30}
}

const mockFilterDefaultDateOption = {
  additionalFilterOption: null,
  dateOption: 'within',
  filterOption: {
    description: 'Monitorees enrolled in system during specified date range',
    name: 'enrolled',
    title: 'Enrolled (Date)',
    type: 'date'
  },
  numberOption: null,
  relativeOption: null,
  value: { 
    start: moment(new Date()).subtract(3,'d').format('YYYY-MM-DD'),
    end: moment(new Date()).format('YYYY-MM-DD')
  }
}

const mockFilterDateOption = {
  additionalFilterOption: null,
  dateOption: 'before',
  filterOption: {
    description: 'Monitorees enrolled in system during specified date range',
    name: 'enrolled',
    title: 'Enrolled (Date)',
    type: 'date'
  },
  numberOption: null,
  relativeOption: null,
  value: '2020-12-30'
}

const mockFilterDefaultRelativeOption = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: {
    name: 'latest-report-relative',
    title: 'Latest Report (Relative Date)',
    description: 'Monitorees with latest report during specified date range (relative to the current date)',
    type: 'relative',
    hasTimestamp: true
  },
  numberOption: null,
  relativeOption: 'today',
  value: null
}

const mockFilterRelativeOption = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: {
    name: 'latest-report-relative',
    title: 'Latest Report (Relative Date)',
    description: 'Monitorees with latest report during specified date range (relative to the current date)',
    type: 'relative',
    hasTimestamp: true
  },
  numberOption: null,
  relativeOption: 'yesterday',
  value: null
}

const mockFilterDefaultCustomRelativeOption = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: {
    name: 'latest-report-relative',
    title: 'Latest Report (Relative Date)',
    description: 'Monitorees with latest report during specified date range (relative to the current date)',
    type: 'relative',
    hasTimestamp: true
  },
  numberOption: null,
  relativeOption: 'custom',
  value: {
    number: 1,
    unit: 'days',
    when: 'past'
  }
}

const mockFilterCustomRelativeOption = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: {
    name: 'latest-report-relative',
    title: 'Latest Report (Relative Date)',
    description: 'Monitorees with latest report during specified date range (relative to the current date)',
    type: 'relative',
    hasTimestamp: true
  },
  numberOption: null,
  relativeOption: 'custom',
  value: {
    number: 2,
    unit: 'weeks',
    when: 'next'
  }
}

const mockFilterDefaultSearchOption = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: {
    description: 'Monitoree Address 1, Town/City, Country, Address 2, Postal Code, Address 3 or State/Province (outside USA)',
    name: 'address-foreign',
    title: 'Address (outside USA) (Text)',
    type: 'search'
  },
  numberOption: null,
  relativeOption: null,
  value: ''
}

const mockFilterSearchOption = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: {
    description: 'Monitoree Address 1, Town/City, Country, Address 2, Postal Code, Address 3 or State/Province (outside USA)',
    name: 'address-foreign',
    title: 'Address (outside USA) (Text)',
    type: 'search'
  },
  numberOption: null,
  relativeOption: null,
  value: '42 Wallaby Way'
}

const mockFilterDefaultAdditionalOption = {
  additionalFilterOption: 'Successful',
  dateOption: null,
  filterOption: {
    name: 'manual-contact-attempts',
    title: 'Manual Contact Attempts (Number)',
    description: 'All records with the specified number of manual contact attempts',
    type: 'number',
    options: ['Successful', 'Unsuccessful', 'All']
  },
  numberOption: 'equal',
  relativeOption: null,
  value: 0
}

const mockFilterAdditionalOption = {
  additionalFilterOption: 'All',
  dateOption: null,
  filterOption: {
    name: 'manual-contact-attempts',
    title: 'Manual Contact Attempts (Number)',
    description: 'All records with the specified number of manual contact attempts',
    type: 'number',
    options: ['Successful', 'Unsuccessful', 'All']
  },
  numberOption: 'less-than',
  relativeOption: null,
  value: 2
}

const mockFilterIncludesTooltip = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: {
    name: 'seven-day-quarantine',
    title: 'Candidate to Reduce Quarantine after 7 Days (Boolean)',
    description:
      'All asymptomatic records that meet CDC criteria to end quarantine after Day 7 (based on last date of exposure and most recent lab result)',
    type: 'boolean',
    tooltip:
      'This filter is based on "Options to Reduce Quarantine for Contacts of Persons with SARS-COV-2 Infection Using Symptom ' +
      'Monitoring and Diagnostic Testing" released by the CDC on December 2, 2020. For more specific information, see Appendix A in the User Guide.',
  },
  numberOption: null,
  relativeOption: null,
  value: false
}

const mockFilter1 = {
  contents: [ mockFilterSearchOption ],
  created_at: '2021-01-11T14:04:32.994Z',
  id: 2,
  name: 'my new filter',
  updated_at: '2021-01-11T14:04:32.994Z',
  user_id: 15
}

const mockFilter2 = {
  contents: [ mockFilterBoolOption, mockFilterDateOption ],
  created_at: '2020-11-11T02:43:56.234Z',
  id: 1,
  name: 'my filter',
  updated_at: '2020-12-10T19:31:12.784Z',
  user_id: 15
}

const mockSavedFilters = [ mockFilter1, mockFilter2 ]

export {
  mockFilterDefaultBoolOption,
  mockFilterBoolOption,
  mockFilterOptionsOption,
  mockFilterDefaultNumberOption,
  mockFilterNumberOption,
  mockFilterDefaultDateOption,
  mockFilterDateOption,
  mockFilterDefaultRelativeOption,
  mockFilterRelativeOption,
  mockFilterDefaultCustomRelativeOption,
  mockFilterCustomRelativeOption,
  mockFilterDefaultSearchOption,
  mockFilterSearchOption,
  mockFilterDefaultAdditionalOption,
  mockFilterAdditionalOption,
  mockFilterIncludesTooltip,
  mockFilter1,
  mockFilter2,
  mockSavedFilters
}