import React from 'react';
import { shallow } from 'enzyme';
import { Dropdown, DropdownButton } from 'react-bootstrap';
import _ from 'lodash';
import Export from '../../components/public_health/Export';
import ConfirmExport from '../../components/public_health/ConfirmExport';
import CustomExport from '../../components/public_health/CustomExport';
import { mockJurisdiction1, mockJurisdictionPaths } from '../mocks/mockJurisdiction';
import { mockQuery1, mockQuery2 } from '../mocks/mockQueries';
import { mockExposureTabs, mockIsolationTabs } from '../mocks/mockTabs';
import { mockExportPresets } from '../mocks/mockExportPresets';
import { mockPlaybookImportExportOptions } from '../mocks/mockExportOptions';
import { availableLineLists } from '../mocks/mockLinelists';

const available_workflows = [
  { name: 'exposure', label: 'Exposure' },
  { name: 'isolation', label: 'Isolation' },
  { name: 'global', label: 'Global' },
];
const continuous_exposure_enabled = true;

const mockToken = 'testMockTokenString12345';

function getExposureWrapper() {
  return shallow(<Export all_monitorees_count={200} authenticity_token={mockToken} availableLineLists={availableLineLists} available_workflows={available_workflows} current_monitorees_count={32} custom_export_options={{}} export_options={mockPlaybookImportExportOptions} jurisdiction={mockJurisdiction1} jurisdiction_paths={mockJurisdictionPaths} query={mockQuery1} tabs={mockExposureTabs} workflow="exposure" continuous_exposure_enabled={continuous_exposure_enabled} />);
}

function getIsolationWrapper() {
  return shallow(<Export all_monitorees_count={200} authenticity_token={mockToken} availableLineLists={availableLineLists} available_workflows={available_workflows} current_monitorees_count={32} custom_export_options={{}} export_options={mockPlaybookImportExportOptions} jurisdiction={mockJurisdiction1} jurisdiction_paths={mockJurisdictionPaths} query={mockQuery2} tabs={mockIsolationTabs} workflow="isolation" continuous_exposure_enabled={continuous_exposure_enabled} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('Export', () => {
  it('Properly renders all main components', () => {
    const wrapper = getExposureWrapper();
    expect(wrapper.find(DropdownButton).exists()).toBeTruthy();
    expect(wrapper.find(Dropdown.Item).length).toEqual(Object.values(mockPlaybookImportExportOptions.export.options).length);
    const hasCustomFormat = Object.values(mockPlaybookImportExportOptions.export.options).some(x => x.label === 'Custom Format...');
    expect(wrapper.find(Dropdown.Divider).length).toEqual(hasCustomFormat ? 1 : 0);
    expect(wrapper.find(ConfirmExport).exists()).toBeFalsy();
    expect(wrapper.find(CustomExport).exists()).toBeFalsy();
  });

  it('Properly renders dropdown in exposure workflow', () => {
    const wrapper = getExposureWrapper();
    Object.values(mockPlaybookImportExportOptions.export.options).forEach((option, index) => {
      let dropdownOption = `${option.label}${option.workflow_specific ? ' (exposure)' : ''}`;
      expect(wrapper.find(Dropdown.Item).at(index).text()).toContain(dropdownOption);
    });
  });

  it('Properly renders dropdown in isolation workflow', () => {
    const wrapper = getIsolationWrapper();
    Object.values(mockPlaybookImportExportOptions.export.options).forEach((option, index) => {
      let dropdownOption = `${option.label}${option.workflow_specific ? ' (isolation)' : ''}`;
      expect(wrapper.find(Dropdown.Item).at(index).text()).toContain(dropdownOption);
    });
  });

  _.initial(Object.values(mockPlaybookImportExportOptions.export.options)).forEach((option, index) => {
    const label = `${option.label}${option.workflow_specific ? ' (exposure)' : ''}`;
    it(`Clicking "${label}" options displays the Confirm Export Modal`, () => {
      const wrapper = getExposureWrapper();
      expect(wrapper.find(ConfirmExport).exists()).toBeFalsy();
      expect(wrapper.find(Dropdown.Item).at(index).text()).toContain(label);
      wrapper.find(Dropdown.Item).at(index).simulate('click');
      expect(wrapper.find(ConfirmExport).exists()).toBeTruthy();
      expect(wrapper.find(ConfirmExport).prop('show')).toBeTruthy();
      expect(wrapper.find(ConfirmExport).prop('exportType')).toEqual(option.label);
    });
  });

  it('Clicking "Custom Format..." option displays Custom Export modal', () => {
    let dropdownOptions = Object.values(mockPlaybookImportExportOptions.export.options);
    const wrapper = getExposureWrapper();
    expect(
      wrapper
        .find(Dropdown.Item)
        .at(dropdownOptions.length - 1)
        .text()
    ).toEqual('Custom Format...');
    expect(wrapper.find(CustomExport).exists()).toBeFalsy();
    wrapper
      .find(Dropdown.Item)
      .at(dropdownOptions.length - 1)
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
    let dropdownOptions = Object.values(mockPlaybookImportExportOptions.export.options);

    const wrapper = getExposureWrapper();
    expect(wrapper.find(Dropdown.Item).length).toEqual(dropdownOptions.length);
    const hasCustomFormat = dropdownOptions.some(x => x.label === 'Custom Format...');
    expect(wrapper.find(Dropdown.Divider).length).toEqual(hasCustomFormat ? 1 : 0);

    expect(wrapper.state('savedExportPresets')).toEqual(undefined);
    wrapper.setState({ savedExportPresets: mockExportPresets });
    expect(wrapper.find(Dropdown.Item).length).toEqual(dropdownOptions.length + mockExportPresets.length);
    expect(wrapper.find(Dropdown.Divider).length).toEqual((hasCustomFormat ? 1 : 0) + 1);

    let numberOfNonCustomFormatOptions = dropdownOptions.length - (hasCustomFormat ? 1 : 0);
    mockExportPresets.forEach((mockPreset, index) => {
      expect(
        wrapper
          .find(Dropdown.Item)
          .at(numberOfNonCustomFormatOptions + index)
          .text()
      ).toContain(mockPreset.name);
    });
  });
});
