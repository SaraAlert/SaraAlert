import React from 'react'
import { shallow } from 'enzyme';
import _ from 'lodash';
import moment from 'moment';
import ReactTooltip from 'react-tooltip';
import { Button, ButtonGroup, Dropdown, Form, Modal, OverlayTrigger, ToggleButton } from 'react-bootstrap';
import AdvancedFilter from '../../../components/public_health/query/AdvancedFilter.js'
import DateInput from '../../../components/util/DateInput.js'
import {
  mockFilter1,
  mockFilter2,
  mockFilterDefaultSearchOption,
  mockFilterSearchOption,
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
  mockFilterDefaultAdditionalOption,
  mockFilterAdditionalOption,
  mockFilterIncludesTooltip,
  mockSavedFilters
} from '../../mocks/mockFilters'

const advancedFilterUpdateMock = jest.fn();
const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";
const numberOptionValues = [ 'less-than', 'less-than-equal', 'equal', 'greater-than-equal', 'greater-than', 'between' ];
const numberOptionValuesText = [ 'less than', 'less than or equal to', 'equal to', 'greater than or equal to', 'greater than', 'between' ];
const dateOptionValues = [ 'within', 'before', 'after' ];
const relativeOptionValues = [ 'today', 'tomorrow', 'yesterday', 'custom' ];
const relativeOptionValuesText = [ 'today', 'tomorrow', 'yesterday', 'more...' ];
const relativeOptionWhenValues = [ 'past', 'next' ];
const relativeOptionUnitValues = [ 'day(s)', 'week(s)', 'month(s)' ];

function getWrapper() {
  return shallow(<AdvancedFilter workflow={'exposure'} advancedFilterUpdate={advancedFilterUpdateMock} updateStickySettings={true}
    authenticity_token={authyToken} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('AdvancedFilter', () => {
  it('Properly renders all Advanced Filter dropdown and button without any saved filters', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(OverlayTrigger).exists()).toBeTruthy();
    expect(wrapper.find(Button).exists()).toBeTruthy();
    expect(wrapper.find(Button).find('i').hasClass('fa-microscope')).toBeTruthy();
    expect(wrapper.find(Button).text()).toEqual('Advanced Filter');
    expect(wrapper.find(Dropdown).exists()).toBeTruthy();
    expect(wrapper.find(Dropdown.Item).length).toEqual(1);
    expect(wrapper.find(Dropdown.Item).text()).toEqual('New filter');
    expect(wrapper.find(Dropdown.Item).find('i').hasClass('fa-plus')).toBeTruthy();
    expect(wrapper.find(Dropdown.Divider).length).toEqual(1);
    expect(wrapper.find(Dropdown.Header).length).toEqual(1);
    expect(wrapper.find(Dropdown.Header).text()).toEqual('Saved Filters');
    expect(wrapper.find(Modal).exists()).toBeFalsy();
  });

  it('Properly renders all Advanced Filter dropdown and button with saved filters', () => {
    const wrapper = getWrapper();
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    expect(wrapper.find(OverlayTrigger).exists()).toBeTruthy();
    expect(wrapper.find(Button).exists()).toBeTruthy();
    expect(wrapper.find(Button).find('i').hasClass('fa-microscope')).toBeTruthy();
    expect(wrapper.find(Button).text()).toEqual('Advanced Filter');
    expect(wrapper.find(Dropdown).exists()).toBeTruthy();
    expect(wrapper.find(Dropdown.Item).length).toEqual(3);
    expect(wrapper.find(Dropdown.Item).at(0).text()).toEqual('New filter');
    expect(wrapper.find(Dropdown.Item).at(0).find('i').hasClass('fa-plus')).toBeTruthy();
    expect(wrapper.find(Dropdown.Divider).length).toEqual(1);
    expect(wrapper.find(Dropdown.Header).length).toEqual(1);
    expect(wrapper.find(Dropdown.Header).text()).toEqual('Saved Filters');
    mockSavedFilters.forEach(function(filter, index) {
      expect(wrapper.find(Dropdown.Item).at(index+1).text()).toEqual(filter.name);
    });
    expect(wrapper.find(Modal).exists()).toBeFalsy();
  });

  it('Clicking "Advanced Filter" button opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Clicking "New Filter" dropdown option opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Dropdown.Item).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Clicking a saved filter in dropdown opens modal', () => {
    const wrapper = getWrapper();
    wrapper.setState({ savedFilters: mockSavedFilters });
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Dropdown.Item).at(1).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Renders all main modal components with no active filter set', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Header).text()).toEqual('Advanced Filter: untitled');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-save').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-save').text()).toEqual('Save');
    expect(wrapper.find('#advanced-filter-save').find('i').hasClass('fa-save')).toBeTruthy();
    expect(wrapper.find('#advanced-filter-update').exists()).toBeFalsy();
    expect(wrapper.find('#advanced-filter-delete').exists()).toBeFalsy();
    expect(wrapper.find('#advanced-filter-reset').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-reset').text()).toEqual('Reset');
    expect(wrapper.find('#advanced-filter-apply').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-apply').text()).toEqual('Apply');
    expect(wrapper.find('.advanced-filter-statement').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(1);
    expect(wrapper.find('.remove-filter-row').exists()).toBeTruthy();
    expect(wrapper.find('#add-filter-row').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find('p').text()).toEqual('Filter will be applied to the line lists in the exposure workflow until reset.');
    expect(wrapper.find(Modal.Footer).find('u').text()).toEqual('exposure');
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(1);
    expect(wrapper.find(Modal.Footer).find(Button).text()).toEqual('Cancel');
  });

  it('Properly renders option dropdown', () => {
    const wrapper = getWrapper();
    const filterOptions = wrapper.state('filterOptions').sort((a, b) => {
      return a?.title?.localeCompare(b?.title);
    });
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('.advanced-filter-select').prop('options').length).toEqual(filterOptions.length);
    wrapper.find('.advanced-filter-select').prop('options').forEach(function(option, index) {
      expect(option.label).toEqual(filterOptions[index].title);
      expect(option.subLabel).toEqual(filterOptions[index].description);
      expect(option.value).toEqual(filterOptions[index].name);
      expect(option.disabled).toEqual(false);
    });
  });

  it('Renders all main modal components when an active filter is set', () => {
    const wrapper = getWrapper();
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Header).text()).toEqual(`Advanced Filter: ${mockFilter1.name}`);
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-save').exists()).toBeFalsy();
    expect(wrapper.find('#advanced-filter-update').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-update').text()).toEqual('Update');
    expect(wrapper.find('#advanced-filter-update').find('i').hasClass('fa-marker')).toBeTruthy();
    expect(wrapper.find('#advanced-filter-delete').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-delete').text()).toEqual('Delete');
    expect(wrapper.find('#advanced-filter-delete').find('i').hasClass('fa-trash')).toBeTruthy();
    expect(wrapper.find('#advanced-filter-reset').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-reset').text()).toEqual('Reset');
    expect(wrapper.find('#advanced-filter-apply').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-apply').text()).toEqual('Apply');
    expect(wrapper.find('.advanced-filter-statement').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(1);
    expect(wrapper.find('.remove-filter-row').exists()).toBeTruthy();
    expect(wrapper.find('#add-filter-row').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find('p').text()).toEqual('Filter will be applied to the line lists in the exposure workflow until reset.');
    expect(wrapper.find(Modal.Footer).find('u').text()).toEqual('exposure');
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(1);
    expect(wrapper.find(Modal.Footer).find(Button).text()).toEqual('Cancel');
  });

  it('Renders advanced filter statements properly when an active filter is set', () => {
    const wrapper = getWrapper();
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents });
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(1);
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual(mockFilter1.contents[0].value);
  });

  it('Renders advanced filter statements properly when loading a saved filter', () => {
    const wrapper = getWrapper();
    wrapper.setState({ savedFilters: mockSavedFilters });
    wrapper.find(Dropdown.Item).at(2).simulate('click');
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(2);
    expect(wrapper.find('.advanced-filter-select').at(0).prop('value').value).toEqual(mockFilter2.contents[0].filterOption.name);
    expect(wrapper.find(ToggleButton).at(0).prop('checked')).toEqual(mockFilter2.contents[0].value);
    expect(wrapper.find(ToggleButton).at(1).prop('checked')).toEqual(!mockFilter2.contents[0].value);
    expect(wrapper.find('.advanced-filter-select').at(1).prop('value').value).toEqual(mockFilter2.contents[1].filterOption.name);
    expect(wrapper.find('.advanced-filter-date-options').prop('value')).toEqual(mockFilter2.contents[1].dateOption);
    expect(wrapper.find(DateInput).length).toEqual(1);
    expect(wrapper.find(DateInput).prop('date')).toEqual(mockFilter2.contents[1].value);
  });

  it('Clicking "+" button adds another filter statement row and updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    _.times(4, (i) => {
      expect(wrapper.find('.advanced-filter-statement').length).toEqual(i+1);
      expect(wrapper.state('activeFilterOptions').length).toEqual(i+1);
      wrapper.find('#add-filter-row').simulate('click');
    });
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(5);
    expect(wrapper.state('activeFilterOptions').length).toEqual(5);
  });

  it('Clicking "+" button displays "AND" row', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('.and-row').length).toEqual(0);
    _.times(4, (i) => {
      wrapper.find('#add-filter-row').simulate('click');
      expect(wrapper.find('.and-row').length).toEqual(i+1);
      expect(wrapper.find('.and-row').at(i).text()).toEqual('AND');
    });
  });

  it('Adding five statements disables the "+" button', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    _.times(4, (i) => {
      expect(wrapper.find('#add-filter-row').prop('disabled')).toBeFalsy();
      expect(wrapper.find('.advanced-filter-statement').length).toEqual(i+1);
      wrapper.find('#add-filter-row').simulate('click');
    });
    expect(wrapper.find('#add-filter-row').prop('disabled')).toBeTruthy();
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(5);
  });

  it('Clicking "-" button removes filter statement row and updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    _.times(4, () => {
      wrapper.find('#add-filter-row').simulate('click');
    });
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(5);
    expect(wrapper.state('activeFilterOptions').length).toEqual(5);
    expect(wrapper.find('.remove-filter-row').length).toEqual(5);
    expect(wrapper.find('.and-row').length).toEqual(4);
    _.times(5, (i) => {
      let random = _.random(1, wrapper.find('.remove-filter-row').length);
      wrapper.find('.remove-filter-row').at(random-1).simulate('click');
      expect(wrapper.find('.advanced-filter-statement').length).toEqual(4-i);
      expect(wrapper.state('activeFilterOptions').length).toEqual(4-i);
      expect(wrapper.find('.remove-filter-row').length).toEqual(4-i);
      expect(wrapper.find('.and-row').length).toEqual(3-i > 0 ? 3-i : 0);
    });
  });

  it('Clicking "-" button removes properly updates state and dropdown value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    _.times(4, () => {
      wrapper.find('#add-filter-row').simulate('click');
    });
    wrapper.find('.advanced-filter-select').at(0).simulate('change', { value: mockFilterDefaultBoolOption.filterOption.name });
    wrapper.find('.advanced-filter-select').at(1).simulate('change', { value: mockFilterOptionsOption.filterOption.name });
    wrapper.find('.advanced-filter-select').at(2).simulate('change', { value: mockFilterDefaultNumberOption.filterOption.name });
    wrapper.find('.advanced-filter-select').at(3).simulate('change', { value: mockFilterDefaultSearchOption.filterOption.name });
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultBoolOption, mockFilterOptionsOption, mockFilterDefaultNumberOption, mockFilterDefaultSearchOption, { filterOption: null } ]);
    expect(wrapper.find('.advanced-filter-select').at(0).prop('value').value).toEqual(mockFilterDefaultBoolOption.filterOption.name);
    expect(wrapper.find('.advanced-filter-select').at(1).prop('value').value).toEqual(mockFilterOptionsOption.filterOption.name);
    expect(wrapper.find('.advanced-filter-select').at(2).prop('value').value).toEqual(mockFilterDefaultNumberOption.filterOption.name);
    expect(wrapper.find('.advanced-filter-select').at(3).prop('value').value).toEqual(mockFilterDefaultSearchOption.filterOption.name);
    expect(wrapper.find('.advanced-filter-select').at(4).prop('value')).toEqual(null);
    wrapper.find('.remove-filter-row').at(3).simulate('click');
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultBoolOption, mockFilterOptionsOption, mockFilterDefaultNumberOption, { filterOption: null } ]);
    expect(wrapper.find('.advanced-filter-select').at(0).prop('value').value).toEqual(mockFilterDefaultBoolOption.filterOption.name);
    expect(wrapper.find('.advanced-filter-select').at(1).prop('value').value).toEqual(mockFilterOptionsOption.filterOption.name);
    expect(wrapper.find('.advanced-filter-select').at(2).prop('value').value).toEqual(mockFilterDefaultNumberOption.filterOption.name);
    expect(wrapper.find('.advanced-filter-select').at(3).prop('value')).toEqual(null);
    wrapper.find('.remove-filter-row').at(1).simulate('click');
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultBoolOption, mockFilterDefaultNumberOption, { filterOption: null } ]);
    expect(wrapper.find('.advanced-filter-select').at(0).prop('value').value).toEqual(mockFilterDefaultBoolOption.filterOption.name);
    expect(wrapper.find('.advanced-filter-select').at(1).prop('value').value).toEqual(mockFilterDefaultNumberOption.filterOption.name);
    expect(wrapper.find('.advanced-filter-select').at(2).prop('value')).toEqual(null);
    wrapper.find('.remove-filter-row').at(1).simulate('click');
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultBoolOption, { filterOption: null } ]);
    expect(wrapper.find('.advanced-filter-select').at(0).prop('value').value).toEqual(mockFilterDefaultBoolOption.filterOption.name);
    expect(wrapper.find('.advanced-filter-select').at(1).prop('value')).toEqual(null);
    wrapper.find('.remove-filter-row').at(0).simulate('click');
    expect(wrapper.state('activeFilterOptions')).toEqual([ { filterOption: null } ]);
    expect(wrapper.find('.advanced-filter-select').at(0).prop('value')).toEqual(null);
    wrapper.find('.remove-filter-row').at(0).simulate('click');
    expect(wrapper.state('activeFilterOptions')).toEqual([ ]);
    expect(wrapper.find('.advanced-filter-select').length).toEqual(0);
  });

  it('Properly renders advanced filter boolean type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterBoolOption.filterOption.name });
    expect(wrapper.find('.advanced-filter-select').prop('value').value).toEqual(mockFilterBoolOption.filterOption.name);
    expect(wrapper.find(ButtonGroup).exists()).toBeTruthy();
    expect(wrapper.find(ToggleButton).length).toEqual(2);
    expect(wrapper.find(ToggleButton).at(0).prop('checked')).toBeTruthy();
    expect(wrapper.find(ToggleButton).at(1).prop('checked')).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
  });

  it('Properly renders advanced filter option type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterOptionsOption.filterOption.name });
    expect(wrapper.find('.advanced-filter-select').prop('value').value).toEqual(mockFilterOptionsOption.filterOption.name);
    expect(wrapper.find(Form.Control).length).toEqual(1);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterOptionsOption.filterOption.options[0]);
    expect(wrapper.find(Form.Control).find('option').length).toEqual(mockFilterOptionsOption.filterOption.options.length);
    mockFilterOptionsOption.filterOption.options.forEach(function(option, index) {
      expect(wrapper.find(Form.Control).find('option').at(index).text()).toEqual(option);
      expect(wrapper.find(Form.Control).find('option').at(index).prop('value')).toEqual(option);
    });
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
  });

  it('Properly renders advanced filter number type statement with single number', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterNumberOption.filterOption.name });
    expect(wrapper.find('.advanced-filter-select').prop('value').value).toEqual(mockFilterNumberOption.filterOption.name);
    expect(wrapper.find(Form.Control).length).toEqual(2);
    expect(wrapper.find(Form.Control).at(0).prop('value')).toEqual('equal');
    expect(wrapper.find(Form.Control).find('option').length).toEqual(numberOptionValues.length);
    numberOptionValues.forEach(function(value, index) {
      expect(wrapper.find(Form.Control).at(0).find('option').at(index).text()).toEqual(numberOptionValuesText[index]);
      expect(wrapper.find(Form.Control).at(0).find('option').at(index).prop('value')).toEqual(value);
    });
    expect(wrapper.find(Form.Control).at(1).prop('value')).toEqual(0);
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
  });

  it('Properly renders advanced filter number type statement with number range', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterNumberOption.filterOption.name });
    expect(wrapper.find('.advanced-filter-select').prop('value').value).toEqual(mockFilterNumberOption.filterOption.name);
    wrapper.find('.advanced-filter-number-options').simulate('change', { target: { value: 'between' } });
    expect(wrapper.find(Form.Control).length).toEqual(3);
    expect(wrapper.find(Form.Control).at(0).prop('value')).toEqual('between');
    expect(wrapper.find(Form.Control).find('option').length).toEqual(numberOptionValues.length);
    numberOptionValues.forEach(function(value, index) {
      expect(wrapper.find(Form.Control).at(0).find('option').at(index).text()).toEqual(numberOptionValuesText[index]);
      expect(wrapper.find(Form.Control).at(0).find('option').at(index).prop('value')).toEqual(value);
    });
    expect(wrapper.find(Form.Control).at(1).prop('value')).toEqual(0);
    expect(wrapper.find('.text-center').find('b').text()).toEqual('AND');
    expect(wrapper.find(Form.Control).at(2).prop('value')).toEqual(0);
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`"Between" is inclusive and will filter for values within the user-entered range, including the start and end values.`);
  });

  it('Properly renders advanced filter date type statement with single date', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterDateOption.filterOption.name });
    expect(wrapper.find('.advanced-filter-select').prop('value').value).toEqual(mockFilterDateOption.filterOption.name);
    wrapper.find('.advanced-filter-date-options').simulate('change', { target: { value: 'before' } });
    expect(wrapper.find(Form.Control).length).toEqual(1);
    expect(wrapper.find(Form.Control).prop('value')).toEqual('before');
    expect(wrapper.find(Form.Control).find('option').length).toEqual(dateOptionValues.length);
    dateOptionValues.forEach(function(value, index) {
      expect(wrapper.find(Form.Control).find('option').at(index).text()).toEqual(value);
      expect(wrapper.find(Form.Control).find('option').at(index).prop('value')).toEqual(value);
    });
    expect(wrapper.find(DateInput).length).toEqual(1);
    expect(wrapper.find(DateInput).prop('date')).toEqual(moment(new Date()).format('YYYY-MM-DD'));
    expect(wrapper.find('.text-center').exists()).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
  });

  it('Properly renders advanced filter date type statement with date range', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterDateOption.filterOption.name });
    expect(wrapper.find('.advanced-filter-select').prop('value').value).toEqual(mockFilterDateOption.filterOption.name);
    expect(wrapper.find(Form.Control).length).toEqual(1);
    expect(wrapper.find(Form.Control).prop('value')).toEqual('within');
    expect(wrapper.find(Form.Control).find('option').length).toEqual(dateOptionValues.length);
    dateOptionValues.forEach(function(value, index) {
      expect(wrapper.find(Form.Control).find('option').at(index).text()).toEqual(value);
      expect(wrapper.find(Form.Control).find('option').at(index).prop('value')).toEqual(value);
    });
    expect(wrapper.find(DateInput).length).toEqual(2);
    expect(wrapper.find(DateInput).at(0).prop('date')).toEqual(moment(new Date()).subtract(3,'d').format('YYYY-MM-DD'));
    expect(wrapper.find('.text-center').find('b').text()).toEqual('TO');
    expect(wrapper.find(DateInput).at(1).prop('date')).toEqual(moment(new Date()).format('YYYY-MM-DD'));
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
  });

  it('Properly renders advanced filter relative type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterDefaultCustomRelativeOption.filterOption.name });
    expect(wrapper.find('.advanced-filter-select').prop('value').value).toEqual(mockFilterDefaultCustomRelativeOption.filterOption.name);
    expect(wrapper.find(Form.Control).length).toEqual(1);
    expect(wrapper.find('.advanced-filter-relative-options').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual('today');
    expect(wrapper.find('.advanced-filter-relative-options').find('option').length).toEqual(relativeOptionValues.length);
    relativeOptionValues.forEach(function(value, index) {
      expect(wrapper.find('.advanced-filter-relative-options').find('option').at(index).text()).toEqual(relativeOptionValuesText[index]);
      expect(wrapper.find('.advanced-filter-relative-options').find('option').at(index).prop('value')).toEqual(value);
    });
    expect(wrapper.find('.advanced-filter-when-input').exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-number-input').exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-unit-input').exists()).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
  });

  it('Properly renders advanced filter relative type custom statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterDefaultCustomRelativeOption.filterOption.name });
    expect(wrapper.find('.advanced-filter-select').prop('value').value).toEqual(mockFilterDefaultCustomRelativeOption.filterOption.name);
    wrapper.find('.advanced-filter-relative-options').simulate('change', { target: { value: 'custom' } });
    expect(wrapper.find(Form.Control).length).toEqual(4);
    expect(wrapper.find('.advanced-filter-relative-options').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual('custom');
    expect(wrapper.find('.advanced-filter-relative-options').find('option').length).toEqual(relativeOptionValues.length);
    relativeOptionValues.forEach(function(value, index) {
      expect(wrapper.find('.advanced-filter-relative-options').find('option').at(index).text()).toEqual(relativeOptionValuesText[index]);
      expect(wrapper.find('.advanced-filter-relative-options').find('option').at(index).prop('value')).toEqual(value);
    });
    expect(wrapper.find('.advanced-filter-when-input').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-when-input').prop('value')).toEqual('past');
    expect(wrapper.find('.advanced-filter-when-input').find('option').length).toEqual(relativeOptionWhenValues.length);
    relativeOptionWhenValues.forEach(function(value, index) {
      expect(wrapper.find('.advanced-filter-when-input').find('option').at(index).text()).toEqual(`in the ${value}`);
      expect(wrapper.find('.advanced-filter-when-input').find('option').at(index).prop('value')).toEqual(value);
    });
    expect(wrapper.find('.advanced-filter-number-input').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(1);
    expect(wrapper.find('.advanced-filter-unit-input').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-unit-input').prop('value')).toEqual('days');
    expect(wrapper.find('.advanced-filter-unit-input').find('option').length).toEqual(relativeOptionUnitValues.length);
    relativeOptionUnitValues.forEach(function(value, index) {
      expect(wrapper.find('.advanced-filter-unit-input').find('option').at(index).text()).toEqual(value);
      expect(wrapper.find('.advanced-filter-unit-input').find('option').at(index).prop('value')).toEqual(value.replace('(', '').replace(')', ''));
    });
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`Latest Report “past” relative date periods include records dated through today’s date. The current setting of "past 1 days" will return records with Latest Report date from ${moment(new Date()).subtract(1,'d').format('MM/DD/YY')} through now.`);
  });

  it('Properly renders advanced filter search type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterSearchOption.filterOption.name });
    expect(wrapper.find('.advanced-filter-select').prop('value').value).toEqual(mockFilterSearchOption.filterOption.name);
    expect(wrapper.find(Form.Control).length).toEqual(1);
    expect(wrapper.find(Form.Control).hasClass('advanced-filter-search-input')).toBeTruthy();
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual('');
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Properly renders advanced filter type with additional dropdown options statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterAdditionalOption.filterOption.name });
    expect(wrapper.find('.advanced-filter-select').prop('value').value).toEqual(mockFilterAdditionalOption.filterOption.name);
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-additional-filter-options').prop('value')).toEqual(mockFilterAdditionalOption.filterOption.options[0]);
    expect(wrapper.find('.advanced-filter-additional-filter-options').find('option').length).toEqual(mockFilterAdditionalOption.filterOption.options.length);
    mockFilterAdditionalOption.filterOption.options.forEach(function(option, index) {
      expect(wrapper.find('.advanced-filter-additional-filter-options').find('option').at(index).text()).toEqual(option);
      expect(wrapper.find('.advanced-filter-additional-filter-options').find('option').at(index).prop('value')).toEqual(option);
    });
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });
 
  it('Properly renders tooltip when defined with advanced filter option', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterIncludesTooltip.filterOption.name });
    expect(wrapper.find('.advanced-filter-select').prop('value').value).toEqual(mockFilterIncludesTooltip.filterOption.name);
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(mockFilterIncludesTooltip.filterOption.tooltip);
  });

  it('Toggling boolean buttons properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ { 'filterOption': null } ]);
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterBoolOption.filterOption.name });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultBoolOption ]);
    expect(wrapper.find('.advanced-filter-boolean-true').prop('checked')).toBeTruthy();
    expect(wrapper.find('.advanced-filter-boolean-false').prop('checked')).toBeFalsy();
    wrapper.find('.advanced-filter-boolean-false').simulate('change');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterBoolOption ]);
    expect(wrapper.find('.advanced-filter-boolean-true').prop('checked')).toBeFalsy();
    expect(wrapper.find('.advanced-filter-boolean-false').prop('checked')).toBeTruthy();
    wrapper.find('.advanced-filter-boolean-true').simulate('change');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultBoolOption ]);
    expect(wrapper.find('.advanced-filter-boolean-true').prop('checked')).toBeTruthy();
    expect(wrapper.find('.advanced-filter-boolean-false').prop('checked')).toBeFalsy();
  });

  it('Changing advanced filter option dropdown properly updates state and value', () => {
    const wrapper = getWrapper();
    const randomNumber = _.random(0, mockFilterOptionsOption.filterOption.options.length - 1);
    let newMockFilterOptionsOption = _.clone(mockFilterOptionsOption);
    newMockFilterOptionsOption.value = mockFilterOptionsOption.filterOption.options[randomNumber];
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ { 'filterOption': null } ]);
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterOptionsOption.filterOption.name });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterOptionsOption ]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterOptionsOption.filterOption.options[0]);
    wrapper.find(Form.Control).simulate('change', { target: { value: mockFilterOptionsOption.filterOption.options[randomNumber] } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ newMockFilterOptionsOption ]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterOptionsOption.filterOption.options[randomNumber]);
    wrapper.find(Form.Control).simulate('change', { target: { value: mockFilterOptionsOption.filterOption.options[0] } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterOptionsOption ]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterOptionsOption.filterOption.options[0]);
  });

  it('Changing advanced filter numberOption and value for number type advanced filters properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ { 'filterOption': null } ]);
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterNumberOption.filterOption.name });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultNumberOption ]);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterDefaultNumberOption.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterDefaultNumberOption.value);
    wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: 12 } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].numberOption).toEqual(mockFilterDefaultNumberOption.numberOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(12);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterDefaultNumberOption.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(12);
    wrapper.find('.advanced-filter-number-options').simulate('change', { target: { value: 'less-than' } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].numberOption).toEqual('less-than');
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(12);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual('less-than');
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(12);
    wrapper.find('.advanced-filter-number-options').simulate('change', { target: { value: 'between' } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].numberOption).toEqual('between');
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual({ firstBound: 0, secondBound: 0 });
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual('between');
    expect(wrapper.find('.advanced-filter-number-input').at(0).prop('value')).toEqual(0);
    expect(wrapper.find('.advanced-filter-number-input').at(1).prop('value')).toEqual(0);
    wrapper.find('.advanced-filter-number-input').at(1).simulate('change', { target: { value: mockFilterNumberOption.value.secondBound } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].numberOption).toEqual('between');
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual({ firstBound: 0, secondBound: mockFilterNumberOption.value.secondBound });
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual('between');
    expect(wrapper.find('.advanced-filter-number-input').at(0).prop('value')).toEqual(0);
    expect(wrapper.find('.advanced-filter-number-input').at(1).prop('value')).toEqual(mockFilterNumberOption.value.secondBound);
    wrapper.find('.advanced-filter-number-input').at(0).simulate('change', { target: { value: 20 } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterNumberOption ]);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual('between');
    expect(wrapper.find('.advanced-filter-number-input').at(0).prop('value')).toEqual(mockFilterNumberOption.value.firstBound);
    expect(wrapper.find('.advanced-filter-number-input').at(1).prop('value')).toEqual(mockFilterNumberOption.value.secondBound);
    wrapper.find('.advanced-filter-number-options').simulate('change', { target: { value: 'equal' } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultNumberOption ]);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterDefaultNumberOption.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterDefaultNumberOption.value);
  });

  it('Changing advanced filter dateOption and values for date type advanced filters properly updates state and value', () => {
    const wrapper = getWrapper();
    const newDate = moment(new Date()).subtract(14,'d').format('YYYY-MM-DD');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ { 'filterOption': null } ]);
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterDateOption.filterOption.name });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultDateOption ]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterDefaultDateOption.dateOption);
    expect(wrapper.find(DateInput).at(0).prop('date')).toEqual(mockFilterDefaultDateOption.value.start);
    expect(wrapper.find(DateInput).at(1).prop('date')).toEqual(mockFilterDefaultDateOption.value.end);
    wrapper.find(DateInput).at(0).simulate('change', newDate);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].dateOption).toEqual(mockFilterDefaultDateOption.dateOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual({ start: newDate, end: mockFilterDefaultDateOption.value.end });
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterDefaultDateOption.dateOption);
    expect(wrapper.find(DateInput).at(0).prop('date')).toEqual(newDate);
    expect(wrapper.find(DateInput).at(1).prop('date')).toEqual(mockFilterDefaultDateOption.value.end);
    wrapper.find(DateInput).at(1).simulate('change', mockFilterDefaultDateOption.value.start);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].dateOption).toEqual(mockFilterDefaultDateOption.dateOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual({ start: newDate, end: mockFilterDefaultDateOption.value.start });
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterDefaultDateOption.dateOption);
    expect(wrapper.find(DateInput).at(0).prop('date')).toEqual(newDate);
    expect(wrapper.find(DateInput).at(1).prop('date')).toEqual(mockFilterDefaultDateOption.value.start);
    wrapper.find(Form.Control).simulate('change', { target: { value: mockFilterDateOption.dateOption } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].dateOption).toEqual(mockFilterDateOption.dateOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(mockFilterDefaultDateOption.value.end);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterDateOption.dateOption);
    expect(wrapper.find(DateInput).prop('date')).toEqual(mockFilterDefaultDateOption.value.end);
    wrapper.find(DateInput).simulate('change', mockFilterDateOption.value);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].dateOption).toEqual(mockFilterDateOption.dateOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(mockFilterDateOption.value);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterDateOption.dateOption);
    expect(wrapper.find(DateInput).prop('date')).toEqual(mockFilterDateOption.value);
  });

  it('Changing advanced filter relativeOption and values for relative type advanced filters properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ { 'filterOption': null } ]);
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterDefaultRelativeOption.filterOption.name });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultRelativeOption ]);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterDefaultRelativeOption.relativeOption);
    wrapper.find('.advanced-filter-relative-options').simulate('change', { target: { value: mockFilterRelativeOption.relativeOption } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterRelativeOption ]);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterRelativeOption.relativeOption);
    wrapper.find('.advanced-filter-relative-options').simulate('change', { target: { value: mockFilterDefaultCustomRelativeOption.relativeOption } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultCustomRelativeOption ]);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterDefaultCustomRelativeOption.relativeOption);
    wrapper.find('.advanced-filter-when-input').simulate('change', { target: { value: mockFilterCustomRelativeOption.value.when } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].relativeOption).toEqual(mockFilterCustomRelativeOption.relativeOption);
    expect(wrapper.state('activeFilterOptions')[0].value.when).toEqual(mockFilterCustomRelativeOption.value.when);
    expect(wrapper.state('activeFilterOptions')[0].value.number).toEqual(mockFilterDefaultCustomRelativeOption.value.number);
    expect(wrapper.state('activeFilterOptions')[0].value.unit).toEqual(mockFilterDefaultCustomRelativeOption.value.unit);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterCustomRelativeOption.relativeOption);
    expect(wrapper.find('.advanced-filter-when-input').prop('value')).toEqual(mockFilterCustomRelativeOption.value.when);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterDefaultCustomRelativeOption.value.number);
    expect(wrapper.find('.advanced-filter-unit-input').prop('value')).toEqual(mockFilterDefaultCustomRelativeOption.value.unit);
    wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: mockFilterCustomRelativeOption.value.number } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].relativeOption).toEqual(mockFilterCustomRelativeOption.relativeOption);
    expect(wrapper.state('activeFilterOptions')[0].value.when).toEqual(mockFilterCustomRelativeOption.value.when);
    expect(wrapper.state('activeFilterOptions')[0].value.number).toEqual(mockFilterCustomRelativeOption.value.number);
    expect(wrapper.state('activeFilterOptions')[0].value.unit).toEqual(mockFilterDefaultCustomRelativeOption.value.unit);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterCustomRelativeOption.relativeOption);
    expect(wrapper.find('.advanced-filter-when-input').prop('value')).toEqual(mockFilterCustomRelativeOption.value.when);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterCustomRelativeOption.value.number);
    expect(wrapper.find('.advanced-filter-unit-input').prop('value')).toEqual(mockFilterDefaultCustomRelativeOption.value.unit);
    wrapper.find('.advanced-filter-unit-input').simulate('change', { target: { value: mockFilterCustomRelativeOption.value.unit } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterCustomRelativeOption ]);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterCustomRelativeOption.relativeOption);
    expect(wrapper.find('.advanced-filter-when-input').prop('value')).toEqual(mockFilterCustomRelativeOption.value.when);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterCustomRelativeOption.value.number);
    expect(wrapper.find('.advanced-filter-unit-input').prop('value')).toEqual(mockFilterCustomRelativeOption.value.unit);
    wrapper.find('.advanced-filter-relative-options').simulate('change', { target: { value: mockFilterDefaultRelativeOption.relativeOption } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultRelativeOption ]);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterDefaultRelativeOption.relativeOption);
  });

  it('Changing input text for search type advanced filter properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ { 'filterOption': null } ]);
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterSearchOption.filterOption.name });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultSearchOption ]);
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual('');
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: mockFilterSearchOption.value } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterSearchOption ]);
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual(mockFilterSearchOption.value);
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: '' } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultSearchOption ]);
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual('');
  });

  it('Changing additional options dropdown properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ { 'filterOption': null } ]);
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterAdditionalOption.filterOption.name });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultAdditionalOption ]);
    expect(wrapper.find('.advanced-filter-additional-filter-options').prop('value')).toEqual(mockFilterAdditionalOption.filterOption.options[0]);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterDefaultAdditionalOption.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterDefaultAdditionalOption.value);
    wrapper.find('.advanced-filter-additional-filter-options').simulate('change', { target: { value: mockFilterAdditionalOption.additionalFilterOption } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].additionalFilterOption).toEqual(mockFilterAdditionalOption.additionalFilterOption);
    expect(wrapper.state('activeFilterOptions')[0].numberOption).toEqual(mockFilterDefaultAdditionalOption.numberOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(mockFilterDefaultAdditionalOption.value);
    expect(wrapper.find('.advanced-filter-additional-filter-options').prop('value')).toEqual(mockFilterAdditionalOption.additionalFilterOption);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterDefaultAdditionalOption.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterDefaultAdditionalOption.value);
    wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: 2 } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].additionalFilterOption).toEqual(mockFilterAdditionalOption.additionalFilterOption);
    expect(wrapper.state('activeFilterOptions')[0].numberOption).toEqual(mockFilterDefaultAdditionalOption.numberOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(2);
    expect(wrapper.find('.advanced-filter-additional-filter-options').prop('value')).toEqual(mockFilterAdditionalOption.additionalFilterOption);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterDefaultAdditionalOption.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(2);
    wrapper.find('.advanced-filter-additional-filter-options').simulate('change', { target: { value: 'Unsuccessful' } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].additionalFilterOption).toEqual('Unsuccessful');
    expect(wrapper.state('activeFilterOptions')[0].numberOption).toEqual(mockFilterDefaultAdditionalOption.numberOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(2);
    expect(wrapper.find('.advanced-filter-additional-filter-options').prop('value')).toEqual('Unsuccessful');
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterDefaultAdditionalOption.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(2);
    wrapper.find('.advanced-filter-number-options').simulate('change', { target: { value: 'less-than' } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].additionalFilterOption).toEqual('Unsuccessful');
    expect(wrapper.state('activeFilterOptions')[0].numberOption).toEqual('less-than');
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(2);
    expect(wrapper.find('.advanced-filter-additional-filter-options').prop('value')).toEqual('Unsuccessful');
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual('less-than');
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(2);
    wrapper.find('.advanced-filter-additional-filter-options').simulate('change', { target: { value: mockFilterAdditionalOption.additionalFilterOption } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterAdditionalOption ]);
    expect(wrapper.find('.advanced-filter-additional-filter-options').prop('value')).toEqual(mockFilterAdditionalOption.additionalFilterOption);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterAdditionalOption.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterAdditionalOption.value);
  });

  it('Relative date custom tooltip dynamically updates as options change', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterDefaultCustomRelativeOption.filterOption.name });
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    wrapper.find('.advanced-filter-relative-options').simulate('change', { target: { value: 'custom' } });
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`Latest Report “past” relative date periods include records dated through today’s date. The current setting of "past 1 days" will return records with Latest Report date from ${moment(new Date()).subtract(1,'d').format('MM/DD/YY')} through now.`);
    wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: 3 } });
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`Latest Report “past” relative date periods include records dated through today’s date. The current setting of "past 3 days" will return records with Latest Report date from ${moment(new Date()).subtract(3,'d').format('MM/DD/YY')} through now.`);
    wrapper.find('.advanced-filter-unit-input').simulate('change', { target: { value: 'weeks' } });
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`Latest Report “past” relative date periods include records dated through today’s date. The current setting of "past 3 weeks" will return records with Latest Report date from ${moment(new Date()).subtract(3,'weeks').format('MM/DD/YY')} through now.`);
    wrapper.find('.advanced-filter-when-input').simulate('change', { target: { value: 'next' } });
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`Latest Report “next” relative date periods include records with today’s date as of the current time. The current setting of "next 3 weeks" will return records with Latest Report date from now through ${moment(new Date()).add(3,'weeks').format('MM/DD/YY')}.`);
    wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: 1 } });
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`Latest Report “next” relative date periods include records with today’s date as of the current time. The current setting of "next 1 weeks" will return records with Latest Report date from now through ${moment(new Date()).add(1,'weeks').format('MM/DD/YY')}.`);
  });

  it('Clicking "Save" button opens Filter Name modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('#advanced-filter-modal').exists()).toBeTruthy();
    expect(wrapper.find('#filter-name-modal').exists()).toBeFalsy();
    expect(wrapper.state('show')).toBeTruthy();
    expect(wrapper.state('showFilterNameModal')).toBeFalsy();
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find('#filter-name-modal').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-modal').exists()).toBeFalsy();
    expect(wrapper.state('show')).toBeFalsy();
    expect(wrapper.state('showFilterNameModal')).toBeTruthy();
  });

  it('Properly renders Filter Name modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find(Modal.Header).text()).toEqual('Filter Name');
    expect(wrapper.find('#filter-name-input').exists()).toBeTruthy();
    expect(wrapper.find('#filter-name-input').prop('value')).toEqual('');
    expect(wrapper.find('#filter-name-cancel').text()).toEqual('Cancel');
    expect(wrapper.find('#filter-name-save').text()).toEqual('Save');
    expect(wrapper.find('#filter-name-save').prop('disabled')).toBeTruthy();
  });

  it('Adding text to Filter Name modal input enables "Save" button and updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find('#filter-name-save').prop('disabled')).toBeTruthy();
    expect(wrapper.state('filterName')).toEqual(null);
    wrapper.find('#filter-name-input').simulate('change', { target: { value: 'some filter name' } });
    expect(wrapper.find('#filter-name-save').prop('disabled')).toBeFalsy();
    expect(wrapper.state('filterName')).toEqual('some filter name');
  });

  it('Clicking Filter Name modal "Cancel" button hides modal and shows Advanced Filter modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find('#filter-name-modal').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-modal').exists()).toBeFalsy();
    wrapper.find('#filter-name-cancel').simulate('click');
    expect(wrapper.find('#advanced-filter-modal').exists()).toBeTruthy();
    expect(wrapper.find('#filter-name-modal').exists()).toBeFalsy();
  });

  it('Clicking Filter Name modal "Cancel" button resets modal and state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    wrapper.find('#filter-name-input').simulate('change', { target: { value: 'some filter name' } });
    expect(wrapper.state('show')).toBeFalsy();
    expect(wrapper.state('showFilterNameModal')).toBeTruthy();
    expect(wrapper.state('filterName')).toEqual('some filter name');
    expect(wrapper.find('#filter-name-input').prop('value')).toEqual('some filter name');
    wrapper.find('#filter-name-cancel').simulate('click');
    expect(wrapper.state('show')).toBeTruthy();
    expect(wrapper.state('showFilterNameModal')).toBeFalsy();
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.state('show')).toBeFalsy();
    expect(wrapper.state('showFilterNameModal')).toBeTruthy();
    expect(wrapper.state('filterName')).toEqual(null);
    expect(wrapper.find('#filter-name-input').prop('value')).toEqual('');
  });

  it('Opening Filter Name modal and clicking "Cancel" button maintains advanced filter modal state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterSearchOption.filterOption.name });
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: mockFilterSearchOption.value } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterSearchOption ]);
    expect(wrapper.state('show')).toBeTruthy();
    expect(wrapper.find('.advanced-filter-select').prop('value').value).toEqual(mockFilterSearchOption.filterOption.name);
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual(mockFilterSearchOption.value);
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.state('show')).toBeFalsy();
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterSearchOption ]);
    expect(wrapper.find('.advanced-filter-select').exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-search-input').exists()).toBeFalsy();
    wrapper.find('#filter-name-cancel').simulate('click');
    expect(wrapper.state('show')).toBeTruthy();
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterSearchOption ]);
    expect(wrapper.find('.advanced-filter-select').prop('value').value).toEqual(mockFilterSearchOption.filterOption.name);
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual(mockFilterSearchOption.value);
  });

  it('Clicking Filter Name modal "Save" button calls save method', () => {
    const wrapper = getWrapper();
    const saveSpy = jest.spyOn(wrapper.instance(), 'save');
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(saveSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#filter-name-input').simulate('change', { target: { value: 'some filter name' } });
    expect(saveSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#filter-name-save').simulate('click');
    expect(saveSpy).toHaveBeenCalled();
  });

  it('Clicking Filter Name modal "Save" button hides modal and shows Advanced Filter modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find('#filter-name-modal').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-modal').exists()).toBeFalsy();
    wrapper.find('#filter-name-input').simulate('change', { target: { value: 'some filter name' } });
    wrapper.find('#filter-name-save').simulate('click');
    expect(wrapper.find('#advanced-filter-modal').exists()).toBeTruthy();
    expect(wrapper.find('#filter-name-modal').exists()).toBeFalsy();
  });

  it('Clicking "Update" button calls update method', () => {
    const wrapper = getWrapper();
    const updateSpy = jest.spyOn(wrapper.instance(), 'update');
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    wrapper.find(Button).simulate('click');
    expect(updateSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#advanced-filter-update').simulate('click');
    expect(updateSpy).toHaveBeenCalled();
  });

  it('Clicking "Delete" button calls delete method', () => {
    const wrapper = getWrapper();
    const deleteSpy = jest.spyOn(wrapper.instance(), 'delete');
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    wrapper.find(Button).simulate('click');
    expect(deleteSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#advanced-filter-delete').simulate('click');
    expect(deleteSpy).toHaveBeenCalled();
  });

  it('Clicking "Reset" button calls reset method', () => {
    const wrapper = getWrapper();
    const resetSpy = jest.spyOn(wrapper.instance(), 'reset');
    wrapper.find(Button).simulate('click');
    expect(resetSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#advanced-filter-reset').simulate('click');
    expect(resetSpy).toHaveBeenCalled();
  });

  it('Clicking "Apply" button calls props.advancedFilterUpdate', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledTimes(0);
    wrapper.setState({ activeFilterOptions: mockFilter1.contents });
    wrapper.find('#advanced-filter-apply').simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalled();
  });

  it('Clicking "Apply" button properly updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('show')).toBeTruthy();
    expect(wrapper.state('applied')).toBeFalsy();
    expect(wrapper.state('lastAppliedFilter')).toEqual(null);
    wrapper.setState({ activeFilterOptions: mockFilter1.contents });
    wrapper.find('#advanced-filter-apply').simulate('click');
    expect(wrapper.state('show')).toBeFalsy();
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual(mockFilter1.contents);
  });

  it('Clicking "Clear current filter" dropdown option calls props.advancedFilterUpdate', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledTimes(0);
    wrapper.setState({ activeFilterOptions: mockFilter1.contents });
    wrapper.find('#advanced-filter-apply').simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledTimes(1);
    wrapper.find(Dropdown.Item).at(1).simulate('click');
    expect(advancedFilterUpdateMock).toHaveBeenCalledTimes(2);
  });

  it('Clicking "Clear current filter" dropdown option properly updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('show')).toBeTruthy();
    expect(wrapper.state('applied')).toBeFalsy();
    expect(wrapper.state('activeFilterOptions')).toEqual([ { filterOption: null } ]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter')).toEqual(null);
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    wrapper.find('#advanced-filter-apply').simulate('click');
    expect(wrapper.state('show')).toBeFalsy();
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')).toEqual(mockFilter1.contents);
    expect(wrapper.state('activeFilter')).toEqual(mockFilter1);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(mockFilter1);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual(mockFilter1.contents);
    wrapper.find(Dropdown.Item).at(1).simulate('click');
    expect(wrapper.state('show')).toBeFalsy();
    expect(wrapper.state('applied')).toBeFalsy();
    expect(wrapper.state('activeFilterOptions')).toEqual([ { filterOption: null } ]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(mockFilter1);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual(mockFilter1.contents);
  });

  it('Clicking "Cancel" button calls cancel method and hides modal', () => {
    const wrapper = getWrapper();
    const cancelSpy = jest.spyOn(wrapper.instance(), 'cancel');
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(cancelSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#advanced-filter-cancel').simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    expect(cancelSpy).toHaveBeenCalled();
  });

  it('Triggering advanced filter modal onHide prop calls cancel method and hides modal', () => {
    const wrapper = getWrapper();
    const cancelSpy = jest.spyOn(wrapper.instance(), 'cancel');
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(cancelSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Modal).prop('onHide')();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    expect(cancelSpy).toHaveBeenCalled();
  });

  it('Clicking "Cancel" button after making changes properly resets modal to initial state if no filter was applied', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBeFalsy();
    expect(wrapper.state('activeFilterOptions')).toEqual([ { filterOption: null } ]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter')).toEqual(null);
    expect(wrapper.find(Form.Control).exists()).toBeFalsy();
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterSearchOption.filterOption.name });
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: mockFilterSearchOption.value } });
    expect(wrapper.state('applied')).toBeFalsy();
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterSearchOption ]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter')).toEqual(null);
    expect(wrapper.find(Form.Control).exists()).toBeTruthy();
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterSearchOption.value);
    wrapper.find('#advanced-filter-cancel').simulate('click');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBeFalsy();
    expect(wrapper.state('activeFilterOptions')).toEqual([ { filterOption: null } ]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter')).toEqual(null);
    expect(wrapper.find(Form.Control).exists()).toBeFalsy();
  });

  it('Clicking "Cancel" button after making changes properly resets modal to the most recent filter applied', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterDefaultBoolOption.filterOption.name });
    expect(wrapper.state('applied')).toBeFalsy();
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultBoolOption ]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter')).toEqual(null);
    expect(wrapper.find(ToggleButton).at(0).prop('checked')).toBeTruthy();
    expect(wrapper.find(ToggleButton).at(1).prop('checked')).toBeFalsy();
    wrapper.find('#advanced-filter-apply').simulate('click');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultBoolOption ]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([ mockFilterDefaultBoolOption ]);
    expect(wrapper.find(ToggleButton).at(0).prop('checked')).toBeTruthy();
    expect(wrapper.find(ToggleButton).at(1).prop('checked')).toBeFalsy();
    wrapper.find('.advanced-filter-boolean-false').simulate('change');
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterBoolOption ]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([ mockFilterDefaultBoolOption ]);
    expect(wrapper.find(ToggleButton).at(0).prop('checked')).toBeFalsy();
    expect(wrapper.find(ToggleButton).at(1).prop('checked')).toBeTruthy();
    wrapper.find('#advanced-filter-cancel').simulate('click');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterDefaultBoolOption ]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([ mockFilterDefaultBoolOption ]);
    expect(wrapper.find(ToggleButton).at(0).prop('checked')).toBeTruthy();
    expect(wrapper.find(ToggleButton).at(1).prop('checked')).toBeFalsy();
    wrapper.find('.advanced-filter-select').simulate('change', { value: mockFilterSearchOption.filterOption.name });
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: mockFilterSearchOption.value } });
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterSearchOption ]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([ mockFilterDefaultBoolOption ]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterSearchOption.value);
    wrapper.find('#advanced-filter-apply').simulate('click');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterSearchOption ]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([ mockFilterSearchOption ]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterSearchOption.value);
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: `${mockFilterSearchOption.value}!!!` } });
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(`${mockFilterSearchOption.value}!!!`);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([ mockFilterSearchOption ]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(`${mockFilterSearchOption.value}!!!`);
    wrapper.find('#advanced-filter-cancel').simulate('click');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')).toEqual([ mockFilterSearchOption ]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([ mockFilterSearchOption ]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterSearchOption.value);
  });
});