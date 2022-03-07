import React from 'react';
import _ from 'lodash';
import { shallow } from 'enzyme';
import { Badge, DropdownButton, Dropdown, Nav } from 'react-bootstrap';
import PatientsTable from '../../components/patient/PatientsTable';
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

function getWrapper(additionalProps) {
  return shallow(<PatientsTable authenticity_token={mockToken} jurisdiction_paths={mockJurisdictionPaths} jurisdiction={mockJurisdiction1} monitoring_reasons={mockMonitoringReasons} setQuery={setQueryMock} setFilteredMonitoreesCount={setMonitoreeCountMock} {...additionalProps} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('PatientsTable', () => {
  it('Properly renders all main components for the exposure workflow', () => {
    const wrapper = getWrapper({ workflow: 'exposure', tabs: mockExposureTabs });
    const defaultTab = Object.keys(mockExposureTabs)[0];
    expect(wrapper.find(Nav).exists()).toBe(true);
    expect(wrapper.find('#search').exists()).toBe(true);
    expect(wrapper.find('#table-description').exists()).toBe(true);
    expect(wrapper.find('#table-description').text()).toEqual(mockExposureTabs[`${defaultTab}`]['description'] + ' You are currently in the exposure workflow.');
    expect(wrapper.find('#clear-all-filters').exists()).toBe(true);
    expect(wrapper.find('#clear-all-filters').find('span').text()).toEqual('Clear All Filters');
    expect(wrapper.find('#clear-all-filters').find('i').hasClass('fa-eraser')).toBe(true);
    expect(wrapper.find(JurisdictionFilter).exists()).toBe(true);
    expect(wrapper.find(AssignedUserFilter).exists()).toBe(true);
    expect(wrapper.find(AdvancedFilter).exists()).toBe(true);
    expect(wrapper.find(DropdownButton).exists()).toBe(true);
    expect(wrapper.find(Dropdown.Item).length).toEqual(4);
    expect(wrapper.find(CustomTable).exists()).toBe(true);
  });

  it('Properly renders all main components for the isolation workflow', () => {
    const wrapper = getWrapper({ workflow: 'isolation', tabs: mockIsolationTabs });
    const defaultTab = Object.keys(mockIsolationTabs)[0];
    expect(wrapper.find(Nav).exists()).toBe(true);
    expect(wrapper.find('#search').exists()).toBe(true);
    expect(wrapper.find('#table-description').exists()).toBe(true);
    expect(wrapper.find('#table-description').text()).toEqual(mockIsolationTabs[`${defaultTab}`]['description'] + ' You are currently in the isolation workflow.');
    expect(wrapper.find('#clear-all-filters').exists()).toBe(true);
    expect(wrapper.find('#clear-all-filters').find('span').text()).toEqual('Clear All Filters');
    expect(wrapper.find('#clear-all-filters').find('i').hasClass('fa-eraser')).toBe(true);
    expect(wrapper.find(JurisdictionFilter).exists()).toBe(true);
    expect(wrapper.find(AssignedUserFilter).exists()).toBe(true);
    expect(wrapper.find(AdvancedFilter).exists()).toBe(true);
    expect(wrapper.find(DropdownButton).exists()).toBe(true);
    expect(wrapper.find(Dropdown.Item).length).toEqual(4);
    expect(wrapper.find(CustomTable).exists()).toBe(true);
  });

  it('Properly renders all main components for the global workflow', () => {
    const wrapper = getWrapper({ workflow: 'global', tabs: mockGlobalTabs, default_tab: 'all' });
    const defaultTab = Object.keys(mockIsolationTabs)[0];
    expect(wrapper.find(Nav).exists()).toBe(true);
    expect(wrapper.find('#search').exists()).toBe(true);
    expect(wrapper.find('#table-description').exists()).toBe(true);
    expect(wrapper.find('#table-description').text()).toEqual(mockGlobalTabs[`${defaultTab}`]['description'] + ' You are currently in the global dashboard.');
    expect(wrapper.find('#clear-all-filters').exists()).toBe(true);
    expect(wrapper.find('#clear-all-filters').find('span').text()).toEqual('Clear All Filters');
    expect(wrapper.find('#clear-all-filters').find('i').hasClass('fa-eraser')).toBe(true);
    expect(wrapper.find(JurisdictionFilter).exists()).toBe(true);
    expect(wrapper.find(AssignedUserFilter).exists()).toBe(true);
    expect(wrapper.find(AdvancedFilter).exists()).toBe(true);
    expect(wrapper.find(DropdownButton).exists()).toBe(true);
    expect(wrapper.find(Dropdown.Item).length).toEqual(3);
    expect(wrapper.find(CustomTable).exists()).toBe(true);
  });

  it('Properly renders all main components for enroller table', () => {
    const wrapper = getWrapper({ enroller: true });
    expect(wrapper.find(Nav).exists()).toBe(false);
    expect(wrapper.find('#search').exists()).toBe(true);
    expect(wrapper.find('#table-description').exists()).toBe(true);
    expect(wrapper.find('#table-description').text()).toEqual('Enrolled Monitorees');
    expect(wrapper.find('#clear-all-filters').exists()).toBe(true);
    expect(wrapper.find('#clear-all-filters').find('span').text()).toEqual('Clear All Filters');
    expect(wrapper.find('#clear-all-filters').find('i').hasClass('fa-eraser')).toBe(true);
    expect(wrapper.find(JurisdictionFilter).exists()).toBe(true);
    expect(wrapper.find(AssignedUserFilter).exists()).toBe(true);
    expect(wrapper.find(AdvancedFilter).exists()).toBe(false);
    expect(wrapper.find(DropdownButton).exists()).toBe(false);
    expect(wrapper.find(CustomTable).exists()).toBe(true);
  });

  it('Properly renders all tabs on exposure dashboard', () => {
    const wrapper = getWrapper({ workflow: 'exposure', tabs: mockExposureTabs });
    for (var key of Object.keys(mockExposureTabs)) {
      expect(wrapper.find('#' + key + '_tab').exists()).toBe(true);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.large-tab')
          .exists()
      ).toBe(true);
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
      ).toBe(true);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.small-tab')
          .text()
      ).toEqual(mockExposureTabs[`${key}`]['abbreviatedLabel'] || mockExposureTabs[`${key}`]['label']);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find(Badge)
          .exists()
      ).toBe(true);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find(Badge)
          .prop('variant')
      ).toEqual(mockExposureTabs[`${key}`]['variant']);
    }
  });

  it('Properly renders all tabs on isolation dashboard', () => {
    const wrapper = getWrapper({ workflow: 'isolation', tabs: mockIsolationTabs });
    for (var key of Object.keys(mockIsolationTabs)) {
      expect(wrapper.find('#' + key + '_tab').exists()).toBe(true);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.large-tab')
          .exists()
      ).toBe(true);
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
      ).toBe(true);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.small-tab')
          .text()
      ).toEqual(mockIsolationTabs[`${key}`]['abbreviatedLabel'] || mockIsolationTabs[`${key}`]['label']);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find(Badge)
          .exists()
      ).toBe(true);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find(Badge)
          .prop('variant')
      ).toEqual(mockIsolationTabs[`${key}`]['variant']);
    }
  });

  it('Properly renders all tabs on global dashboard', () => {
    const wrapper = getWrapper({ workflow: 'global', tabs: mockGlobalTabs, default_tab: 'all' });
    for (var key of Object.keys(mockGlobalTabs)) {
      expect(wrapper.find('#' + key + '_tab').exists()).toBe(true);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.large-tab')
          .exists()
      ).toBe(true);
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
      ).toBe(true);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find('.small-tab')
          .text()
      ).toEqual(mockGlobalTabs[`${key}`]['abbreviatedLabel'] || mockGlobalTabs[`${key}`]['label']);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find(Badge)
          .exists()
      ).toBe(true);
      expect(
        wrapper
          .find('#' + key + '_tab')
          .find(Badge)
          .prop('variant')
      ).toEqual(mockGlobalTabs[`${key}`]['variant']);
    }
  });

  it('Sets intial state after mount correctly', () => {
    const wrapper = getWrapper({ workflow: 'exposure', tabs: mockExposureTabs });

    // componentDidMount is called when mounted and that calls an async method (updateTable),
    // as a result, we added a timeout to give it time to resolve.
    setTimeout(() => {
      expect(_.size(wrapper.state('table').colData)).toEqual(21);
      expect(_.size(wrapper.state('table').displayedColData)).toEqual(0);
      expect(_.size(wrapper.state('table').rowData)).toEqual(0);
      expect(wrapper.state('table').totalRows).toEqual(0);
      expect(wrapper.state('loading')).toBe(false);
      expect(wrapper.state('actionsEnabled')).toBe(false);
      expect(_.size(wrapper.state('selectedPatients'))).toEqual(0);
      expect(wrapper.state('selectAll')).toBe(false);
      expect(wrapper.state('jurisdiction_paths')).toEqual({});
      expect(_.size(wrapper.state('assigned_users'))).toEqual(0);
      expect(wrapper.state('query').workflow).toEqual('exposure');
      expect(wrapper.state('query').tab).toEqual(Object.keys(mockExposureTabs)[0]);
      expect(wrapper.state('query').jurisdiction).toEqual(mockJurisdiction1.id);
      expect(wrapper.state('query').scope).toEqual('all');
      expect(wrapper.state('query').user).toBeNull();
      expect(wrapper.state('query').search).toEqual('');
      expect(wrapper.state('query').page).toEqual(0);
      expect(wrapper.state('query').entries).toEqual(25);
      expect(_.size(wrapper.state('entryOptions'))).toEqual(5);
    }, 500);
  });

  it('Properly renders dropdown', () => {
    const wrapper = getWrapper({ workflow: 'exposure', tabs: mockExposureTabs });
    dropdownOptions.forEach((option, index) => {
      expect(wrapper.find(Dropdown.Item).at(index).text()).toEqual(option);
    });
  });

  it('Inputting text into search bar calls update table function', () => {
    const wrapper = getWrapper({ workflow: 'exposure', tabs: mockExposureTabs });
    const handleSearchChangeSpy = jest.spyOn(wrapper.instance(), 'updateTable');
    expect(handleSearchChangeSpy).not.toHaveBeenCalled();
    expect(wrapper.state('query').search).toEqual('');
    wrapper.find('#search').simulate('change', { target: { id: 'search', value: 'search' } });
    expect(wrapper.state('query').search).toEqual('search');
    expect(handleSearchChangeSpy).toHaveBeenCalled();
  });

  it('Clicking "Close Records" option displays Close Records modal', () => {
    const wrapper = getWrapper({ workflow: 'exposure', tabs: mockExposureTabs });
    expect(wrapper.find(CloseRecords).exists()).toBe(false);
    expect(wrapper.find(Dropdown.Item).at(0).text()).toContain(dropdownOptions[0]);
    wrapper.find(Dropdown.Item).at(0).simulate('click');
    expect(wrapper.find(CloseRecords).exists()).toBe(true);
  });

  it('Clicking "Update Case Status" option displays Update Case Status modal', () => {
    const wrapper = getWrapper({ workflow: 'exposure', tabs: mockExposureTabs });
    expect(wrapper.find(UpdateCaseStatus).exists()).toBe(false);
    expect(wrapper.find(Dropdown.Item).at(1).text()).toContain(dropdownOptions[1]);
    wrapper.find(Dropdown.Item).at(1).simulate('click');
    expect(wrapper.find(UpdateCaseStatus).exists()).toBe(true);
  });

  it('Clicking "Update Assigned User" option displays Update Assigned User modal', () => {
    const wrapper = getWrapper({ workflow: 'exposure', tabs: mockExposureTabs });
    expect(wrapper.find(UpdateAssignedUser).exists()).toBe(false);
    expect(wrapper.find(Dropdown.Item).at(2).text()).toContain(dropdownOptions[2]);
    wrapper.find(Dropdown.Item).at(2).simulate('click');
    expect(wrapper.find(UpdateAssignedUser).exists()).toBe(true);
  });

  it('Clicking "Flag for Follow-up" option displays Flag for Follow-up modal', () => {
    const wrapper = getWrapper({ workflow: 'exposure', tabs: mockExposureTabs });
    expect(wrapper.find(FollowUpFlag).exists()).toBe(false);
    expect(wrapper.find(Dropdown.Item).at(3).text()).toContain(dropdownOptions[3]);
    wrapper.find(Dropdown.Item).at(3).simulate('click');
    expect(wrapper.find(FollowUpFlag).exists()).toBe(true);
  });

  it('Calls updateAssignedUsers and updateTable methods when component mounts', () => {
    const instance = getWrapper({ workflow: 'exposure', tabs: mockExposureTabs }).instance();
    const updateAssignedUsersSpy = jest.spyOn(instance, 'updateAssignedUsers');
    expect(updateAssignedUsersSpy).not.toHaveBeenCalled();
    instance.componentDidMount();
    expect(updateAssignedUsersSpy).toHaveBeenCalled();
  });
});
