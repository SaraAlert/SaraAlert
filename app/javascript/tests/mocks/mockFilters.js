import moment from 'moment';
import { advancedFilterOptions } from '../../data/advancedFilterOptions';

/* BOOLEAN TYPE MOCK FILTERS */
const mockFilterMonitoringStatusTrue = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'monitoring-status'),
  numberOption: null,
  relativeOption: null,
  value: true
}

const mockFilterMonitoringStatusFalse = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'monitoring-status'),
  numberOption: null,
  relativeOption: null,
  value: false
}

const mockFilterSevenDayQuarantine = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'seven-day-quarantine'),
  numberOption: null,
  relativeOption: null,
  value: false
}

/* SELECT TYPE MOCK FILTERS */
const mockFilterPreferredContactTime = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'preferred-contact-time'),
  numberOption: null,
  relativeOption: null,
  value: 'Morning'
}

/* NUMBER TYPE MOCK FILTERS */
const mockFilterAgeEqual = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'age'),
  numberOption: 'equal',
  relativeOption: null,
  value: 0
}

const mockFilterAgeBetween = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'age'),
  numberOption: 'between',
  relativeOption: null,
  value: {firstBound: 20, secondBound: 30}
}

const mockFilterManualContactAttemptsEqual = {
  additionalFilterOption: 'Successful',
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'manual-contact-attempts'),
  numberOption: 'equal',
  relativeOption: null,
  value: 0
}

const mockFilterManualContactAttemptsLessThan = {
  additionalFilterOption: 'All',
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'manual-contact-attempts'),
  numberOption: 'less-than',
  relativeOption: null,
  value: 2
}

/* DATE TYPE MOCK FILTERS */
const mockFilterEnrolledDateWithin = {
  additionalFilterOption: null,
  dateOption: 'within',
  filterOption: advancedFilterOptions.find(filter => filter.name === 'enrolled'),
  numberOption: null,
  relativeOption: null,
  value: { 
    start: moment(new Date()).subtract(3,'d').format('YYYY-MM-DD'),
    end: moment(new Date()).format('YYYY-MM-DD')
  }
}

const mockFilterEnrolledDateBefore = {
  additionalFilterOption: null,
  dateOption: 'before',
  filterOption: advancedFilterOptions.find(filter => filter.name === 'enrolled'),
  numberOption: null,
  relativeOption: null,
  value: '2020-12-30'
}

/* RELATIVE TYPE MOCK FILTERS */
const mockFilterLatestReportRelativeToday = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'latest-report-relative'),
  numberOption: null,
  relativeOption: 'today',
  value: 'today'
}

const mockFilterLatestReportRelativeYesterday = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'latest-report-relative'),
  numberOption: null,
  relativeOption: 'yesterday',
  value: 'yesterday'
}

const mockFilterLatestReportRelativeCustomPast = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'latest-report-relative'),
  numberOption: null,
  relativeOption: 'custom',
  value: {
    operator: 'less-than',
    number: 1,
    unit: 'days',
    when: 'past'
  }
}

const mockFilterLatestReportRelativeCustomFuture = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'latest-report-relative'),
  numberOption: null,
  relativeOption: 'custom',
  value: {
    operator: 'more-than',
    number: 2,
    unit: 'weeks',
    when: 'next'
  }
}

const mockFilterSymptomOnsetRelativeCustomPast = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'symptom-onset-relative'),
  numberOption: null,
  relativeOption: 'custom',
  value: {
    operator: 'less-than',
    number: 1,
    unit: 'days',
    when: 'past'
  }
}

/* SEARCH TYPE MOCK FILTERS */
const mockFilterAddressForeignEmpty = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'address-foreign'),
  numberOption: null,
  relativeOption: null,
  value: ''
}

const mockFilterAddressForeign = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'address-foreign'),
  numberOption: null,
  relativeOption: null,
  value: '42 Wallaby Way'
}

/* MULTI TYPE MOCK FILTERS */
const mockFilterLabResults = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: advancedFilterOptions.find(filter => filter.name === 'lab-result'),
  numberOption: null,
  relativeOption: null,
  value: [ {name: 'result', value: 'positive'} ]
}

/* MOCK SAVED FILTERS */
const mockFilter1 = {
  contents: [ mockFilterAddressForeign ],
  created_at: '2021-01-11T14:04:32.994Z',
  id: 2,
  name: 'my new filter',
  updated_at: '2021-01-11T14:04:32.994Z',
  user_id: 15
}

const mockFilter2 = {
  contents: [ mockFilterMonitoringStatusFalse, mockFilterEnrolledDateBefore],
  created_at: '2020-11-11T02:43:56.234Z',
  id: 1,
  name: 'my filter',
  updated_at: '2020-12-10T19:31:12.784Z',
  user_id: 15
}

const mockSavedFilters = [ mockFilter1, mockFilter2 ]

export {
  mockFilterMonitoringStatusTrue,
  mockFilterMonitoringStatusFalse,
  mockFilterSevenDayQuarantine,
  mockFilterPreferredContactTime,
  mockFilterAgeEqual,
  mockFilterAgeBetween,
  mockFilterManualContactAttemptsEqual,
  mockFilterManualContactAttemptsLessThan,
  mockFilterEnrolledDateWithin,
  mockFilterEnrolledDateBefore,
  mockFilterLatestReportRelativeToday,
  mockFilterLatestReportRelativeYesterday,
  mockFilterLatestReportRelativeCustomPast,
  mockFilterSymptomOnsetRelativeCustomPast,
  mockFilterLatestReportRelativeCustomFuture,
  mockFilterAddressForeignEmpty,
  mockFilterAddressForeign,
  mockFilterLabResults,
  mockFilter1,
  mockFilter2,
  mockSavedFilters
}