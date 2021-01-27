import React from 'react'
import { shallow } from 'enzyme';
import PatientsTable from '../../components/public_health/PatientsTable.js'
import JurisdictionFilter from '../../components/public_health/query/JurisdictionFilter.js'
import AssignedUserFilter from '../../components/public_health/query/AssignedUserFilter.js'
import AdvancedFilter from '../../components/public_health/query/AdvancedFilter.js'
import CustomTable from '../../components/layout/CustomTable'
import { mockJurisdiction1, mockJurisdictionPaths } from '../mocks/mockJurisdiction'
import { mockExposureTabs, mockIsolationTabs } from '../mocks/mockTabs'
import { mockMonitoringReasons } from '../mocks/mockMonitoringReasons'

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";
const workflow = 'exposure'
const setQueryMock = jest.fn();
const setMonitoreeCountMock = jest.fn();

function ExposurePatientTable() {
  return shallow(<PatientsTable
    authenticity_token={authyToken}
    jurisdiction_paths={mockJurisdictionPaths}
    workflow={workflow}
    jurisdiction={mockJurisdiction1}
    tabs={mockExposureTabs}
    monitoring_reasons={mockMonitoringReasons}
    setQuery={setQueryMock}
    setFilteredMonitoreesCount={setMonitoreeCountMock}
  />);
}

function IsolationPatientTable() {
  return shallow(<PatientsTable
    authenticity_token={authyToken}
    jurisdiction_paths={mockJurisdictionPaths}
    workflow={workflow}
    jurisdiction={mockJurisdiction1}
    tabs={mockIsolationTabs}
    monitoring_reasons={mockMonitoringReasons}
    setQuery={setQueryMock}
    setFilteredMonitoreesCount={setMonitoreeCountMock}
  />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('PatientsTable', () => {
  it('Properly renders all main components', () => {
    const patientTable = ExposurePatientTable();
    expect(patientTable.find('#search').exists()).toBeTruthy();
    expect(patientTable.containsMatchingElement(JurisdictionFilter)).toBeTruthy();
    expect(patientTable.containsMatchingElement(AssignedUserFilter)).toBeTruthy();
    expect(patientTable.containsMatchingElement(AdvancedFilter)).toBeTruthy();
    expect(patientTable.containsMatchingElement(CustomTable)).toBeTruthy();
  });

  describe('ExposureDashboard', () => {
    it('Properly renders all tabs', () => {
      const patientTable = ExposurePatientTable();
      for (var key of Object.keys(mockExposureTabs)) {
        expect(patientTable.find('#' + key + '_tab').exists()).toBeTruthy();
      }
    });
  });

  describe('IsolationDashboard', () => {
    it('Properly renders all tabs', () => {
      const patientTable = IsolationPatientTable();
      for (var key of Object.keys(mockIsolationTabs)) {
        expect(patientTable.find('#' + key + '_tab').exists()).toBeTruthy();
      }
    });
  });
});