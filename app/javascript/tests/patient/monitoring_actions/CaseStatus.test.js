import React from 'react';
import { shallow, mount } from 'enzyme';
import { Button, Modal, Form } from 'react-bootstrap';
import CaseStatus from '../../../components/patient/monitoring_actions/CaseStatus';
import ApplyToHousehold from '../../../components/patient/household/actions/ApplyToHousehold';
import CustomTable from '../../../components/layout/CustomTable';
import InfoTooltip from '../../../components/util/InfoTooltip';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockMonitoringReasons } from '../../mocks/mockMonitoringReasons';
import { blankIsolationMockPatient, mockPatient1, mockPatient2, mockPatient3, mockPatient4, mockPatient5 } from '../../mocks/mockPatients';

const mockToken = 'testMockTokenString12345';
const caseStatusValues = ['', 'Confirmed', 'Probable', 'Suspect', 'Unknown', 'Not a Case'];
const monitoringOptionValues = ['', 'End Monitoring', 'Continue Monitoring in Isolation Workflow'];
const available_workflows = [
  { name: 'exposure', label: 'Exposure' },
  { name: 'isolation', label: 'Isolation' },
  { name: 'global', label: 'Global' },
];

function getWrapper(patient, aw) {
  return shallow(<CaseStatus patient={patient} current_user={mockUser1} household_members={[]} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} monitoring_reasons={mockMonitoringReasons} workflow={'global'} available_workflows={aw} />);
}

describe('CaseStatus', () => {
  it('Properly renders all main components', () => {
    let aw = available_workflows;
    const wrapper = getWrapper(mockPatient1, aw);
    expect(wrapper.find(Form.Label).text().includes('CASE STATUS')).toBeTruthy();
    expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('caseStatus');
    expect(wrapper.find('#case_status').exists()).toBeTruthy();
    expect(wrapper.find('option').length).toEqual(6);
    caseStatusValues.forEach((value, index) => {
      expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#case_status').prop('value')).toEqual(mockPatient1.case_status);
  });

  it('Changing Case Status opens modal', () => {
    let aw = available_workflows;
    const wrapper = getWrapper(mockPatient1, aw);
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders modal', () => {
    let aw = available_workflows;
    const wrapper = getWrapper(mockPatient1, aw);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Case Status');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find(ApplyToHousehold).exists()).toBeFalsy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');
  });

  it('Correctly renders modal body and does not change line list or workflow for closed record', () => {
    let aw = available_workflows;
    const wrapper = getWrapper(mockPatient3, aw);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.state('showCaseStatusModal')).toBeTruthy();
    expect(wrapper.state('showMonitoringDropdown')).toBeFalsy();
    expect(wrapper.state('case_status')).toEqual('Confirmed');
    expect(wrapper.state('confirmedOrProbable')).toBeTruthy();
    expect(wrapper.state('isolation')).toEqual(mockPatient3.isolation);
    expect(wrapper.state('monitoring')).toBeFalsy();
    expect(modalBody.find('p').text()).toEqual(`Are you sure you want to change case status from ${mockPatient3.case_status} to Confirmed? Since this record is on the Closed line list, updating this value will not move this record to another line list. If this individual should be actively monitored, please update the record’s Monitoring Status.`);
  });

  it('Correctly renders modal body and updates to exposure workflow when changing Case Status to Suspect, Unknown or Not a Case from Confirmed or Probable in isolation workflow', () => {
    let aw = available_workflows;
    const wrapper = getWrapper(mockPatient4, aw);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Unknown' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.state('showCaseStatusModal')).toBeTruthy();
    expect(wrapper.state('showMonitoringDropdown')).toBeFalsy();
    expect(wrapper.state('case_status')).toEqual('Unknown');
    expect(wrapper.state('confirmedOrProbable')).toBeFalsy();
    expect(wrapper.state('isolation')).toBeFalsy();
    expect(modalBody.find('p').text()).toEqual('This case will be moved to the exposure workflow and will be placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate to continue exposure monitoring.');
    expect(modalBody.children().length).toEqual(1); // Ensure no monitoring options dropdowns are present
  });

  it('Correctly renders modal body and does not change workflow or line list when updating Case Status to Confirmed from Probable or vice versa for a record in the Isolation workflow', () => {
    let aw = available_workflows;
    const wrapper = getWrapper(mockPatient4, aw);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.state('showCaseStatusModal')).toBeTruthy();
    expect(wrapper.state('showMonitoringDropdown')).toBeFalsy();
    expect(wrapper.state('case_status')).toEqual('Confirmed');
    expect(wrapper.state('confirmedOrProbable')).toBeTruthy();
    expect(wrapper.state('isolation')).toBeTruthy();
    expect(modalBody.find('p').text()).toEqual(`Are you sure you want to change the case status from ${mockPatient4.case_status} to Confirmed? The record will remain in the isolation workflow.`);
  });

  it('Correctly renders modal body and is moved to the exposure workflow when changing Case Status to Blank in the isolation workflow', () => {
    let aw = available_workflows;
    const wrapper = getWrapper(blankIsolationMockPatient, aw);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: '' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.state('showCaseStatusModal')).toBeTruthy();
    expect(wrapper.state('showMonitoringDropdown')).toBeFalsy();
    expect(wrapper.state('case_status')).toEqual('');
    expect(wrapper.state('confirmedOrProbable')).toBeFalsy();
    expect(wrapper.state('isolation')).toBeFalsy();
    expect(modalBody.find('p').text()).toEqual('The case status for the selected record will be updated to blank and moved to the appropriate line list in the Exposure Workflow.');
  });

  it('Correctly renders modal body and is moved to the exposure workflow when changing Case Status to Suspect, Unknown or Not A Case in the isolation workflow', () => {
    let aw = available_workflows;
    const wrapper = getWrapper(blankIsolationMockPatient, aw);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Suspect' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.state('showCaseStatusModal')).toBeTruthy();
    expect(wrapper.state('showMonitoringDropdown')).toBeFalsy();
    expect(wrapper.state('case_status')).toEqual('Suspect');
    expect(wrapper.state('confirmedOrProbable')).toBeFalsy();
    expect(wrapper.state('isolation')).toBeFalsy();
    expect(modalBody.find('p').text()).toEqual('The case status for the selected record will be updated to Suspect and moved to the appropriate line list in the Exposure Workflow.');
  });

  it('Correctly renders modal body and does not change workflow or line list when when changing Case Status to Suspect, Unknown or Not A Case in the exposure workflow', () => {
    let aw = available_workflows;
    const wrapper = getWrapper(mockPatient2, aw);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Suspect' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.state('showCaseStatusModal')).toBeTruthy();
    expect(wrapper.state('showMonitoringDropdown')).toBeFalsy();
    expect(wrapper.state('case_status')).toEqual('Suspect');
    expect(wrapper.state('confirmedOrProbable')).toBeFalsy();
    expect(wrapper.state('isolation')).toBeFalsy();
    expect(modalBody.find('p').text()).toEqual('The case status for the selected record will be updated to Suspect.');
  });

  it('Correctly renders modal body and changes line list but not workflow when changing Case Status to Suspect, Unknown or Not A Case in the PUI line list of the exposure workflow', () => {
    let aw = available_workflows;
    const wrapper = getWrapper(mockPatient5, aw);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Suspect' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.state('showCaseStatusModal')).toBeTruthy();
    expect(wrapper.state('showMonitoringDropdown')).toBeFalsy();
    expect(wrapper.state('case_status')).toEqual('Suspect');
    expect(wrapper.state('confirmedOrProbable')).toBeFalsy();
    expect(wrapper.state('isolation')).toBeFalsy();
    expect(modalBody.find('p').text()).toEqual('Are you sure you want to change case status to "Suspect"? The monitoree will be placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate to continue exposure monitoring and the Latest Public Health Action will be set to "None".');
  });

  it('Correctly renders modal body when changing Case Status to Confirmed or Probable (all other cases)', () => {
    let aw = available_workflows;
    const wrapper = getWrapper(mockPatient1, aw);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);

    // updates state
    expect(wrapper.state('showCaseStatusModal')).toBeTruthy();
    expect(wrapper.state('showMonitoringDropdown')).toBeTruthy();
    expect(wrapper.state('case_status')).toEqual('Confirmed');
    expect(wrapper.state('confirmedOrProbable')).toBeTruthy();
    expect(wrapper.state('disabled')).toBeTruthy();

    // renders modal elements
    expect(modalBody.find('p').text()).toEqual('Please select what you would like to do:');
    expect(modalBody.find('#monitoring_option').exists()).toBeTruthy();
    expect(modalBody.find('option').length).toEqual(3);
    monitoringOptionValues.forEach((value, index) => {
      expect(modalBody.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find(Button).at(1).prop('disabled')).toBeTruthy();
  });

  it('Changing monitoring option dropdown updates workflow and d isable/enables the submit button', () => {
    let aw = available_workflows;
    const wrapper = getWrapper(mockPatient1, aw);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });

    // initial modal state with monitoring option empty
    expect(wrapper.state('monitoring_option')).toEqual('');
    expect(wrapper.find(Button).at(1).prop('disabled')).toBeTruthy();

    // change monitoring option to End Monitoring
    wrapper.find('#monitoring_option').simulate('change', { target: { id: 'monitoring_option', value: 'End Monitoring' }, persist: jest.fn() });
    wrapper.update();
    expect(wrapper.state('monitoring_option')).toEqual('End Monitoring');
    expect(wrapper.state('isolation')).toEqual(mockPatient1.isolation);
    expect(wrapper.state('monitoring')).toBeFalsy();
    expect(wrapper.find(Button).at(1).prop('disabled')).toBeFalsy();
    expect(wrapper.find('p').at(1).text()).toEqual('The case status for the selected record will be updated to Confirmed and moved to the closed line list in the current workflow.');
    expect(wrapper.find('ModalBody').find('p').at(0).text()).toContain('Please select what you would like to do:');
    const monitoringReasonOptions = [''].concat(mockMonitoringReasons);
    wrapper
      .find('FormGroup')
      .at(0)
      .find('option')
      .forEach((option, index) => {
        expect(option.text()).toEqual(monitoringReasonOptions[Number(index)]);
      });

    // change monitoring option to Continue Monitoring in Isolation Workflow
    wrapper.find('#monitoring_option').simulate('change', { target: { id: 'monitoring_option', value: 'Continue Monitoring in Isolation Workflow' }, persist: jest.fn() });
    wrapper.update();
    expect(wrapper.state('monitoring_option')).toEqual('Continue Monitoring in Isolation Workflow');
    expect(wrapper.state('isolation')).toBeTruthy();
    expect(wrapper.state('monitoring')).toBeTruthy();
    expect(wrapper.find(Button).at(1).prop('disabled')).toBeFalsy();
    expect(wrapper.find('p').at(1).text()).toEqual('The case status for the selected record will be updated to Confirmed and moved to the appropriate line list in the Isolation Workflow.');

    // back to initial modal state with monitoring option empty
    wrapper.find('#monitoring_option').simulate('change', { target: { id: 'monitoring_option', value: '' }, persist: jest.fn() });
    expect(wrapper.state('monitoring_option')).toEqual('');
    expect(wrapper.find(Button).at(1).prop('disabled')).toBeTruthy();
  });

  it('Toggling HoH radio buttons hides/shows household members table and updates state', () => {
    let aw = available_workflows;
    const wrapper = mount(<CaseStatus patient={mockPatient1} current_user={mockUser1} household_members={[mockPatient2, mockPatient3, mockPatient4]} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} workflow={'global'} available_workflows={aw} />);
    wrapper
      .find('#case_status')
      .at(1)
      .simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });

    // initial radio button state
    expect(wrapper.find(ApplyToHousehold).exists()).toBeTruthy();
    expect(wrapper.find(CustomTable).exists()).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_no').at(1).prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').at(1).prop('checked')).toBeFalsy();

    // change to apply to all of household
    wrapper
      .find('#apply_to_household_yes')
      .at(1)
      .simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.find(CustomTable).exists()).toBeTruthy();
    expect(wrapper.state('apply_to_household')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_no').at(1).prop('checked')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_yes').at(1).prop('checked')).toBeTruthy();

    // change back to just this monitoree
    wrapper
      .find('#apply_to_household_no')
      .at(1)
      .simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    expect(wrapper.find(CustomTable).exists()).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_no').at(1).prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').at(1).prop('checked')).toBeFalsy();
  });

  it('Clicking the cancel button closes modal and resets state', () => {
    let aw = available_workflows;
    const wrapper = getWrapper(mockPatient1, aw);

    // closes modal
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
    wrapper.find('#monitoring_option').simulate('change', { target: { id: 'monitoring_option', value: 'End Monitoring' }, persist: jest.fn() });
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();

    // resets state
    expect(wrapper.state('showCaseStatusModal')).toBeFalsy();
    expect(wrapper.state('showMonitoringDropdown')).toBeFalsy();
    expect(wrapper.state('confirmedOrProbable')).toEqual(mockPatient1.case_status === 'Confirmed' || mockPatient1.case_status === 'Probable');
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('case_status')).toEqual(mockPatient1.case_status);
    expect(wrapper.state('disabled')).toBeFalsy();
    expect(wrapper.state('isolation')).toEqual(mockPatient1.isolation);
    expect(wrapper.state('modal_text')).toEqual('');
    expect(wrapper.state('monitoring')).toEqual(mockPatient1.monitoring);
    expect(wrapper.state('monitoring_reason')).toEqual(mockPatient1.monitoring_reason);
    expect(wrapper.state('monitoring_option')).toEqual('');
  });

  it('Clicking the submit button calls the submit method', () => {
    let aw = available_workflows;
    const wrapper = getWrapper(mockPatient1, aw);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
