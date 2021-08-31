import React from 'react';
import _ from 'lodash';
import { shallow } from 'enzyme';
import { Badge, DropdownButton, Dropdown } from 'react-bootstrap';
import PatientsTable from '../../components/public_health/PatientsTable';
import JurisdictionFilter from '../../components/public_health/query/JurisdictionFilter';
import AssignedUserFilter from '../../components/public_health/query/AssignedUserFilter';
import AdvancedFilter from '../../components/public_health/query/AdvancedFilter';
import CustomTable from '../../components/layout/CustomTable';
import CloseRecords from '../../components/public_health/bulk_actions/CloseRecords';
import FollowUpFlag from '../../components/patient/follow_up_flag/FollowUpFlag';
import UpdateCaseStatus from '../../components/public_health/bulk_actions/UpdateCaseStatus';
import UpdateAssignedUser from '../../components/public_health/bulk_actions/UpdateAssignedUser';
import { mockJurisdiction1, mockJurisdictionPaths } from '../mocks/mockJurisdiction';
import { mockExposureTabs, mockIsolationTabs, mockGlobalTabs } from '../mocks/mockTabs';
import { mockMonitoringReasons } from '../mocks/mockMonitoringReasons';

const mockToken = 'testMockTokenString12345';
const setQueryMock = jest.fn();
const setMonitoreeCountMock = jest.fn();
const dropdownOptions = ['Close Records', 'Update Case Status', 'Update Assigned User', 'Flag for Follow-up'];

function getExposureWrapper() {
  return shallow(<PatientsTable authenticity_token={mockToken} jurisdiction_paths={mockJurisdictionPaths} workflow={'exposure'} jurisdiction={mockJurisdiction1} tabs={mockExposureTabs} monitoring_reasons={mockMonitoringReasons} setQuery={setQueryMock} setFilteredMonitoreesCount={setMonitoreeCountMock} />);
}

function getIsolationWrapper() {
  return shallow(<PatientsTable authenticity_token={mockToken} jurisdiction_paths={mockJurisdictionPaths} workflow={'isolation'} jurisdiction={mockJurisdiction1} tabs={mockIsolationTabs} monitoring_reasons={mockMonitoringReasons} setQuery={setQueryMock} setFilteredMonitoreesCount={setMonitoreeCountMock} />);
}

function getGlobalWrapper() {
  return shallow(<PatientsTable authenticity_token={mockToken} jurisdiction_paths={mockJurisdictionPaths} workflow={'global'} jurisdiction={mockJurisdiction1} tabs={mockGlobalTabs} default_tab={'all'} monitoring_reasons={mockMonitoringReasons} setQuery={setQueryMock} setFilteredMonitoreesCount={setMonitoreeCountMock} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('PatientsTable', () => {
  it('Properly renders all main components for the exposure workflow', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find('#search').exists()).toBeTruthy();
    expect(wrapper.find('#tab-description').exists()).toBeTruthy();
    expect(wrapper.find('#clear-all-filters').exists()).toBeTruthy();
    expect(wrapper.containsMatchingElement(JurisdictionFilter)).toBeTruthy();
    expect(wrapper.containsMatchingElement(AssignedUserFilter)).toBeTruthy();
    expect(wrapper.containsMatchingElement(AdvancedFilter)).toBeTruthy();
    expect(wrapper.containsMatchingElement(CustomTable)).toBeTruthy();
    expect(wrapper.containsMatchingElement(DropdownButton)).toBeTruthy();
    expect(wrapper.find(Dropdown.Item).length).toEqual(4);

    const defaultTab = Object.keys(mockExposureTabs)[0];
    expect(wrapper.find('#tab-description').text()).toEqual(mockExposureTabs[`${defaultTab}`]['description'] + ' You are currently in the exposure workflow.');
  });

  it('Properly renders all main components for the isolation workflow', () => {
    const wrapper = getIsolationWrapper();
    expect(wrapper.find('#search').exists()).toBeTruthy();
    expect(wrapper.find('#tab-description').exists()).toBeTruthy();
    expect(wrapper.find('#clear-all-filters').exists()).toBeTruthy();
    expect(wrapper.containsMatchingElement(JurisdictionFilter)).toBeTruthy();
    expect(wrapper.containsMatchingElement(AssignedUserFilter)).toBeTruthy();
    expect(wrapper.containsMatchingElement(AdvancedFilter)).toBeTruthy();
    expect(wrapper.containsMatchingElement(CustomTable)).toBeTruthy();
    expect(wrapper.containsMatchingElement(DropdownButton)).toBeTruthy();
    expect(wrapper.find(Dropdown.Item).length).toEqual(4);

    const defaultTab = Object.keys(mockIsolationTabs)[0];
    expect(wrapper.find('#tab-description').text()).toEqual(mockIsolationTabs[`${defaultTab}`]['description'] + ' You are currently in the isolation workflow.');
  });

  it('Properly renders all main components for the global workflow', () => {
    const wrapper = getGlobalWrapper();
    expect(wrapper.find('#search').exists()).toBeTruthy();
    expect(wrapper.find('#tab-description').exists()).toBeTruthy();
    expect(wrapper.find('#clear-all-filters').exists()).toBeTruthy();
    expect(wrapper.containsMatchingElement(JurisdictionFilter)).toBeTruthy();
    expect(wrapper.containsMatchingElement(AssignedUserFilter)).toBeTruthy();
    expect(wrapper.containsMatchingElement(AdvancedFilter)).toBeTruthy();
    expect(wrapper.containsMatchingElement(CustomTable)).toBeTruthy();
    expect(wrapper.containsMatchingElement(DropdownButton)).toBeTruthy();
    expect(wrapper.find(Dropdown.Item).length).toEqual(3);

    const defaultTab = Object.keys(mockIsolationTabs)[0];
    expect(wrapper.find('#tab-description').text()).toEqual(mockGlobalTabs[`${defaultTab}`]['description'] + ' You are currently in the global dashboard.');
  });

  it('Sets intial state after mount correctly', () => {
    const wrapper = getExposureWrapper();

    // componentDidMount is called when mounted and that calls an async method (updateTable),
    // as a result, we added a timeout to give it time to resolve.
    setTimeout(() => {
      expect(_.size(wrapper.state('table').colData)).toEqual(21);
      expect(_.size(wrapper.state('table').displayedColData)).toEqual(0);
      expect(_.size(wrapper.state('table').rowData)).toEqual(0);
      expect(wrapper.state('table').totalRows).toEqual(0);
      expect(wrapper.state('loading')).toBeFalsy();
      expect(wrapper.state('actionsEnabled')).toBeFalsy();
      expect(_.size(wrapper.state('selectedPatients'))).toEqual(0);
      expect(wrapper.state('selectAll')).toBeFalsy();
      expect(wrapper.state('jurisdiction_paths')).toEqual({});
      expect(_.size(wrapper.state('assigned_users'))).toEqual(0);
      expect(wrapper.state('query').workflow).toEqual('exposure');
      expect(wrapper.state('query').tab).toEqual(Object.keys(mockExposureTabs)[0]);
      expect(wrapper.state('query').jurisdiction).toEqual(mockJurisdiction1.id);
      expect(wrapper.state('query').scope).toEqual('all');
      expect(wrapper.state('query').user).toEqual(null);
      expect(wrapper.state('query').search).toEqual('');
      expect(wrapper.state('query').page).toEqual(0);
      expect(wrapper.state('query').entries).toEqual(25);
      expect(_.size(wrapper.state('entryOptions'))).toEqual(5);
    }, 500);
  });

  it('Properly renders dropdown', () => {
    const wrapper = getExposureWrapper();
    dropdownOptions.forEach((option, index) => {
      expect(wrapper.find(Dropdown.Item).at(index).text()).toEqual(option);
    });
  });

  it('Inputting text into search bar calls update table function', () => {
    const wrapper = getExposureWrapper();
    const handleSearchChangeSpy = jest.spyOn(wrapper.instance(), 'updateTable');
    expect(handleSearchChangeSpy).toHaveBeenCalledTimes(0);
    expect(wrapper.state('query').search).toEqual('');
    wrapper.find('#search').simulate('change', { target: { id: 'search', value: 'search' } });
    expect(wrapper.state('query').search).toEqual('search');
    expect(handleSearchChangeSpy).toHaveBeenCalledTimes(1);
  });

  it('Clicking "Close Records" option displays Close Records modal', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(CloseRecords).exists()).toBeFalsy();
    expect(wrapper.find(Dropdown.Item).at(0).text().includes(dropdownOptions[0])).toBeTruthy();
    wrapper.find(Dropdown.Item).at(0).simulate('click');
    expect(wrapper.find(CloseRecords).exists()).toBeTruthy();
  });

  it('Clicking "Update Case Status" option displays Update Case Status modal', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(UpdateCaseStatus).exists()).toBeFalsy();
    expect(wrapper.find(Dropdown.Item).at(1).text().includes(dropdownOptions[1])).toBeTruthy();
    wrapper.find(Dropdown.Item).at(1).simulate('click');
    expect(wrapper.find(UpdateCaseStatus).exists()).toBeTruthy();
  });

  it('Clicking "Update Assigned User" option displays Update Assigned User modal', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(UpdateAssignedUser).exists()).toBeFalsy();
    expect(wrapper.find(Dropdown.Item).at(2).text().includes(dropdownOptions[2])).toBeTruthy();
    wrapper.find(Dropdown.Item).at(2).simulate('click');
    expect(wrapper.find(UpdateAssignedUser).exists()).toBeTruthy();
  });

  it('Clicking "Flag for Follow-up" option displays Flag for Follow-up modal', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(FollowUpFlag).exists()).toBeFalsy();
    expect(wrapper.find(Dropdown.Item).at(3).text().includes(dropdownOptions[3])).toBeTruthy();
    wrapper.find(Dropdown.Item).at(3).simulate('click');
    expect(wrapper.find(FollowUpFlag).exists()).toBeTruthy();
  });

  it('Calls updateAssignedUsers and updateTable methods when component mounts', () => {
    const instance = getExposureWrapper().instance();
    const updateAssignedUsersSpy = jest.spyOn(instance, 'updateAssignedUsers');
    expect(updateAssignedUsersSpy).toHaveBeenCalledTimes(0);
    instance.componentDidMount();
    expect(updateAssignedUsersSpy).toHaveBeenCalledTimes(1);
  });

  it('Properly renders all tabs on exposure dashboard', () => {
    const wrapper = getExposureWrapper();
    for (var key of Object.keys(mockExposureTabs)) {
      expect(wrapper.find('#' + key + '_tab').exists()).toBeTruthy();
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.large-tab')
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.large-tab')
          .text()
      ).toEqual(mockExposureTabs[`${key}`]['label']);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.small-tab')
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.small-tab')
          .text()
      ).toEqual(mockExposureTabs[`${key}`]['abbreviated_label'] || mockExposureTabs[`${key}`]['label']);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find(Badge)
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find(Badge)
          .prop('variant')
      ).toEqual(mockExposureTabs[`${key}`]['variant']);
    }
  });

  it('Properly renders all tabs on isolation dashboard', () => {
    const wrapper = getIsolationWrapper();
    for (var key of Object.keys(mockIsolationTabs)) {
      expect(wrapper.find('#' + key + '_tab').exists()).toBeTruthy();
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.large-tab')
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.large-tab')
          .text()
      ).toEqual(mockIsolationTabs[`${key}`]['label']);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.small-tab')
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.small-tab')
          .text()
      ).toEqual(mockIsolationTabs[`${key}`]['abbreviated_label'] || mockIsolationTabs[`${key}`]['label']);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find(Badge)
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find(Badge)
          .prop('variant')
      ).toEqual(mockIsolationTabs[`${key}`]['variant']);
    }
  });

  it('Properly renders all tabs on global dashboard', () => {
    const wrapper = getGlobalWrapper();
    for (var key of Object.keys(mockGlobalTabs)) {
      expect(wrapper.find('#' + key + '_tab').exists()).toBeTruthy();
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.large-tab')
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.large-tab')
          .text()
      ).toEqual(mockGlobalTabs[`${key}`]['label']);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.small-tab')
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.small-tab')
          .text()
      ).toEqual(mockGlobalTabs[`${key}`]['abbreviated_label'] || mockGlobalTabs[`${key}`]['label']);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find(Badge)
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find(Badge)
          .prop('variant')
      ).toEqual(mockGlobalTabs[`${key}`]['variant']);
    }
  });
});
