import React from 'react'
import _ from 'lodash';
import { shallow } from 'enzyme';
import { DropdownButton, Dropdown } from 'react-bootstrap';
import PatientsTable from '../../components/public_health/PatientsTable.js'
import JurisdictionFilter from '../../components/public_health/query/JurisdictionFilter.js'
import AssignedUserFilter from '../../components/public_health/query/AssignedUserFilter.js'
import AdvancedFilter from '../../components/public_health/query/AdvancedFilter.js'
import CustomTable from '../../components/layout/CustomTable'
import CloseRecords from '../../components/public_health/actions/CloseRecords';
import UpdateCaseStatus from '../../components/public_health/actions/UpdateCaseStatus';
import UpdateAssignedUser from '../../components/public_health/actions/UpdateAssignedUser';
import InfoTooltip from '../../components/util/InfoTooltip';
import { mockJurisdiction1, mockJurisdictionPaths } from '../mocks/mockJurisdiction'
import { mockExposureTabs, mockIsolationTabs } from '../mocks/mockTabs'
import { mockMonitoringReasons } from '../mocks/mockMonitoringReasons'

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";
const setQueryMock = jest.fn();
const setMonitoreeCountMock = jest.fn();
const dropdownOptions = [ 'Close Records', 'Update Case Status', 'Update Assigned User' ];

function getExposureWrapper() {
  return shallow(<PatientsTable authenticity_token={authyToken} jurisdiction_paths={mockJurisdictionPaths} workflow={'exposure'} jurisdiction={mockJurisdiction1}
    tabs={mockExposureTabs} monitoring_reasons={mockMonitoringReasons} setQuery={setQueryMock} setFilteredMonitoreesCount={setMonitoreeCountMock}/>);
}

function getIsolationWrapper() {
  return shallow(<PatientsTable authenticity_token={authyToken} jurisdiction_paths={mockJurisdictionPaths} workflow={'isolation'} jurisdiction={mockJurisdiction1}
    tabs={mockIsolationTabs} monitoring_reasons={mockMonitoringReasons} setQuery={setQueryMock} setFilteredMonitoreesCount={setMonitoreeCountMock}/>);
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
    expect(wrapper.find(Dropdown.Item).length).toEqual(3);

    const defaultTab = Object.keys(mockExposureTabs)[0]
    expect(wrapper.find('#tab-description').text())
        .toEqual(mockExposureTabs[defaultTab]['description'] + ' You are currently in the exposure workflow.');
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
    expect(wrapper.find(Dropdown.Item).length).toEqual(3);

    const defaultTab = Object.keys(mockIsolationTabs)[0]
    expect(wrapper.find('#tab-description').text())
        .toEqual(mockIsolationTabs[defaultTab]['description'] + ' You are currently in the isolation workflow.');
  });

  it('Sets intial state after mount correctly', () => {
    const wrapper = getExposureWrapper();

    // componentDidMount is called when mounted and that calls an async method (updateTable),
    // as a result, we added a timeout to give it time to resolve.
    setTimeout (() => {
      expect(_.size(wrapper.state('table').colData)).toEqual(20);
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
    }, 500)

  });

  it('Properly renders dropdown', () => {
    const wrapper = getExposureWrapper();
    dropdownOptions.forEach(function(option, index) {
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

  it ('Clicking "Close Records" option displays Close Records modal', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(CloseRecords).exists()).toBeFalsy();
    expect(wrapper.find(Dropdown.Item).at(0).text().includes(dropdownOptions[0])).toBeTruthy();
    wrapper.find(Dropdown.Item).at(0).simulate('click');
    expect(wrapper.find(CloseRecords).exists()).toBeTruthy();
  });

  it ('Clicking "Update Case Status" option displays Update Case Status modal', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(UpdateCaseStatus).exists()).toBeFalsy();
    expect(wrapper.find(Dropdown.Item).at(1).text().includes(dropdownOptions[1])).toBeTruthy();
    wrapper.find(Dropdown.Item).at(1).simulate('click');
    expect(wrapper.find(UpdateCaseStatus).exists()).toBeTruthy();
  });

  it ('Clicking "Update Assigned User" option displays Update Assigned User modal', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(UpdateAssignedUser).exists()).toBeFalsy();
    expect(wrapper.find(Dropdown.Item).at(2).text().includes(dropdownOptions[2])).toBeTruthy();
    wrapper.find(Dropdown.Item).at(2).simulate('click');
    expect(wrapper.find(UpdateAssignedUser).exists()).toBeTruthy();
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
      expect(wrapper.find('#' + key + '_tab').text()).toEqual(mockExposureTabs[key]['label']);
    }
  });

  it('Properly renders all tabs on isolation dashboard', () => {
    const wrapper = getIsolationWrapper();
    for (var key of Object.keys(mockIsolationTabs)) {
      expect(wrapper.find('#' + key + '_tab').exists()).toBeTruthy();
      expect(wrapper.find('#' + key + '_tab').text()).toEqual(mockIsolationTabs[key]['label']);
    }
  });
});
