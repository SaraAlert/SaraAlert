const mockFilterOptions1 = {
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

const mockFilterOptions2 = {
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
  value: false,
}

const mockFilterOptions3 = {
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
  value: '2020-12-30',
}

const mockFilter1 = {
  contents: [ mockFilterOptions1 ],
  created_at: '2021-01-11T14:04:32.994Z',
  id: 2,
  name: 'my new filter',
  updated_at: '2021-01-11T14:04:32.994Z',
  user_id: 15
}

const mockFilter2 = {
  contents: [ mockFilterOptions2, mockFilterOptions3 ],
  created_at: '2020-11-11T02:43:56.234Z',
  id: 1,
  name: 'my filter',
  updated_at: '2020-12-10T19:31:12.784Z',
  user_id: 15
}

const mockSavedFilters = [ mockFilter1, mockFilter2 ]

export {
  mockFilterOptions1,
  mockFilterOptions2,
  mockFilterOptions3,
  mockFilter1,
  mockFilter2,
  mockSavedFilters
}