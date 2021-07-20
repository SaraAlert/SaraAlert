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
import exportOptions from '../mocks/mockExportOptions';
import available_line_lists from '../mocks/mockLinelists';

const available_workflows = [
  { name: 'exposure', label: 'Exposure' },
  { name: 'isolation', label: 'Isolation' },
  { name: 'global', label: 'Global' },
];

const mockToken = 'testMockTokenString12345';
const dropdownOptions = ['Line list CSV', 'Sara Alert Format', 'Excel Export For Purge-Eligible Monitorees', 'Excel Export For All Monitorees', 'Custom Format...'];

function getExposureWrapper() {
  return shallow(<Export authenticity_token={mockToken} jurisdiction_paths={mockJurisdictionPaths} jurisdiction={mockJurisdiction1} available_workflows={available_workflows} available_line_lists={available_line_lists} tabs={mockExposureTabs} export_options={exportOptions} query={mockQuery1} all_monitorees_count={200} current_monitorees_count={32} custom_export_options={{}} />);
}

function getIsolationWrapper() {
  return shallow(<Export authenticity_token={mockToken} jurisdiction_paths={mockJurisdictionPaths} jurisdiction={mockJurisdiction1} available_workflows={available_workflows} available_line_lists={available_line_lists} tabs={mockIsolationTabs} export_options={exportOptions} query={mockQuery2} all_monitorees_count={200} current_monitorees_count={32} custom_export_options={{}} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('Export', () => {
  it('Properly renders all main components', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(DropdownButton).exists()).toBeTruthy();
    expect(wrapper.find(Dropdown.Item).length).toEqual(5);
    expect(wrapper.find(Dropdown.Divider).length).toEqual(1);
    expect(wrapper.find(ConfirmExport).exists()).toBeFalsy();
    expect(wrapper.find(CustomExport).exists()).toBeFalsy();
  });

  it('Properly renders dropdown in exposure workflow', () => {
    const wrapper = getExposureWrapper();
    dropdownOptions.forEach((option, index) => {
      if (index < 2) {
        option += ' (exposure)';
      }
      expect(
        wrapper
          .find(Dropdown.Item)
          .at(index)
          .text()
      ).toContain(option);
    });
  });

  it('Properly renders dropdown in isolation workflow', () => {
    const wrapper = getIsolationWrapper();
    dropdownOptions.forEach((option, index) => {
      if (index < 2) {
        option += ' (isolation)';
      }
      expect(
        wrapper
          .find(Dropdown.Item)
          .at(index)
          .text()
      ).toContain(option);
    });
  });

  it('Clicking "Line list CSV" option displays Confirm Export modal', () => {
    let wrapper = getExposureWrapper();
    expect(wrapper.find(ConfirmExport).exists()).toBeFalsy();
    expect(
      wrapper
        .find(Dropdown.Item)
        .at(0)
        .text()
        .includes(dropdownOptions[0])
    ).toBeTruthy();
    wrapper
      .find(Dropdown.Item)
      .at(0)
      .simulate('click');
    expect(wrapper.find(ConfirmExport).exists()).toBeTruthy();
    expect(wrapper.find(ConfirmExport).prop('show')).toBeTruthy();
    expect(wrapper.find(ConfirmExport).prop('exportType')).toEqual('Line list CSV');
  });

  // Debug these tests
  // it('Clicking "Sara Alert Format" option displays Confirm Export modal', () => {
  //   let wrapper = getExposureWrapper();
  //   console.log(wrapper.debug())
  //   // expect(wrapper.find(ConfirmExport).exists()).toBeFalsy();
  //   expect(
  //     wrapper
  //       .find(Dropdown.Item)
  //       .at(1)
  //       .text()
  //       .includes(dropdownOptions[1])
  //   ).toBeTruthy();
  //   wrapper
  //     .find(Dropdown.Item)
  //     .at(1)
  //     .simulate('click');
  //   expect(wrapper.find(ConfirmExport).exists()).toBeTruthy();
  //   expect(wrapper.find(ConfirmExport).prop('show')).toBeTruthy();
  //   expect(wrapper.find(ConfirmExport).prop('exportType')).toEqual('Sara Alert Format');
  // });

  // it('Clicking "Excel Export For Purge-Eligible Monitorees" option displays Confirm Export modal', () => {
  //   const wrapper = getExposureWrapper();
  //   expect(wrapper.find(ConfirmExport).exists()).toBeFalsy();
  //   expect(
  //     wrapper
  //       .find(Dropdown.Item)
  //       .at(2)
  //       .text()
  //   ).toEqual(dropdownOptions[2]);
  //   wrapper
  //     .find(Dropdown.Item)
  //     .at(2)
  //     .simulate('click');
  //   expect(wrapper.find(ConfirmExport).exists()).toBeTruthy();
  //   expect(wrapper.find(ConfirmExport).prop('show')).toBeTruthy();
  //   expect(wrapper.find(ConfirmExport).prop('exportType')).toContain('Excel Export For Purge-Eligible Monitorees');
  // });

  // it('Clicking "Excel Export For All Monitorees" option displays Confirm Export modal', () => {
  //   const wrapper = getExposureWrapper();
  //   expect(wrapper.find(ConfirmExport).exists()).toBeFalsy();
  //   expect(
  //     wrapper
  //       .find(Dropdown.Item)
  //       .at(3)
  //       .text()
  //   ).toEqual(dropdownOptions[3]);
  //   wrapper
  //     .find(Dropdown.Item)
  //     .at(3)
  //     .simulate('click');
  //   expect(wrapper.find(ConfirmExport).exists()).toBeTruthy();
  //   expect(wrapper.find(ConfirmExport).prop('show')).toBeTruthy();
  //   expect(wrapper.find(ConfirmExport).prop('exportType')).toContain('Excel Export For All Monitorees');
  //   expect(wrapper.find(ConfirmExport).prop('workflow')).toEqual(undefined);
  // });

  it('Clicking "Custom Format..." option displays Custom Export modal', () => {
    const wrapper = getExposureWrapper();
    expect(
      wrapper
        .find(Dropdown.Item)
        .at(4)
        .text()
    ).toEqual(dropdownOptions[4]);
    expect(wrapper.find(CustomExport).exists()).toBeFalsy();
    wrapper
      .find(Dropdown.Item)
      .at(4)
      .simulate('click');
    expect(wrapper.find(CustomExport).exists()).toBeTruthy();
  });

  it('Calls reloadExportPresets method when component mounts', () => {
    const instance = getExposureWrapper().instance();
    const reloadPresetsSpy = jest.spyOn(instance, 'reloadExportPresets');
    expect(reloadPresetsSpy).toHaveBeenCalledTimes(0);
    instance.componentDidMount();
    expect(reloadPresetsSpy).toHaveBeenCalledTimes(1);
  });

  it('Adds export presets to dropdown list', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(Dropdown.Item).length).toEqual(5);
    expect(wrapper.find(Dropdown.Divider).length).toEqual(1);
    expect(wrapper.state('savedExportPresets')).toEqual(undefined);
    wrapper.setState({ savedExportPresets: mockExportPresets });
    expect(wrapper.find(Dropdown.Item).length).toEqual(7);
    expect(wrapper.find(Dropdown.Divider).length).toEqual(2);
    expect(
      wrapper
        .find(Dropdown.Item)
        .at(4)
        .text()
    ).toEqual('custom1');
    expect(
      wrapper
        .find(Dropdown.Item)
        .at(5)
        .text()
    ).toEqual('custom2');
  });
});
