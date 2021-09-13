import React from 'react';
import { shallow } from 'enzyme';
import _ from 'lodash';
import moment from 'moment';
import ReactTooltip from 'react-tooltip';
import { Button, ButtonGroup, Dropdown, Form, Modal, OverlayTrigger, ToggleButton } from 'react-bootstrap';
import AdvancedFilter from '../../../components/public_health/query/AdvancedFilter';
import DateInput from '../../../components/util/DateInput';
import { advancedFilterOptions } from '../../../data/advancedFilterOptions';
import {
  mockFilter1,
  mockFilter2,
  mockFilterMonitoringStatusTrue,
  mockFilterMonitoringStatusFalse,
  mockFilterSevenDayQuarantine,
  mockFilterPreferredContactTime,
  mockFilterAgeEqual,
  mockFilterAgeBetween,
  mockFilterManualContactAttemptsEqual,
  mockFilterManualContactAttemptsLessThan,
  mockFilterSymptomOnsetDateWithin,
  mockFilterSymptomOnsetDateBefore,
  mockFilterSymptomOnsetDateBlank,
  mockFilterEnrolledDateBefore,
  mockFilterLatestReportRelativeToday,
  mockFilterLatestReportRelativeYesterday,
  mockFilterLatestReportRelativeCustomPast,
  mockFilterSymptomOnsetRelativeCustomPast,
  mockFilterLatestReportRelativeCustomFuture,
  mockFilterAddressForeignEmpty,
  mockFilterAddressForeign,
  mockFilterLabResults,
  mockFilterAssignedUser,
  mockFilterJurisdiction,
  mockSavedFilters,
} from '../../mocks/mockFilters';

const advancedFilterUpdateMock = jest.fn();
const mockToken = 'testMockTokenString12345';
const numberOptionValues = ['less-than', 'less-than-equal', 'equal', 'greater-than-equal', 'greater-than', 'between'];
const numberOptionValuesText = ['less than', 'less than or equal to', 'equal to', 'greater than or equal to', 'greater than', 'between'];
const dateOptionValues = ['within', 'before', 'after'];
const combinationDateOptionValues = ['before', 'after', ''];
const relativeOptionValues = ['today', 'tomorrow', 'yesterday', 'custom'];
const relativeOptionOperatorValues = ['less-than', 'greater-than'];
const relativeOptionUnitValues = ['day(s)', 'week(s)', 'month(s)'];
const relativeOptionWhenValues = ['past', 'future'];
const continuous_exposure_enabled = true;

function getWrapper() {
  return shallow(<AdvancedFilter workflow={'exposure'} advancedFilterUpdate={advancedFilterUpdateMock} updateStickySettings={true} authenticity_token={mockToken} continuous_exposure_enabled={continuous_exposure_enabled} />);
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
    mockSavedFilters.forEach((filter, index) => {
      expect(
        wrapper
          .find(Dropdown.Item)
          .at(index + 1)
          .text()
      ).toEqual(filter.name);
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
    expect(wrapper.find(Modal.Body).find(Button).length).toEqual(4);
    expect(wrapper.find(Modal.Body).find('#advanced-filter-save').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('#advanced-filter-save').text()).toEqual('Save');
    expect(wrapper.find(Modal.Body).find('#advanced-filter-save').find('i').hasClass('fa-save')).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('#advanced-filter-update').exists()).toBeFalsy();
    expect(wrapper.find(Modal.Body).find('#advanced-filter-delete').exists()).toBeFalsy();
    expect(wrapper.find(Modal.Body).find('#advanced-filter-reset').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('#advanced-filter-reset').text()).toEqual('Reset');
    expect(wrapper.find(Modal.Body).find('.advanced-filter-statement').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('.advanced-filter-statement').length).toEqual(1);
    expect(wrapper.find(Modal.Body).find('.remove-filter-row').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('#add-filter-row').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find('p').text()).toEqual('Filter will be applied to all line lists in the current dashboard until reset.');
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-cancel').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-cancel').text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-apply').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-apply').text()).toEqual('Apply');
  });

  it('Properly renders option dropdown', () => {
    const wrapper = getWrapper();
    const filterOptions = advancedFilterOptions.sort((a, b) => {
      return a?.title?.localeCompare(b?.title);
    });
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('options').length).toEqual(filterOptions.length);
    wrapper
      .find('.advanced-filter-options-dropdown')
      .prop('options')
      .forEach((option, index) => {
        expect(option.label).toEqual(filterOptions[Number(index)].title);
        expect(option.subLabel).toEqual(filterOptions[Number(index)].description);
        expect(option.value).toEqual(filterOptions[Number(index)].name);
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
    expect(wrapper.find(Modal.Body).find(Button).length).toEqual(5);
    expect(wrapper.find(Modal.Body).find('#advanced-filter-save').exists()).toBeFalsy();
    expect(wrapper.find(Modal.Body).find('#advanced-filter-update').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('#advanced-filter-update').text()).toEqual('Update');
    expect(wrapper.find(Modal.Body).find('#advanced-filter-update').find('i').hasClass('fa-marker')).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('#advanced-filter-delete').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('#advanced-filter-delete').text()).toEqual('Delete');
    expect(wrapper.find(Modal.Body).find('#advanced-filter-delete').find('i').hasClass('fa-trash')).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('#advanced-filter-reset').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('#advanced-filter-reset').text()).toEqual('Reset');
    expect(wrapper.find(Modal.Body).find('.advanced-filter-statement').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('.advanced-filter-statement').length).toEqual(1);
    expect(wrapper.find(Modal.Body).find('.remove-filter-row').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('#add-filter-row').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find('p').text()).toEqual('Filter will be applied to all line lists in the current dashboard until reset.');
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-cancel').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-cancel').text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-apply').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find('#advanced-filter-apply').text()).toEqual('Apply');
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
    expect(wrapper.find('.advanced-filter-options-dropdown').at(0).prop('value').value).toEqual(mockFilter2.contents[0].filterOption.name);
    expect(wrapper.find(ToggleButton).at(0).prop('checked')).toEqual(mockFilter2.contents[0].value);
    expect(wrapper.find(ToggleButton).at(1).prop('checked')).toEqual(!mockFilter2.contents[0].value);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(1).prop('value').value).toEqual(mockFilter2.contents[1].filterOption.name);
    expect(wrapper.find('.advanced-filter-date-options').prop('value')).toEqual(mockFilter2.contents[1].dateOption);
    expect(wrapper.find(DateInput).length).toEqual(1);
    expect(wrapper.find(DateInput).prop('date')).toEqual(mockFilter2.contents[1].value);
  });

  it('Clicking "+" button adds another filter statement row and updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    _.times(4, i => {
      expect(wrapper.find('.advanced-filter-statement').length).toEqual(i + 1);
      expect(wrapper.state('activeFilterOptions').length).toEqual(i + 1);
      wrapper.find('#add-filter-row').simulate('click');
    });
    expect(wrapper.find('.advanced-filter-statement').length).toEqual(5);
    expect(wrapper.state('activeFilterOptions').length).toEqual(5);
  });

  it('Clicking "+" button displays "AND" row', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('.and-row').length).toEqual(0);
    _.times(4, i => {
      wrapper.find('#add-filter-row').simulate('click');
      expect(wrapper.find('.and-row').length).toEqual(i + 1);
      expect(wrapper.find('.and-row').at(i).text()).toEqual('AND');
    });
  });

  it('Adding five statements disables the "+" button', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    _.times(4, i => {
      expect(wrapper.find('#add-filter-row').prop('disabled')).toBeFalsy();
      expect(wrapper.find('.advanced-filter-statement').length).toEqual(i + 1);
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
    _.times(5, i => {
      let random = _.random(1, wrapper.find('.remove-filter-row').length);
      wrapper
        .find('.remove-filter-row')
        .at(random - 1)
        .simulate('click');
      expect(wrapper.find('.advanced-filter-statement').length).toEqual(4 - i);
      expect(wrapper.state('activeFilterOptions').length).toEqual(4 - i);
      expect(wrapper.find('.remove-filter-row').length).toEqual(4 - i);
      expect(wrapper.find('.and-row').length).toEqual(3 - i > 0 ? 3 - i : 0);
    });
  });

  it('Clicking "-" button removes properly updates state and dropdown value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    _.times(4, () => {
      wrapper.find('#add-filter-row').simulate('click');
    });
    wrapper.find('.advanced-filter-options-dropdown').at(0).simulate('change', { value: mockFilterMonitoringStatusTrue.filterOption.name });
    wrapper.find('.advanced-filter-options-dropdown').at(1).simulate('change', { value: mockFilterPreferredContactTime.filterOption.name });
    wrapper.find('.advanced-filter-options-dropdown').at(2).simulate('change', { value: mockFilterAgeEqual.filterOption.name });
    wrapper.find('.advanced-filter-options-dropdown').at(3).simulate('change', { value: mockFilterAddressForeignEmpty.filterOption.name });
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterMonitoringStatusTrue, mockFilterPreferredContactTime, mockFilterAgeEqual, mockFilterAddressForeignEmpty, { filterOption: null }]);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(0).prop('value').value).toEqual(mockFilterMonitoringStatusTrue.filterOption.name);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(1).prop('value').value).toEqual(mockFilterPreferredContactTime.filterOption.name);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(2).prop('value').value).toEqual(mockFilterAgeEqual.filterOption.name);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(3).prop('value').value).toEqual(mockFilterAddressForeignEmpty.filterOption.name);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(4).prop('value')).toEqual(null);
    wrapper.find('.remove-filter-row').at(3).simulate('click');
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterMonitoringStatusTrue, mockFilterPreferredContactTime, mockFilterAgeEqual, { filterOption: null }]);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(0).prop('value').value).toEqual(mockFilterMonitoringStatusTrue.filterOption.name);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(1).prop('value').value).toEqual(mockFilterPreferredContactTime.filterOption.name);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(2).prop('value').value).toEqual(mockFilterAgeEqual.filterOption.name);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(3).prop('value')).toEqual(null);
    wrapper.find('.remove-filter-row').at(1).simulate('click');
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterMonitoringStatusTrue, mockFilterAgeEqual, { filterOption: null }]);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(0).prop('value').value).toEqual(mockFilterMonitoringStatusTrue.filterOption.name);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(1).prop('value').value).toEqual(mockFilterAgeEqual.filterOption.name);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(2).prop('value')).toEqual(null);
    wrapper.find('.remove-filter-row').at(1).simulate('click');
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterMonitoringStatusTrue, { filterOption: null }]);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(0).prop('value').value).toEqual(mockFilterMonitoringStatusTrue.filterOption.name);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(1).prop('value')).toEqual(null);
    wrapper.find('.remove-filter-row').at(0).simulate('click');
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(0).prop('value')).toEqual(null);
    // Add row with jurisdiction filter
    wrapper.find('.advanced-filter-options-dropdown').at(0).simulate('change', { value: mockFilterJurisdiction.filterOption.name });
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterJurisdiction]);
    expect(wrapper.find('.advanced-filter-options-dropdown').at(0).prop('value').value).toEqual(mockFilterJurisdiction.filterOption.name);
    wrapper.find('.advanced-filter-multi-select').simulate('change', { value: [{ value: '2', label: 'USA, State 1' }] });
    expect(wrapper.find('.advanced-filter-multi-select').prop('value').value).toEqual([{ value: '2', label: 'USA, State 1' }]);
    // Add row with assigned user filter
    wrapper.find('#add-filter-row').simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').at(1).simulate('change', { value: mockFilterAssignedUser.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').at(1).prop('value').value).toEqual(mockFilterAssignedUser.filterOption.name);
    wrapper
      .find('.advanced-filter-multi-select')
      .at(1)
      .simulate('change', { value: [{ value: 8007, label: 8007 }] });
    expect(wrapper.find('.advanced-filter-multi-select').at(0).prop('value').value).toEqual([{ value: '2', label: 'USA, State 1' }]);
    expect(wrapper.find('.advanced-filter-multi-select').at(1).prop('value').value).toEqual([{ value: 8007, label: 8007 }]);
    // Remove jurisdiction row
    wrapper.find('.remove-filter-row').at(0).simulate('click');
    expect(wrapper.find('.advanced-filter-options-dropdown').at(0).prop('value').value).toEqual(mockFilterAssignedUser.filterOption.name);
    expect(wrapper.find('.advanced-filter-multi-select').at(0).prop('value').value).toEqual([{ value: 8007, label: 8007 }]);
    // Remove last remaining row
    wrapper.find('.remove-filter-row').at(0).simulate('click');
    expect(wrapper.state('activeFilterOptions')).toEqual([]);
    expect(wrapper.find('.advanced-filter-options-dropdown').length).toEqual(0);
  });

  it('Properly renders advanced filter boolean type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterMonitoringStatusFalse.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterMonitoringStatusFalse.filterOption.name);
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
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterPreferredContactTime.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterPreferredContactTime.filterOption.name);
    expect(wrapper.find(Form.Control).length).toEqual(1);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterPreferredContactTime.filterOption.options[0]);
    expect(wrapper.find(Form.Control).find('option').length).toEqual(mockFilterPreferredContactTime.filterOption.options.length);
    mockFilterPreferredContactTime.filterOption.options.forEach((option, index) => {
      expect(wrapper.find(Form.Control).find('option').at(index).text()).toEqual(option);
      expect(wrapper.find(Form.Control).find('option').at(index).prop('value')).toEqual(option);
    });
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
  });

  it('Properly renders advanced filter number type statement with single number', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterAgeBetween.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterAgeBetween.filterOption.name);
    expect(wrapper.find(Form.Control).length).toEqual(2);
    expect(wrapper.find(Form.Control).at(0).prop('value')).toEqual('equal');
    expect(wrapper.find(Form.Control).find('option').length).toEqual(numberOptionValues.length);
    numberOptionValues.forEach((value, index) => {
      expect(wrapper.find(Form.Control).at(0).find('option').at(index).text()).toEqual(numberOptionValuesText[Number(index)]);
      expect(wrapper.find(Form.Control).at(0).find('option').at(index).prop('value')).toEqual(value);
    });
    expect(wrapper.find(Form.Control).at(1).prop('value')).toEqual(0);
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
  });

  it('Properly renders advanced filter number type statement with number range', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterAgeBetween.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterAgeBetween.filterOption.name);
    wrapper.find('.advanced-filter-number-options').simulate('change', { target: { value: 'between' } });
    expect(wrapper.find(Form.Control).length).toEqual(3);
    expect(wrapper.find(Form.Control).at(0).prop('value')).toEqual('between');
    expect(wrapper.find(Form.Control).find('option').length).toEqual(numberOptionValues.length);
    numberOptionValues.forEach((value, index) => {
      expect(wrapper.find(Form.Control).at(0).find('option').at(index).text()).toEqual(numberOptionValuesText[Number(index)]);
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
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterSymptomOnsetDateBefore.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterSymptomOnsetDateBefore.filterOption.name);
    wrapper.find('.advanced-filter-date-options').simulate('change', { target: { value: 'before' } });
    expect(wrapper.find(Form.Control).length).toEqual(1);
    expect(wrapper.find(Form.Control).prop('value')).toEqual('before');
    expect(wrapper.find(Form.Control).find('option').length).toEqual(dateOptionValues.length + 1);
    dateOptionValues.forEach((value, index) => {
      expect(wrapper.find(Form.Control).find('option').at(index).text()).toEqual(value);
      expect(wrapper.find(Form.Control).find('option').at(index).prop('value')).toEqual(value);
    });
    expect(wrapper.find(Form.Control).find('option').at(dateOptionValues.length).text()).toEqual('');
    expect(wrapper.find(Form.Control).find('option').at(dateOptionValues.length).prop('value')).toEqual(undefined);
    expect(wrapper.find(DateInput).length).toEqual(1);
    expect(wrapper.find(DateInput).prop('date')).toEqual(moment(new Date()).format('YYYY-MM-DD'));
    expect(wrapper.find('.text-center').exists()).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
  });

  it('Properly renders advanced filter date type statement with single date where blank is not supported', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterEnrolledDateBefore.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterEnrolledDateBefore.filterOption.name);
    wrapper.find('.advanced-filter-date-options').simulate('change', { target: { value: 'before' } });
    expect(wrapper.find(Form.Control).length).toEqual(1);
    expect(wrapper.find(Form.Control).prop('value')).toEqual('before');
    expect(wrapper.find(Form.Control).find('option').length).toEqual(dateOptionValues.length);
    dateOptionValues.forEach((value, index) => {
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
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterSymptomOnsetDateWithin.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterSymptomOnsetDateWithin.filterOption.name);
    expect(wrapper.find(Form.Control).length).toEqual(1);
    expect(wrapper.find(Form.Control).prop('value')).toEqual('within');
    expect(wrapper.find(Form.Control).find('option').length).toEqual(dateOptionValues.length + 1);
    dateOptionValues.forEach((value, index) => {
      expect(wrapper.find(Form.Control).find('option').at(index).text()).toEqual(value);
      expect(wrapper.find(Form.Control).find('option').at(index).prop('value')).toEqual(value);
    });
    expect(wrapper.find(Form.Control).find('option').at(dateOptionValues.length).text()).toEqual('');
    expect(wrapper.find(Form.Control).find('option').at(dateOptionValues.length).prop('value')).toEqual(undefined);
    expect(wrapper.find(DateInput).length).toEqual(2);
    expect(wrapper.find(DateInput).at(0).prop('date')).toEqual(moment(new Date()).subtract(3, 'd').format('YYYY-MM-DD'));
    expect(wrapper.find('.text-center').find('b').text()).toEqual('TO');
    expect(wrapper.find(DateInput).at(1).prop('date')).toEqual(moment(new Date()).format('YYYY-MM-DD'));
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
  });

  it('Properly renders advanced filter relative type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterLatestReportRelativeCustomPast.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterLatestReportRelativeCustomPast.filterOption.name);
    expect(wrapper.find(Form.Control).length).toEqual(1);
    expect(wrapper.find('.advanced-filter-relative-options').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual('today');
    expect(wrapper.find('.advanced-filter-relative-options').find('option').length).toEqual(relativeOptionValues.length);
    relativeOptionValues.forEach((value, index) => {
      expect(wrapper.find('.advanced-filter-relative-options').find('option').at(index).text()).toEqual(value);
      expect(wrapper.find('.advanced-filter-relative-options').find('option').at(index).prop('value')).toEqual(value);
    });
    expect(wrapper.find('.advanced-filter-operator-input').exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-number-input').exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-unit-input').exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-when-input').exists()).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
  });

  it('Properly renders advanced filter relative type custom statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterSymptomOnsetRelativeCustomPast.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterSymptomOnsetRelativeCustomPast.filterOption.name);
    wrapper.find('.advanced-filter-relative-options').simulate('change', { target: { value: 'custom' } });
    expect(wrapper.find(Form.Control).length).toEqual(5);
    expect(wrapper.find('.advanced-filter-relative-options').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual('custom');
    expect(wrapper.find('.advanced-filter-relative-options').find('option').length).toEqual(relativeOptionValues.length);
    relativeOptionValues.forEach((value, index) => {
      expect(wrapper.find('.advanced-filter-relative-options').find('option').at(index).text()).toEqual(value);
      expect(wrapper.find('.advanced-filter-relative-options').find('option').at(index).prop('value')).toEqual(value);
    });
    expect(wrapper.find('.advanced-filter-operator-input').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-operator-input').prop('value')).toEqual(mockFilterSymptomOnsetRelativeCustomPast.value.operator);
    expect(wrapper.find('.advanced-filter-operator-input').find('option').length).toEqual(relativeOptionOperatorValues.length);
    relativeOptionOperatorValues.forEach((value, index) => {
      expect(wrapper.find('.advanced-filter-operator-input').find('option').at(index).text()).toEqual(value.replace('-', ' '));
      expect(wrapper.find('.advanced-filter-operator-input').find('option').at(index).prop('value')).toEqual(value);
    });
    expect(wrapper.find('.advanced-filter-number-input').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterSymptomOnsetRelativeCustomPast.value.number);
    expect(wrapper.find('.advanced-filter-unit-input').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-unit-input').prop('value')).toEqual(mockFilterSymptomOnsetRelativeCustomPast.value.unit);
    expect(wrapper.find('.advanced-filter-unit-input').find('option').length).toEqual(relativeOptionUnitValues.length);
    relativeOptionUnitValues.forEach((value, index) => {
      expect(wrapper.find('.advanced-filter-unit-input').find('option').at(index).text()).toEqual(value);
      expect(wrapper.find('.advanced-filter-unit-input').find('option').at(index).prop('value')).toEqual(value.replace('(', '').replace(')', ''));
    });
    expect(wrapper.find('.advanced-filter-when-input').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-when-input').prop('value')).toEqual(mockFilterSymptomOnsetRelativeCustomPast.value.when);
    expect(wrapper.find('.advanced-filter-when-input').find('option').length).toEqual(relativeOptionWhenValues.length);
    relativeOptionWhenValues.forEach((value, index) => {
      expect(wrapper.find('.advanced-filter-when-input').find('option').at(index).text()).toEqual(`in the ${value}`);
      expect(wrapper.find('.advanced-filter-when-input').find('option').at(index).prop('value')).toEqual(value);
    });
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
  });

  it('Properly renders advanced filter search type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterAddressForeign.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterAddressForeign.filterOption.name);
    expect(wrapper.find(Form.Control).length).toEqual(1);
    expect(wrapper.find(Form.Control).hasClass('advanced-filter-search-input')).toBeTruthy();
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual('');
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Properly renders advanced filter type with additional dropdown options statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterManualContactAttemptsLessThan.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterManualContactAttemptsLessThan.filterOption.name);
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-additional-filter-options').prop('value')).toEqual(mockFilterManualContactAttemptsLessThan.filterOption.options[0]);
    expect(wrapper.find('.advanced-filter-additional-filter-options').find('option').length).toEqual(mockFilterManualContactAttemptsLessThan.filterOption.options.length);
    mockFilterManualContactAttemptsLessThan.filterOption.options.forEach((option, index) => {
      expect(wrapper.find('.advanced-filter-additional-filter-options').find('option').at(index).text()).toEqual(option);
      expect(wrapper.find('.advanced-filter-additional-filter-options').find('option').at(index).prop('value')).toEqual(option);
    });
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Properly renders tooltip when defined with advanced filter option', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterSevenDayQuarantine.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterSevenDayQuarantine.filterOption.name);
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(mockFilterSevenDayQuarantine.filterOption.tooltip);
  });

  it('Properly renders main components of advanced filter combination type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterLabResults.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterLabResults.filterOption.name);
    expect(wrapper.find('.advanced-filter-combination-type-statement').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-combination-type-statement').length).toEqual(1);
    expect(wrapper.find('.advanced-filter-combination-options').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-combination-options').prop('value')).toEqual(mockFilterLabResults.filterOption.fields[0].name);
    expect(wrapper.find('.advanced-filter-combination-options').find('option').length).toEqual(mockFilterLabResults.filterOption.fields.length);
    mockFilterLabResults.filterOption.fields.forEach((field, index) => {
      expect(wrapper.find('.advanced-filter-combination-options').find('option').at(index).text()).toEqual(field.title);
      expect(wrapper.find('.advanced-filter-combination-options').find('option').at(index).prop('value')).toEqual(field.name);
      expect(wrapper.find('.advanced-filter-combination-options').find('option').at(index).prop('disabled')).toBeFalsy();
    });
    expect(wrapper.find('.advanced-filter-combination-type-statement').find(Button).length).toEqual(2);
    expect(wrapper.find('.advanced-filter-combination-type-statement').find(Button).at(0).find('i').hasClass('fa-plus')).toBeTruthy();
    expect(wrapper.find('.advanced-filter-combination-type-statement').find(Button).at(1).find('i').hasClass('fa-minus')).toBeTruthy();
    expect(wrapper.find('.advanced-filter-additional-filter-options').exists()).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).length).toEqual(2);
    expect(wrapper.find(ReactTooltip).at(0).find('span').text()).toEqual('Select to add multiple Lab Result search criteria.');
    expect(wrapper.find(ReactTooltip).at(1).find('span').text()).toEqual(mockFilterLabResults.filterOption.tooltip);
  });

  it('Properly renders select option of advanced filter combination type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterLabResults.filterOption.name });
    expect(wrapper.find('.advanced-filter-combination-type-statement').find(Form.Control).length).toEqual(2);
    expect(wrapper.find('.advanced-filter-combination-options').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-combination-select-options').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-date-options').exists()).toBeFalsy();
    expect(wrapper.find(DateInput).exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-combination-select-options').prop('value')).toEqual(mockFilterLabResults.filterOption.fields[0].options[0]);
    expect(wrapper.find('.advanced-filter-combination-select-options').find('option').length).toEqual(mockFilterLabResults.filterOption.fields[0].options.length);
    mockFilterLabResults.filterOption.fields[0].options.forEach((option, index) => {
      expect(wrapper.find('.advanced-filter-combination-select-options').find('option').at(index).text()).toEqual(option);
      expect(wrapper.find('.advanced-filter-combination-select-options').find('option').at(index).prop('disabled')).toBeFalsy();
    });
  });

  it('Properly renders date option of advanced filter combination type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterLabResults.filterOption.name });
    wrapper.find('.advanced-filter-combination-options').simulate('change', { target: { value: 'report' } });
    expect(wrapper.find('.advanced-filter-combination-type-statement').find(Form.Control).length).toEqual(2);
    expect(wrapper.find('.advanced-filter-combination-options').exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-combination-select-options').exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-date-options').exists()).toBeTruthy();
    expect(wrapper.find(DateInput).exists()).toBeTruthy();
    expect(wrapper.find('.advanced-filter-date-options').prop('value')).toEqual(combinationDateOptionValues[0]);
    expect(wrapper.find('.advanced-filter-date-options').find('option').length).toEqual(combinationDateOptionValues.length);
    combinationDateOptionValues.forEach((value, index) => {
      expect(wrapper.find('.advanced-filter-date-options').find('option').at(index).text()).toEqual(value);
      expect(wrapper.find('.advanced-filter-date-options').find('option').at(index).prop('disabled')).toBeFalsy();
    });
    expect(wrapper.find('.advanced-filter-combination-type-statement').find(DateInput).prop('date')).toEqual(moment().format('YYYY-MM-DD'));
  });

  it('Clicking the combination type "+" button adds another combination statement and displays "AND" row', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterLabResults.filterOption.name });
    _.times(mockFilterLabResults.filterOption.fields.length - 1, i => {
      expect(wrapper.find('.advanced-filter-combination-type-statement').length).toEqual(i + 1);
      expect(wrapper.find('.and-row').length).toEqual(i);
      expect(wrapper.find('#lab-result-0-combination-add').exists()).toBeTruthy();
      wrapper.find('.btn-circle').simulate('click');
    });
    expect(wrapper.find('.advanced-filter-combination-type-statement').length).toEqual(mockFilterLabResults.filterOption.fields.length);
    expect(wrapper.find('.and-row').length).toEqual(mockFilterLabResults.filterOption.fields.length - 1);
    expect(wrapper.find('#lab-result-0-combination-add').exists()).toBeFalsy();
  });

  it('Adding additional fields to combination filter does not allow for repeats', () => {
    const wrapper = getWrapper();
    let activeCombinationValues = [];
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterLabResults.filterOption.name });
    _.times(mockFilterLabResults.filterOption.fields.length, i => {
      activeCombinationValues.push(mockFilterLabResults.filterOption.fields[Number(i)].name);
      expect(wrapper.find('.advanced-filter-combination-type-statement').length).toEqual(i + 1);
      wrapper.find('.advanced-filter-combination-type-statement').forEach(statement => {
        let statementValue = statement.find('.advanced-filter-combination-options').prop('value');
        expect(activeCombinationValues.filter(value => value === statementValue).length).toEqual(1);
        statement
          .find('.advanced-filter-combination-options')
          .find('option')
          .forEach(option => {
            let optionValue = option.prop('value');
            expect(option.prop('disabled')).toEqual(activeCombinationValues.includes(optionValue) && optionValue !== statementValue);
          });
      });
      if (i < mockFilterLabResults.filterOption.fields.length - 1) {
        wrapper.find('.btn-circle').simulate('click');
      }
    });
    _.times(mockFilterLabResults.filterOption.fields.length - 1, i => {
      let random = _.random(0, wrapper.find('.remove-filter-row').length - 1);
      activeCombinationValues = activeCombinationValues.slice(0, random).concat(activeCombinationValues.slice(random + 1, activeCombinationValues.length));
      wrapper.find('.remove-filter-row').at(random).simulate('click');
      expect(wrapper.find('.advanced-filter-combination-type-statement').length).toEqual(mockFilterLabResults.filterOption.fields.length - 1 - i);
      wrapper.find('.advanced-filter-combination-type-statement').forEach(statement => {
        let statementValue = statement.find('.advanced-filter-combination-options').prop('value');
        expect(activeCombinationValues.filter(value => value === statementValue).length).toEqual(1);
        statement
          .find('.advanced-filter-combination-options')
          .find('option')
          .forEach(option => {
            let optionValue = option.prop('value');
            expect(option.prop('disabled')).toEqual(activeCombinationValues.includes(optionValue) && optionValue !== statementValue);
          });
      });
    });
  });

  it('Removes the combination type "+" button when all the filter option fields are displayed', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterLabResults.filterOption.name });
    _.times(mockFilterLabResults.filterOption.fields.length - 1, () => {
      expect(wrapper.find('.advanced-filter-combination-type-statement').find('.btn-circle').exists()).toBeTruthy();
      wrapper.find('.btn-circle').simulate('click');
    });
    expect(wrapper.find('.advanced-filter-combination-type-statement').find('.btn-circle').exists()).toBeFalsy();
  });

  it('Clicking the combination type "-" removes combination statements until there is one left, then removed the entire filter statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterLabResults.filterOption.name });
    _.times(mockFilterLabResults.filterOption.fields.length - 1, () => {
      wrapper.find('.btn-circle').simulate('click');
    });
    _.times(mockFilterLabResults.filterOption.fields.length, i => {
      let random = _.random(0, wrapper.find('.remove-filter-row').length - 1);
      expect(wrapper.find('.advanced-filter-statement').length).toEqual(1);
      expect(wrapper.find('.advanced-filter-combination-type-statement').length).toEqual(mockFilterLabResults.filterOption.fields.length - i);
      wrapper.find('.remove-filter-row').at(random).simulate('click');
    });
    expect(wrapper.find('.advanced-filter-statement').exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-combination-type-statement').exists()).toBeFalsy();
  });

  it('Clicking the combination type "+" and "-" properly updates state and value', () => {
    const wrapper = getWrapper();
    let activeCombinationValues = [];
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterLabResults.filterOption.name });
    _.times(mockFilterLabResults.filterOption.fields.length, i => {
      let newField = mockFilterLabResults.filterOption.fields[Number(i)];
      let newValue = newField.type === 'select' ? newField.options[0] : { when: 'before', date: moment().format('YYYY-MM-DD') };
      activeCombinationValues.push({ name: newField.name, value: newValue });
      expect(wrapper.find('.advanced-filter-combination-type-statement').length).toEqual(i + 1);
      expect(wrapper.state('activeFilterOptions')[0].value.length).toEqual(i + 1);
      expect(wrapper.state('activeFilterOptions')[0].value).toEqual(activeCombinationValues);
      wrapper.find('.advanced-filter-combination-type-statement').forEach((statement, index) => {
        expect(statement.find('.advanced-filter-combination-options').prop('value')).toEqual(activeCombinationValues[Number(index)].name);
        if (mockFilterLabResults.filterOption.fields.filter(field => field.name === activeCombinationValues[Number(index)].name).type === 'select') {
          expect(statement.find('.advanced-filter-combination-select-options').prop('value')).toEqual(activeCombinationValues[Number(index)].value);
        } else if (mockFilterLabResults.filterOption.fields.filter(field => field.name === activeCombinationValues[Number(index)].name).type === 'date') {
          expect(statement.find('.advanced-filter-date-options').prop('value')).toEqual(activeCombinationValues[Number(index)].value.when);
          expect(statement.find(DateInput).prop('date')).toEqual(activeCombinationValues[Number(index)].value.date);
        }
      });
      if (i < mockFilterLabResults.filterOption.fields.length - 1) {
        wrapper.find('.btn-circle').simulate('click');
      }
    });
    _.times(mockFilterLabResults.filterOption.fields.length - 1, i => {
      let random = _.random(0, wrapper.find('.remove-filter-row').length - 1);
      activeCombinationValues = activeCombinationValues.slice(0, random).concat(activeCombinationValues.slice(random + 1, activeCombinationValues.length));
      wrapper.find('.remove-filter-row').at(random).simulate('click');
      expect(wrapper.find('.advanced-filter-combination-type-statement').length).toEqual(mockFilterLabResults.filterOption.fields.length - 1 - i);
      expect(wrapper.state('activeFilterOptions')[0].value.length).toEqual(mockFilterLabResults.filterOption.fields.length - 1 - i);
      expect(wrapper.state('activeFilterOptions')[0].value).toEqual(activeCombinationValues);
      wrapper.find('.advanced-filter-combination-type-statement').forEach((statement, index) => {
        expect(statement.find('.advanced-filter-combination-options').prop('value')).toEqual(activeCombinationValues[Number(index)].name);
        if (mockFilterLabResults.filterOption.fields.filter(field => field.name === activeCombinationValues[Number(index)].name).type === 'select') {
          expect(statement.find('.advanced-filter-combination-select-options').prop('value')).toEqual(activeCombinationValues[Number(index)].value);
        } else if (mockFilterLabResults.filterOption.fields.filter(field => field.name === activeCombinationValues[Number(index)].name).type === 'date') {
          expect(statement.find('.advanced-filter-date-options').prop('value')).toEqual(activeCombinationValues[Number(index)].value.when);
          expect(statement.find(DateInput).prop('date')).toEqual(activeCombinationValues[Number(index)].value.date);
        }
      });
    });
  });

  it('Changing the combination type dropdowns and date inputs properly updates', () => {
    const wrapper = getWrapper();
    const selectField = mockFilterLabResults.filterOption.fields.filter(field => field.type === 'select')[0];
    const dateField = mockFilterLabResults.filterOption.fields.filter(field => field.type === 'date')[0];
    const random = _.random(0, selectField.length - 1);
    const initialDate = moment().format('YYYY-MM-DD');
    const newDate = moment(new Date()).subtract(14, 'd').format('YYYY-MM-DD');

    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterLabResults.filterOption.name });
    wrapper.find('.advanced-filter-combination-options').simulate('change', { target: { value: selectField.name } });
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual([{ name: selectField.name, value: selectField.options[0] }]);
    expect(wrapper.find('.advanced-filter-combination-options').prop('value')).toEqual(selectField.name);
    expect(wrapper.find('.advanced-filter-combination-select-options').prop('value')).toEqual(selectField.options[0]);

    wrapper.find('.advanced-filter-combination-select-options').simulate('change', { target: { value: selectField.options[`${random}`] } });
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual([{ name: selectField.name, value: selectField.options[`${random}`] }]);
    expect(wrapper.find('.advanced-filter-combination-options').prop('value')).toEqual(selectField.name);
    expect(wrapper.find('.advanced-filter-combination-select-options').prop('value')).toEqual(selectField.options[`${random}`]);

    wrapper.find('.advanced-filter-combination-options').simulate('change', { target: { value: dateField.name } });
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual([{ name: dateField.name, value: { when: combinationDateOptionValues[0], date: initialDate } }]);
    expect(wrapper.find('.advanced-filter-combination-options').prop('value')).toEqual(dateField.name);
    expect(wrapper.find('.advanced-filter-date-options').prop('value')).toEqual(combinationDateOptionValues[0]);
    expect(wrapper.find(DateInput).prop('date')).toEqual(initialDate);

    wrapper.find('.advanced-filter-date-options').simulate('change', { target: { value: combinationDateOptionValues[1] } });
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual([{ name: dateField.name, value: { when: combinationDateOptionValues[1], date: initialDate } }]);
    expect(wrapper.find('.advanced-filter-combination-options').prop('value')).toEqual(dateField.name);
    expect(wrapper.find('.advanced-filter-date-options').prop('value')).toEqual(combinationDateOptionValues[1]);
    expect(wrapper.find(DateInput).prop('date')).toEqual(initialDate);

    wrapper.find(DateInput).simulate('change', newDate);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual([{ name: dateField.name, value: { when: combinationDateOptionValues[1], date: newDate } }]);
    expect(wrapper.find('.advanced-filter-combination-options').prop('value')).toEqual(dateField.name);
    expect(wrapper.find('.advanced-filter-date-options').prop('value')).toEqual(combinationDateOptionValues[1]);
    expect(wrapper.find(DateInput).prop('date')).toEqual(newDate);

    wrapper.find('.advanced-filter-date-options').simulate('change', { target: { value: combinationDateOptionValues[0] } });
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual([{ name: dateField.name, value: { when: combinationDateOptionValues[0], date: newDate } }]);
    expect(wrapper.find('.advanced-filter-combination-options').prop('value')).toEqual(dateField.name);
    expect(wrapper.find('.advanced-filter-date-options').prop('value')).toEqual(combinationDateOptionValues[0]);
    expect(wrapper.find(DateInput).prop('date')).toEqual(newDate);

    wrapper.find('.advanced-filter-combination-options').simulate('change', { target: { value: selectField.name } });
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual([{ name: selectField.name, value: selectField.options[0] }]);
    expect(wrapper.find('.advanced-filter-combination-options').prop('value')).toEqual(selectField.name);
    expect(wrapper.find('.advanced-filter-combination-select-options').prop('value')).toEqual(selectField.options[0]);
  });

  it('Properly renders advanced filter multi-select type statement', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterAssignedUser.filterOption.name });
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterAssignedUser.filterOption.name);
    expect(wrapper.find('.advanced-filter-multi-select').exists()).toBe(true);
    expect(wrapper.find('.advanced-filter-multi-select').length).toEqual(1);
    expect(wrapper.find('.advanced-filter-multi-select').prop('value')).toEqual([]);
    mockFilterAssignedUser.filterOption.options.forEach((value, index) => {
      expect(wrapper.find('.advanced-filter-multi-select').find('options').at(index).prop('value')).toEqual(value.value);
      expect(wrapper.find('.advanced-filter-multi-select').find('options').at(index).prop('label')).toEqual(value.label);
    });
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual('If multiple Assigned Users are selected, records assigned to any of those users will be returned. Only Assigned User values currently listed in a record are selectable. Leaving this field blank will not filter out any monitorees.');
  });

  it('Toggling boolean buttons properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterMonitoringStatusFalse.filterOption.name });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterMonitoringStatusTrue]);
    expect(wrapper.find('.advanced-filter-boolean-true').prop('checked')).toBeTruthy();
    expect(wrapper.find('.advanced-filter-boolean-false').prop('checked')).toBeFalsy();
    wrapper.find('.advanced-filter-boolean-false').simulate('change');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterMonitoringStatusFalse]);
    expect(wrapper.find('.advanced-filter-boolean-true').prop('checked')).toBeFalsy();
    expect(wrapper.find('.advanced-filter-boolean-false').prop('checked')).toBeTruthy();
    wrapper.find('.advanced-filter-boolean-true').simulate('change');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterMonitoringStatusTrue]);
    expect(wrapper.find('.advanced-filter-boolean-true').prop('checked')).toBeTruthy();
    expect(wrapper.find('.advanced-filter-boolean-false').prop('checked')).toBeFalsy();
  });

  it('Changing advanced filter option dropdown properly updates state and value', () => {
    const wrapper = getWrapper();
    const randomNumber = _.random(0, mockFilterPreferredContactTime.filterOption.options.length - 1);
    let newMockFilterOptionsOption = _.clone(mockFilterPreferredContactTime);
    newMockFilterOptionsOption.value = mockFilterPreferredContactTime.filterOption.options[Number(randomNumber)];
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterPreferredContactTime.filterOption.name });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterPreferredContactTime]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterPreferredContactTime.filterOption.options[0]);
    wrapper.find(Form.Control).simulate('change', { target: { value: mockFilterPreferredContactTime.filterOption.options[Number(randomNumber)] } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([newMockFilterOptionsOption]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterPreferredContactTime.filterOption.options[Number(randomNumber)]);
    wrapper.find(Form.Control).simulate('change', { target: { value: mockFilterPreferredContactTime.filterOption.options[0] } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterPreferredContactTime]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterPreferredContactTime.filterOption.options[0]);
  });

  it('Changing advanced filter numberOption and value for number type advanced filters properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterAgeBetween.filterOption.name });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterAgeEqual]);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterAgeEqual.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterAgeEqual.value);
    wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: 12 } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].numberOption).toEqual(mockFilterAgeEqual.numberOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(12);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterAgeEqual.numberOption);
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
    wrapper
      .find('.advanced-filter-number-input')
      .at(1)
      .simulate('change', { target: { value: mockFilterAgeBetween.value.secondBound } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].numberOption).toEqual('between');
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual({ firstBound: 0, secondBound: mockFilterAgeBetween.value.secondBound });
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual('between');
    expect(wrapper.find('.advanced-filter-number-input').at(0).prop('value')).toEqual(0);
    expect(wrapper.find('.advanced-filter-number-input').at(1).prop('value')).toEqual(mockFilterAgeBetween.value.secondBound);
    wrapper
      .find('.advanced-filter-number-input')
      .at(0)
      .simulate('change', { target: { value: 20 } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterAgeBetween]);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual('between');
    expect(wrapper.find('.advanced-filter-number-input').at(0).prop('value')).toEqual(mockFilterAgeBetween.value.firstBound);
    expect(wrapper.find('.advanced-filter-number-input').at(1).prop('value')).toEqual(mockFilterAgeBetween.value.secondBound);
    wrapper.find('.advanced-filter-number-options').simulate('change', { target: { value: 'equal' } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterAgeEqual]);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterAgeEqual.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterAgeEqual.value);
  });

  it('Changing advanced filter dateOption and values for date type advanced filters properly updates state and value', () => {
    const wrapper = getWrapper();
    const newDate = moment(new Date()).subtract(14, 'd').format('YYYY-MM-DD');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterSymptomOnsetDateWithin.filterOption.name });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterSymptomOnsetDateWithin]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterSymptomOnsetDateWithin.dateOption);
    expect(wrapper.find(DateInput).at(0).prop('date')).toEqual(mockFilterSymptomOnsetDateWithin.value.start);
    expect(wrapper.find(DateInput).at(1).prop('date')).toEqual(mockFilterSymptomOnsetDateWithin.value.end);
    wrapper.find(DateInput).at(0).simulate('change', newDate);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].dateOption).toEqual(mockFilterSymptomOnsetDateWithin.dateOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual({ start: newDate, end: mockFilterSymptomOnsetDateWithin.value.end });
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterSymptomOnsetDateWithin.dateOption);
    expect(wrapper.find(DateInput).at(0).prop('date')).toEqual(newDate);
    expect(wrapper.find(DateInput).at(1).prop('date')).toEqual(mockFilterSymptomOnsetDateWithin.value.end);
    wrapper.find(DateInput).at(1).simulate('change', mockFilterSymptomOnsetDateWithin.value.start);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].dateOption).toEqual(mockFilterSymptomOnsetDateWithin.dateOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual({ start: newDate, end: mockFilterSymptomOnsetDateWithin.value.start });
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterSymptomOnsetDateWithin.dateOption);
    expect(wrapper.find(DateInput).at(0).prop('date')).toEqual(newDate);
    expect(wrapper.find(DateInput).at(1).prop('date')).toEqual(mockFilterSymptomOnsetDateWithin.value.start);
    wrapper.find(Form.Control).simulate('change', { target: { value: mockFilterEnrolledDateBefore.dateOption } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].dateOption).toEqual(mockFilterEnrolledDateBefore.dateOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(mockFilterSymptomOnsetDateWithin.value.end);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterEnrolledDateBefore.dateOption);
    expect(wrapper.find(DateInput).prop('date')).toEqual(mockFilterSymptomOnsetDateWithin.value.end);
    wrapper.find(DateInput).simulate('change', mockFilterEnrolledDateBefore.value);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].dateOption).toEqual(mockFilterEnrolledDateBefore.dateOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(mockFilterEnrolledDateBefore.value);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterEnrolledDateBefore.dateOption);
    expect(wrapper.find(DateInput).prop('date')).toEqual(mockFilterEnrolledDateBefore.value);
    wrapper.find(Form.Control).simulate('change', { target: { value: mockFilterSymptomOnsetDateBlank.dateOption } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].dateOption).toEqual(mockFilterSymptomOnsetDateBlank.dateOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(mockFilterSymptomOnsetDateBlank.value);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterSymptomOnsetDateBlank.dateOption);
    expect(wrapper.find(DateInput).exists()).toBeFalsy();
  });

  it('Changing advanced filter relativeOption and values for relative type advanced filters properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterLatestReportRelativeToday.filterOption.name });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterLatestReportRelativeToday]);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterLatestReportRelativeToday.relativeOption);
    wrapper.find('.advanced-filter-relative-options').simulate('change', { target: { value: mockFilterLatestReportRelativeYesterday.relativeOption } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterLatestReportRelativeYesterday]);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterLatestReportRelativeYesterday.relativeOption);
    wrapper.find('.advanced-filter-relative-options').simulate('change', { target: { value: mockFilterLatestReportRelativeCustomPast.relativeOption } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterLatestReportRelativeCustomPast]);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterLatestReportRelativeCustomPast.relativeOption);
    wrapper.find('.advanced-filter-operator-input').simulate('change', { target: { value: mockFilterLatestReportRelativeCustomFuture.value.operator } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].relativeOption).toEqual(mockFilterLatestReportRelativeCustomFuture.relativeOption);
    expect(wrapper.state('activeFilterOptions')[0].value.operator).toEqual(mockFilterLatestReportRelativeCustomFuture.value.operator);
    expect(wrapper.state('activeFilterOptions')[0].value.number).toEqual(mockFilterLatestReportRelativeCustomPast.value.number);
    expect(wrapper.state('activeFilterOptions')[0].value.unit).toEqual(mockFilterLatestReportRelativeCustomPast.value.unit);
    expect(wrapper.state('activeFilterOptions')[0].value.when).toEqual(mockFilterLatestReportRelativeCustomPast.value.when);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterLatestReportRelativeCustomFuture.relativeOption);
    expect(wrapper.find('.advanced-filter-operator-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomFuture.value.operator);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomPast.value.number);
    expect(wrapper.find('.advanced-filter-unit-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomPast.value.unit);
    expect(wrapper.find('.advanced-filter-when-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomPast.value.when);
    wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: mockFilterLatestReportRelativeCustomFuture.value.number } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].relativeOption).toEqual(mockFilterLatestReportRelativeCustomFuture.relativeOption);
    expect(wrapper.state('activeFilterOptions')[0].value.operator).toEqual(mockFilterLatestReportRelativeCustomFuture.value.operator);
    expect(wrapper.state('activeFilterOptions')[0].value.number).toEqual(mockFilterLatestReportRelativeCustomFuture.value.number);
    expect(wrapper.state('activeFilterOptions')[0].value.unit).toEqual(mockFilterLatestReportRelativeCustomPast.value.unit);
    expect(wrapper.state('activeFilterOptions')[0].value.when).toEqual(mockFilterLatestReportRelativeCustomPast.value.when);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterLatestReportRelativeCustomFuture.relativeOption);
    expect(wrapper.find('.advanced-filter-operator-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomFuture.value.operator);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomFuture.value.number);
    expect(wrapper.find('.advanced-filter-unit-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomPast.value.unit);
    expect(wrapper.find('.advanced-filter-when-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomPast.value.when);
    wrapper.find('.advanced-filter-unit-input').simulate('change', { target: { value: mockFilterLatestReportRelativeCustomFuture.value.unit } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].relativeOption).toEqual(mockFilterLatestReportRelativeCustomFuture.relativeOption);
    expect(wrapper.state('activeFilterOptions')[0].value.operator).toEqual(mockFilterLatestReportRelativeCustomFuture.value.operator);
    expect(wrapper.state('activeFilterOptions')[0].value.number).toEqual(mockFilterLatestReportRelativeCustomFuture.value.number);
    expect(wrapper.state('activeFilterOptions')[0].value.unit).toEqual(mockFilterLatestReportRelativeCustomFuture.value.unit);
    expect(wrapper.state('activeFilterOptions')[0].value.when).toEqual(mockFilterLatestReportRelativeCustomPast.value.when);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterLatestReportRelativeCustomFuture.relativeOption);
    expect(wrapper.find('.advanced-filter-operator-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomFuture.value.operator);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomFuture.value.number);
    expect(wrapper.find('.advanced-filter-unit-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomFuture.value.unit);
    expect(wrapper.find('.advanced-filter-when-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomPast.value.when);
    wrapper.find('.advanced-filter-when-input').simulate('change', { target: { value: mockFilterLatestReportRelativeCustomFuture.value.when } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterLatestReportRelativeCustomFuture]);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterLatestReportRelativeCustomFuture.relativeOption);
    expect(wrapper.find('.advanced-filter-operator-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomFuture.value.operator);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomFuture.value.number);
    expect(wrapper.find('.advanced-filter-unit-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomFuture.value.unit);
    expect(wrapper.find('.advanced-filter-when-input').prop('value')).toEqual(mockFilterLatestReportRelativeCustomFuture.value.when);
    wrapper.find('.advanced-filter-relative-options').simulate('change', { target: { value: mockFilterLatestReportRelativeToday.relativeOption } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterLatestReportRelativeToday]);
    expect(wrapper.find('.advanced-filter-relative-options').prop('value')).toEqual(mockFilterLatestReportRelativeToday.relativeOption);
  });

  it('Changing input text for search type advanced filter properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterAddressForeign.filterOption.name });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterAddressForeignEmpty]);
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual('');
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: mockFilterAddressForeign.value } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterAddressForeign]);
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual(mockFilterAddressForeign.value);
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: '' } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterAddressForeignEmpty]);
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual('');
  });

  it('Changing additional options dropdown properly updates state and value', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterManualContactAttemptsLessThan.filterOption.name });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterManualContactAttemptsEqual]);
    expect(wrapper.find('.advanced-filter-additional-filter-options').prop('value')).toEqual(mockFilterManualContactAttemptsLessThan.filterOption.options[0]);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterManualContactAttemptsEqual.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterManualContactAttemptsEqual.value);
    wrapper.find('.advanced-filter-additional-filter-options').simulate('change', { target: { value: mockFilterManualContactAttemptsLessThan.additionalFilterOption } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].additionalFilterOption).toEqual(mockFilterManualContactAttemptsLessThan.additionalFilterOption);
    expect(wrapper.state('activeFilterOptions')[0].numberOption).toEqual(mockFilterManualContactAttemptsEqual.numberOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(mockFilterManualContactAttemptsEqual.value);
    expect(wrapper.find('.advanced-filter-additional-filter-options').prop('value')).toEqual(mockFilterManualContactAttemptsLessThan.additionalFilterOption);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterManualContactAttemptsEqual.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterManualContactAttemptsEqual.value);
    wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: 2 } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].additionalFilterOption).toEqual(mockFilterManualContactAttemptsLessThan.additionalFilterOption);
    expect(wrapper.state('activeFilterOptions')[0].numberOption).toEqual(mockFilterManualContactAttemptsEqual.numberOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(2);
    expect(wrapper.find('.advanced-filter-additional-filter-options').prop('value')).toEqual(mockFilterManualContactAttemptsLessThan.additionalFilterOption);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterManualContactAttemptsEqual.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(2);
    wrapper.find('.advanced-filter-additional-filter-options').simulate('change', { target: { value: 'Unsuccessful' } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].additionalFilterOption).toEqual('Unsuccessful');
    expect(wrapper.state('activeFilterOptions')[0].numberOption).toEqual(mockFilterManualContactAttemptsEqual.numberOption);
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(2);
    expect(wrapper.find('.advanced-filter-additional-filter-options').prop('value')).toEqual('Unsuccessful');
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterManualContactAttemptsEqual.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(2);
    wrapper.find('.advanced-filter-number-options').simulate('change', { target: { value: 'less-than' } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')[0].additionalFilterOption).toEqual('Unsuccessful');
    expect(wrapper.state('activeFilterOptions')[0].numberOption).toEqual('less-than');
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(2);
    expect(wrapper.find('.advanced-filter-additional-filter-options').prop('value')).toEqual('Unsuccessful');
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual('less-than');
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(2);
    wrapper.find('.advanced-filter-additional-filter-options').simulate('change', { target: { value: mockFilterManualContactAttemptsLessThan.additionalFilterOption } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterManualContactAttemptsLessThan]);
    expect(wrapper.find('.advanced-filter-additional-filter-options').prop('value')).toEqual(mockFilterManualContactAttemptsLessThan.additionalFilterOption);
    expect(wrapper.find('.advanced-filter-number-options').prop('value')).toEqual(mockFilterManualContactAttemptsLessThan.numberOption);
    expect(wrapper.find('.advanced-filter-number-input').prop('value')).toEqual(mockFilterManualContactAttemptsLessThan.value);
  });

  it('Relative date with timestamp custom tooltip dynamically updates as options change', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterLatestReportRelativeCustomPast.filterOption.name });
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    wrapper.find('.advanced-filter-relative-options').simulate('change', { target: { value: 'custom' } });
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`The current setting of "less than 1 days in the past" will return records with Latest Report date from the current time on ${moment(new Date()).subtract(1, 'd').format('MM/DD/YY')} through now. To filter between two dates, use the "greater than" and "less than" filters in combination.`);
    wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: 3 } });
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`The current setting of "less than 3 days in the past" will return records with Latest Report date from the current time on ${moment(new Date()).subtract(3, 'd').format('MM/DD/YY')} through now. To filter between two dates, use the "greater than" and "less than" filters in combination.`);
    wrapper.find('.advanced-filter-unit-input').simulate('change', { target: { value: 'weeks' } });
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`The current setting of "less than 3 weeks in the past" will return records with Latest Report date from the current time on ${moment(new Date()).subtract(3, 'weeks').format('MM/DD/YY')} through now. To filter between two dates, use the "greater than" and "less than" filters in combination.`);
    wrapper.find('.advanced-filter-operator-input').simulate('change', { target: { value: 'greater-than' } });
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`The current setting of "greater than 3 weeks in the past" will return records with Latest Report date before the current time on ${moment(new Date()).subtract(3, 'w').format('MM/DD/YY')}. To filter between two dates, use the "greater than" and "less than" filters in combination.`);
    wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: 1 } });
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`The current setting of "greater than 1 weeks in the past" will return records with Latest Report date before the current time on ${moment(new Date()).subtract(1, 'w').format('MM/DD/YY')}. To filter between two dates, use the "greater than" and "less than" filters in combination.`);
  });

  it('Relative date without timestamp custom tooltip dynamically updates as options change', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterSymptomOnsetRelativeCustomPast.filterOption.name });
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
    wrapper.find('.advanced-filter-relative-options').simulate('change', { target: { value: 'custom' } });
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`The current setting of "less than 1 days in the past" will return records with Symptom Onset date of today. To filter between two dates, use the "greater than" and "less than" filters in combination.`);
    wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: 3 } });
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`The current setting of "less than 3 days in the past" will return records with Symptom Onset date from ${moment(new Date()).subtract(3, 'd').add(1, 'd').format('MM/DD/YY')} through ${moment(new Date()).format('MM/DD/YY')}. To filter between two dates, use the "greater than" and "less than" filters in combination.`);
    wrapper.find('.advanced-filter-unit-input').simulate('change', { target: { value: 'weeks' } });
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`The current setting of "less than 3 weeks in the past" will return records with Symptom Onset date from ${moment(new Date()).subtract(3, 'w').add(1, 'd').format('MM/DD/YY')} through ${moment(new Date()).format('MM/DD/YY')}. To filter between two dates, use the "greater than" and "less than" filters in combination.`);
    wrapper.find('.advanced-filter-when-input').simulate('change', { target: { value: 'future' } });
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`The current setting of "less than 3 weeks in the future" will return records with Symptom Onset date from ${moment(new Date()).format('MM/DD/YY')} through ${moment(new Date()).add(3, 'w').subtract(1, 'd').format('MM/DD/YY')}. To filter between two dates, use the "greater than" and "less than" filters in combination.`);
    wrapper.find('.advanced-filter-number-input').simulate('change', { target: { value: 1 } });
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`The current setting of "less than 1 weeks in the future" will return records with Symptom Onset date from ${moment(new Date()).format('MM/DD/YY')} through ${moment(new Date()).add(1, 'w').subtract(1, 'd').format('MM/DD/YY')}. To filter between two dates, use the "greater than" and "less than" filters in combination.`);
    wrapper.find('.advanced-filter-operator-input').simulate('change', { target: { value: 'greater-than' } });
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`The current setting of "greater than 1 weeks in the future" will return records with Symptom Onset date after ${moment(new Date()).add(1, 'w').format('MM/DD/YY')}. To filter between two dates, use the "greater than" and "less than" filters in combination.`);
    wrapper.find('.advanced-filter-when-input').simulate('change', { target: { value: 'past' } });
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual(`The current setting of "greater than 1 weeks in the past" will return records with Symptom Onset date before ${moment(new Date()).subtract(1, 'w').format('MM/DD/YY')}. To filter between two dates, use the "greater than" and "less than" filters in combination.`);
  });

  it('Changing advanced filter multi-select selected options properly updates state and value', () => {
    const wrapper = getWrapper();
    let selectedOptions = [];
    let options = [
      { label: 1, value: 1 },
      { label: 2, value: 2 },
      { label: 3, value: 3 },
    ];

    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterAssignedUser.filterOption.name });

    _.times(options.length, i => {
      selectedOptions.push(options[Number(i)]);
      wrapper.find('.advanced-filter-multi-select').simulate('change', { value: selectedOptions });
      expect(wrapper.find('.advanced-filter-multi-select').prop('value').value).toEqual(selectedOptions);
    });

    _.times(options.length, () => {
      selectedOptions.pop();
      wrapper.find('.advanced-filter-multi-select').simulate('change', { value: selectedOptions });
      expect(wrapper.find('.advanced-filter-multi-select').prop('value').value).toEqual(selectedOptions);
    });
  });

  it('Changing advanced filter multi-select filter to another multi-select resets selected', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterAssignedUser.filterOption.name });
    expect(wrapper.find('.advanced-filter-multi-select').prop('value')).toEqual([]);
    wrapper.find('.advanced-filter-multi-select').simulate('change', { value: [{ value: 1, label: 1 }] });
    expect(wrapper.find('.advanced-filter-multi-select').prop('value').value).toEqual([{ value: 1, label: 1 }]);
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterJurisdiction.filterOption.name });
    expect(wrapper.find('.advanced-filter-multi-select').prop('value')).toEqual([]);
  });

  it('Clicking "Save" button opens Filter Name modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('#advanced-filter-modal').exists()).toBeTruthy();
    expect(wrapper.find('#filter-name-modal').exists()).toBeFalsy();
    expect(wrapper.state('showAdvancedFilterModal')).toBeTruthy();
    expect(wrapper.state('showFilterNameModal')).toBeFalsy();
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find('#filter-name-modal').exists()).toBeTruthy();
    expect(wrapper.find('#advanced-filter-modal').exists()).toBeFalsy();
    expect(wrapper.state('showAdvancedFilterModal')).toBeFalsy();
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
    expect(wrapper.state('showAdvancedFilterModal')).toBeFalsy();
    expect(wrapper.state('showFilterNameModal')).toBeTruthy();
    expect(wrapper.state('filterName')).toEqual('some filter name');
    expect(wrapper.find('#filter-name-input').prop('value')).toEqual('some filter name');
    wrapper.find('#filter-name-cancel').simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBeTruthy();
    expect(wrapper.state('showFilterNameModal')).toBeFalsy();
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBeFalsy();
    expect(wrapper.state('showFilterNameModal')).toBeTruthy();
    expect(wrapper.state('filterName')).toEqual(null);
    expect(wrapper.find('#filter-name-input').prop('value')).toEqual('');
  });

  it('Filter name is cleared when saving a new filter', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.state('filterName')).toEqual(null);
    wrapper.find('#filter-name-input').simulate('change', { target: { value: 'some filter name' } });
    expect(wrapper.state('filterName')).toEqual('some filter name');
    wrapper.find('#filter-name-save').simulate('click');
    expect(wrapper.state('filterName')).toEqual('some filter name');
    wrapper.find('#advanced-filter-cancel').simulate('click');
    expect(wrapper.state('filterName')).toEqual('some filter name');
    wrapper.find(Dropdown.Item).simulate('click');
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.state('filterName')).toEqual(null);
  });

  it('Opening Filter Name modal and clicking "Cancel" button maintains advanced filter modal state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterAddressForeign.filterOption.name });
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: mockFilterAddressForeign.value } });
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterAddressForeign]);
    expect(wrapper.state('showAdvancedFilterModal')).toBeTruthy();
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterAddressForeign.filterOption.name);
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual(mockFilterAddressForeign.value);
    wrapper.find('#advanced-filter-save').simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBeFalsy();
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterAddressForeign]);
    expect(wrapper.find('.advanced-filter-options-dropdown').exists()).toBeFalsy();
    expect(wrapper.find('.advanced-filter-search-input').exists()).toBeFalsy();
    wrapper.find('#filter-name-cancel').simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBeTruthy();
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterAddressForeign]);
    expect(wrapper.find('.advanced-filter-options-dropdown').prop('value').value).toEqual(mockFilterAddressForeign.filterOption.name);
    expect(wrapper.find('.advanced-filter-search-input').prop('value')).toEqual(mockFilterAddressForeign.value);
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
    expect(wrapper.state('showAdvancedFilterModal')).toBeTruthy();
    expect(wrapper.state('applied')).toBeFalsy();
    expect(wrapper.state('lastAppliedFilter')).toEqual(null);
    wrapper.setState({ activeFilterOptions: mockFilter1.contents });
    wrapper.find('#advanced-filter-apply').simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBeFalsy();
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
    expect(wrapper.state('showAdvancedFilterModal')).toBeTruthy();
    expect(wrapper.state('applied')).toBeFalsy();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter')).toEqual(null);
    wrapper.setState({ activeFilter: mockFilter1, activeFilterOptions: mockFilter1.contents, savedFilters: mockSavedFilters });
    wrapper.find('#advanced-filter-apply').simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBeFalsy();
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')).toEqual(mockFilter1.contents);
    expect(wrapper.state('activeFilter')).toEqual(mockFilter1);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(mockFilter1);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual(mockFilter1.contents);
    wrapper.find(Dropdown.Item).at(1).simulate('click');
    expect(wrapper.state('showAdvancedFilterModal')).toBeFalsy();
    expect(wrapper.state('applied')).toBeFalsy();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);
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
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter')).toEqual(null);
    expect(wrapper.find(Form.Control).exists()).toBeFalsy();
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterAddressForeign.filterOption.name });
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: mockFilterAddressForeign.value } });
    expect(wrapper.state('applied')).toBeFalsy();
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterAddressForeign]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter')).toEqual(null);
    expect(wrapper.find(Form.Control).exists()).toBeTruthy();
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterAddressForeign.value);
    wrapper.find('#advanced-filter-cancel').simulate('click');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBeFalsy();
    expect(wrapper.state('activeFilterOptions')).toEqual([{ filterOption: null }]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter')).toEqual(null);
    expect(wrapper.find(Form.Control).exists()).toBeFalsy();
  });

  it('Clicking "Cancel" button after making changes properly resets modal to the most recent filter applied', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterMonitoringStatusTrue.filterOption.name });
    expect(wrapper.state('applied')).toBeFalsy();
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterMonitoringStatusTrue]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter')).toEqual(null);
    expect(wrapper.find(ToggleButton).at(0).prop('checked')).toBeTruthy();
    expect(wrapper.find(ToggleButton).at(1).prop('checked')).toBeFalsy();
    wrapper.find('#advanced-filter-apply').simulate('click');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterMonitoringStatusTrue]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([mockFilterMonitoringStatusTrue]);
    expect(wrapper.find(ToggleButton).at(0).prop('checked')).toBeTruthy();
    expect(wrapper.find(ToggleButton).at(1).prop('checked')).toBeFalsy();
    wrapper.find('.advanced-filter-boolean-false').simulate('change');
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterMonitoringStatusFalse]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([mockFilterMonitoringStatusTrue]);
    expect(wrapper.find(ToggleButton).at(0).prop('checked')).toBeFalsy();
    expect(wrapper.find(ToggleButton).at(1).prop('checked')).toBeTruthy();
    wrapper.find('#advanced-filter-cancel').simulate('click');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterMonitoringStatusTrue]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([mockFilterMonitoringStatusTrue]);
    expect(wrapper.find(ToggleButton).at(0).prop('checked')).toBeTruthy();
    expect(wrapper.find(ToggleButton).at(1).prop('checked')).toBeFalsy();
    wrapper.find('.advanced-filter-options-dropdown').simulate('change', { value: mockFilterAddressForeign.filterOption.name });
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: mockFilterAddressForeign.value } });
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterAddressForeign]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([mockFilterMonitoringStatusTrue]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterAddressForeign.value);
    wrapper.find('#advanced-filter-apply').simulate('click');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterAddressForeign]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([mockFilterAddressForeign]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterAddressForeign.value);
    wrapper.find('.advanced-filter-search-input').simulate('change', { target: { value: `${mockFilterAddressForeign.value}!!!` } });
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')[0].value).toEqual(`${mockFilterAddressForeign.value}!!!`);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([mockFilterAddressForeign]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(`${mockFilterAddressForeign.value}!!!`);
    wrapper.find('#advanced-filter-cancel').simulate('click');
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('applied')).toBeTruthy();
    expect(wrapper.state('activeFilterOptions')).toEqual([mockFilterAddressForeign]);
    expect(wrapper.state('activeFilter')).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilter).toEqual(null);
    expect(wrapper.state('lastAppliedFilter').activeFilterOptions).toEqual([mockFilterAddressForeign]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(mockFilterAddressForeign.value);
  });
});
