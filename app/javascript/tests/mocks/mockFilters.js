import moment from 'moment';

const mockFilterOptions = [
  {
    name: 'blue-eyes',
    title: 'Blue Eyes (Boolean)',
    description: 'Monitorees who have blue eyes',
    type: 'boolean',
  },
  {
    name: 'tv-show',
    title: 'Television Show (Text)',
    description: 'Monitoree favorite television show',
    type: 'search',
    tooltip: ['Examples', 'Parks & Rec', 'Grace & Frankie'],
  },
  {
    name: 'occupation',
    title: 'Occpation (Text)',
    description: 'Monitorees with a certain occupation',
    type: 'search',
    options: ['Full Time', 'Part Time', 'Unemployed'],
    tooltip: {
      'Full Time': '40+ hours a week',
      'Part Time': 'Under 40 hours a week',
      Unemployed: 'No job',
    },
  },
  {
    name: 'water-consumption',
    title: 'Water Consumption (Number)',
    description: 'All records with the specified number of water consumption',
    type: 'number',
    allow_range: true,
  },
  {
    name: 'writing-utensil',
    title: 'Writing Utensil (Select)',
    description: 'Monitoree favorite writing utensil',
    type: 'select',
    options: ['Pen', 'Pencil', 'Marker', 'Crayon', 'Highlighter', 'Other'],
    tooltip: 'Writing is fun!',
  },
  {
    name: 'pets',
    title: 'Pet Types (Multi-select)',
    description: 'Monitorees with certain pet types',
    type: 'multi',
    options: [
      { label: 'Dog', value: 'Dog' },
      { label: 'Cat', value: 'Cat' },
      { label: 'Bird', value: 'Bird' },
      { label: 'Horse', value: 'Horse' },
      { label: 'Fish', value: 'Fish' },
      { label: 'Goat', value: 'Goat' },
      { label: 'Hamster', value: 'Hamster' },
    ],
    tooltip: 'Furbabies are the best!',
  },
  {
    name: 'birthday',
    title: 'Birthday (Date)',
    description: 'Monitoree birthday (relative to the current date)',
    type: 'date',
  },
  {
    name: 'birthday-relative',
    title: 'Birthday (Relative Date)',
    description: 'Monitoree birthday (relative to the current date)',
    type: 'relative',
    has_timestamp: false,
  },
  {
    name: 'emergency-contact',
    title: 'Emergency Contact (Combination)',
    description: 'Monitoree emergency contact',
    type: 'combination',
    fields: [
      {
        name: 'ec-name',
        title: 'Contact Name',
        type: 'search',
      },
      {
        name: 'ec-relationship',
        title: 'Contact Relationship',
        type: 'select',
        options: ['Parent', 'Sibling', 'Child', 'Friend', 'Other'],
      },
      {
        name: 'ec-dob',
        title: 'Contact Date of Birth',
        type: 'date',
      },
      {
        name: 'ec-time',
        title: 'Contact Time',
        type: 'multi',
        options: [
          { label: 'Morning', value: 'Morning' },
          { label: 'Afternoon', value: 'Afternoon' },
          { label: 'Evening', value: 'Evening' },
        ],
      },
      {
        name: 'ec-notes',
        title: 'Contact Notes',
        type: 'search',
      },
    ],
  },
];

const additionalMultiOption = {
  name: 'holidays',
  title: 'Holidays (Multi-select)',
  description: 'Monitorees that celebrate certain holidays',
  type: 'multi',
  options: [
    { label: 'Christmas', value: 'Christmas' },
    { label: 'Thanksgiving', value: 'Thanksgiving' },
    { label: 'Passover', value: 'Passover' },
    { label: 'Hanukkah', value: 'Hanukkah' },
  ],
};

const mockBlankContents = {
  filterOption: null,
};

const mockBooleanContents = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: mockFilterOptions.find(filter => filter.type === 'boolean'),
  numberOption: null,
  relativeOption: null,
  value: true,
};

const mockSearchContents = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: mockFilterOptions.find(filter => filter.type === 'search' && !filter.additionalFilterOption),
  numberOption: null,
  relativeOption: null,
  value: '',
};

const additionalFilterOption = mockFilterOptions.find(filter => filter.type !== 'select' && filter.options);
const mockAdditionalFilterContents = {
  additionalFilterOption: additionalFilterOption.options[0],
  dateOption: null,
  filterOption: additionalFilterOption,
  numberOption: null,
  relativeOption: null,
  value: '',
};

const selectOption = mockFilterOptions.find(filter => filter.type === 'select');
const mockSelectContents = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: selectOption,
  numberOption: null,
  relativeOption: null,
  value: selectOption.options[0],
};

const mockNumberContents = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: mockFilterOptions.find(filter => filter.type === 'number'),
  numberOption: 'equal',
  relativeOption: null,
  value: 0,
};

const mockDateContents = {
  additionalFilterOption: null,
  dateOption: 'within',
  filterOption: mockFilterOptions.find(filter => filter.type === 'date'),
  numberOption: null,
  relativeOption: null,
  value: { start: moment(new Date()).subtract(3, 'd').format('YYYY-MM-DD'), end: moment(new Date()).format('YYYY-MM-DD') },
};

const mockRelativeContents = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: mockFilterOptions.find(filter => filter.type === 'relative'),
  numberOption: null,
  relativeOption: 'today',
  value: 'today',
};

const mockMultiContents = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: mockFilterOptions.find(filter => filter.type === 'multi'),
  numberOption: null,
  relativeOption: null,
  value: [],
};

const combinationOption = mockFilterOptions.find(filter => filter.type === 'combination');
const mockCombinationContents = {
  additionalFilterOption: null,
  dateOption: null,
  filterOption: combinationOption,
  numberOption: null,
  relativeOption: null,
  value: [{ name: combinationOption.fields[0].name, value: getDefaultCombinationValues(combinationOption.fields[0]) }],
};

function getDefaultCombinationValues(field) {
  switch (field.type) {
    case 'search':
      return '';
    case 'select':
      return field.options[0];
    case 'date':
      return { when: 'before', date: moment(new Date()).format('YYYY-MM-DD') };
    case 'multi':
      return [];
  }
}

const mockFilter1 = {
  contents: [mockBooleanContents, mockDateContents],
  created_at: '2021-01-11T14:04:32.994Z',
  id: 2,
  name: 'my new filter',
  updated_at: '2021-01-11T14:04:32.994Z',
  user_id: 15,
};

const mockFilter2 = {
  contents: [mockBooleanContents, mockSearchContents, mockNumberContents, mockMultiContents, mockBlankContents],
  created_at: '2020-11-11T02:43:56.234Z',
  id: 1,
  name: 'my filter',
  updated_at: '2020-12-10T19:31:12.784Z',
  user_id: 15,
};

const mockSavedFilters = [mockFilter1, mockFilter2];

export {
  mockFilterOptions,
  additionalMultiOption,
  mockBlankContents,
  mockBooleanContents,
  mockSearchContents,
  mockAdditionalFilterContents,
  mockSelectContents,
  mockNumberContents,
  mockDateContents,
  mockRelativeContents,
  mockMultiContents,
  mockCombinationContents,
  mockFilter1,
  mockFilter2,
  mockSavedFilters,
  getDefaultCombinationValues,
};
