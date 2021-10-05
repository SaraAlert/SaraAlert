import React from 'react';
import { shallow } from 'enzyme';
import { Dropdown, DropdownButton } from 'react-bootstrap';
import Export from '../../components/public_health/Export';
import ConfirmExport from '../../components/public_health/ConfirmExport';
import CustomExport from '../../components/public_health/CustomExport';
import { mockJurisdiction1, mockJurisdictionPaths } from '../mocks/mockJurisdiction';
import { mockQuery1, mockQuery2 } from '../mocks/mockQueries';
import { mockExposureTabs, mockIsolationTabs } from '../mocks/mockTabs';
import { mockExportPresets } from '../mocks/mockExportPresets';

const mockToken = 'testMockTokenString12345';
const dropdownOptions = ['Line list CSV', 'Sara Alert Format', 'Excel Export For Purge-Eligible Monitorees', 'Excel Export For All Monitorees', 'Custom Format...'];

function getExposureWrapper() {
  return shallow(<Export all_monitorees_count={200} authenticity_token={mockToken} current_monitorees_count={32} custom_export_options={{}} jurisdiction_paths={mockJurisdictionPaths} jurisdiction={mockJurisdiction1} query={mockQuery1} tabs={mockExposureTabs} />);
}

function getIsolationWrapper() {
  return shallow(<Export all_monitorees_count={200} authenticity_token={mockToken} current_monitorees_count={32} custom_export_options={{}} jurisdiction_paths={mockJurisdictionPaths} jurisdiction={mockJurisdiction1} query={mockQuery2} tabs={mockIsolationTabs} />);
}

describe('Export', () => {
  it('Properly renders all main components', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(DropdownButton).exists()).toBe(true);
    expect(wrapper.find(Dropdown.Item).length).toEqual(5);
    expect(wrapper.find(Dropdown.Divider).length).toEqual(1);
    expect(wrapper.find(ConfirmExport).exists()).toBe(false);
    expect(wrapper.find(CustomExport).exists()).toBe(false);
  });

  it('Properly renders dropdown in exposure workflow', () => {
    const wrapper = getExposureWrapper();
    dropdownOptions.forEach((option, index) => {
      if (index < 2) {
        option += ' (exposure)';
      }
      expect(wrapper.find(Dropdown.Item).at(index).text()).toEqual(option);
    });
  });

  it('Properly renders dropdown in isolation workflow', () => {
    const wrapper = getIsolationWrapper();
    dropdownOptions.forEach((option, index) => {
      if (index < 2) {
        option += ' (isolation)';
      }
      expect(wrapper.find(Dropdown.Item).at(index).text()).toEqual(option);
    });
  });

  it('Clicking "Line list CSV" option displays Confirm Export modal', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(ConfirmExport).exists()).toBe(false);
    expect(wrapper.find(Dropdown.Item).at(0).text()).toContain(dropdownOptions[0]);
    wrapper.find(Dropdown.Item).at(0).simulate('click');
    expect(wrapper.find(ConfirmExport).exists()).toBe(true);
    expect(wrapper.find(ConfirmExport).prop('show')).toBe(true);
    expect(wrapper.find(ConfirmExport).prop('exportType')).toEqual('Line list CSV');
    expect(wrapper.find(ConfirmExport).prop('workflow')).toEqual('exposure');
  });

  it('Clicking "Sara Alert Format" option displays Confirm Export modal', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(ConfirmExport).exists()).toBe(false);
    expect(wrapper.find(Dropdown.Item).at(1).text()).toContain(dropdownOptions[1]);
    wrapper.find(Dropdown.Item).at(1).simulate('click');
    expect(wrapper.find(ConfirmExport).exists()).toBe(true);
    expect(wrapper.find(ConfirmExport).prop('show')).toBe(true);
    expect(wrapper.find(ConfirmExport).prop('exportType')).toEqual('Sara Alert Format');
    expect(wrapper.find(ConfirmExport).prop('workflow')).toEqual('exposure');
  });

  it('Clicking "Excel Export For Purge-Eligible Monitorees" option displays Confirm Export modal', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(ConfirmExport).exists()).toBe(false);
    expect(wrapper.find(Dropdown.Item).at(2).text()).toEqual(dropdownOptions[2]);
    wrapper.find(Dropdown.Item).at(2).simulate('click');
    expect(wrapper.find(ConfirmExport).exists()).toBe(true);
    expect(wrapper.find(ConfirmExport).prop('show')).toBe(true);
    expect(wrapper.find(ConfirmExport).prop('exportType')).toEqual('Excel Export For Purge-Eligible Monitorees');
    expect(wrapper.find(ConfirmExport).prop('workflow')).toBeUndefined();
  });

  it('Clicking "Excel Export For All Monitorees" option displays Confirm Export modal', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(ConfirmExport).exists()).toBe(false);
    expect(wrapper.find(Dropdown.Item).at(3).text()).toEqual(dropdownOptions[3]);
    wrapper.find(Dropdown.Item).at(3).simulate('click');
    expect(wrapper.find(ConfirmExport).exists()).toBe(true);
    expect(wrapper.find(ConfirmExport).prop('show')).toBe(true);
    expect(wrapper.find(ConfirmExport).prop('exportType')).toEqual('Excel Export For All Monitorees');
    expect(wrapper.find(ConfirmExport).prop('workflow')).toBeUndefined();
  });

  it('Clicking "Custom Format..." option displays Custom Export modal', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(Dropdown.Item).at(4).text()).toEqual(dropdownOptions[4]);
    expect(wrapper.find(CustomExport).exists()).toBe(false);
    wrapper.find(Dropdown.Item).at(4).simulate('click');
    expect(wrapper.find(CustomExport).exists()).toBe(true);
  });

  it('Calls reloadExportPresets method when component mounts', () => {
    const instance = getExposureWrapper().instance();
    const reloadPresetsSpy = jest.spyOn(instance, 'reloadExportPresets');
    expect(reloadPresetsSpy).not.toHaveBeenCalled();
    instance.componentDidMount();
    expect(reloadPresetsSpy).toHaveBeenCalled();
  });

  it('Adds export presets to dropdown list', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(Dropdown.Item).length).toEqual(5);
    expect(wrapper.find(Dropdown.Divider).length).toEqual(1);
    expect(wrapper.state('savedExportPresets')).toBeUndefined();
    wrapper.setState({ savedExportPresets: mockExportPresets });
    expect(wrapper.find(Dropdown.Item).length).toEqual(7);
    expect(wrapper.find(Dropdown.Divider).length).toEqual(2);
    expect(wrapper.find(Dropdown.Item).at(4).text()).toEqual('custom1');
    expect(wrapper.find(Dropdown.Item).at(5).text()).toEqual('custom2');
  });
});
