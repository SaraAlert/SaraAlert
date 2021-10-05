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

function getWrapper(patient) {
  return shallow(<CaseStatus patient={patient} current_user={mockUser1} household_members={[]} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} monitoring_reasons={mockMonitoringReasons} workflow={'global'} />);
}

describe('CaseStatus', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper(mockPatient1);
    expect(wrapper.find(Form.Label).text()).toContain('CASE STATUS');
    expect(wrapper.find(InfoTooltip).exists()).toBe(true);
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('caseStatus');
    expect(wrapper.find('#case_status').exists()).toBe(true);
    expect(wrapper.find('option').length).toEqual(6);
    caseStatusValues.forEach((value, index) => {
      expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#case_status').prop('value')).toEqual(mockPatient1.case_status);
  });

  it('Changing Case Status opens modal', () => {
    const wrapper = getWrapper(mockPatient1);
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
    expect(wrapper.find(Modal).exists()).toBe(true);
  });

  it('Properly renders modal', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
    expect(wrapper.find(Modal.Title).exists()).toBe(true);
    expect(wrapper.find(Modal.Title).text()).toEqual('Case Status');
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find(ApplyToHousehold).exists()).toBe(false);
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');
  });

  it('Correctly renders modal body and does not change line list or workflow for closed record', () => {
    const wrapper = getWrapper(mockPatient3);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.state('showCaseStatusModal')).toBe(true);
    expect(wrapper.state('showMonitoringDropdown')).toBe(false);
    expect(wrapper.state('case_status')).toEqual('Confirmed');
    expect(wrapper.state('confirmedOrProbable')).toBe(true);
    expect(wrapper.state('isolation')).toEqual(mockPatient3.isolation);
    expect(wrapper.state('monitoring')).toBe(false);
    expect(modalBody.find('p').text()).toEqual(`Are you sure you want to change case status from ${mockPatient3.case_status} to Confirmed? Since this record is on the Closed line list, updating this value will not move this record to another line list. If this individual should be actively monitored, please update the record’s Monitoring Status.`);
  });

  it('Correctly renders modal body and updates to exposure workflow when changing Case Status to Suspect, Unknown or Not a Case from Confirmed or Probable in isolation workflow', () => {
    const wrapper = getWrapper(mockPatient4);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Unknown' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.state('showCaseStatusModal')).toBe(true);
    expect(wrapper.state('showMonitoringDropdown')).toBe(false);
    expect(wrapper.state('case_status')).toEqual('Unknown');
    expect(wrapper.state('confirmedOrProbable')).toBe(false);
    expect(wrapper.state('isolation')).toBe(false);
    expect(modalBody.find('p').text()).toEqual('This case will be moved to the exposure workflow and will be placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate to continue exposure monitoring.');
    expect(modalBody.children().length).toEqual(1); // Ensure no monitoring options dropdowns are present
  });

  it('Correctly renders modal body and does not change workflow or line list when updating Case Status to Confirmed from Probable or vice versa for a record in the Isolation workflow', () => {
    const wrapper = getWrapper(mockPatient4);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.state('showCaseStatusModal')).toBe(true);
    expect(wrapper.state('showMonitoringDropdown')).toBe(false);
    expect(wrapper.state('case_status')).toEqual('Confirmed');
    expect(wrapper.state('confirmedOrProbable')).toBe(true);
    expect(wrapper.state('isolation')).toBe(true);
    expect(modalBody.find('p').text()).toEqual(`Are you sure you want to change the case status from ${mockPatient4.case_status} to Confirmed? The record will remain in the isolation workflow.`);
  });

  it('Correctly renders modal body and is moved to the exposure workflow when changing Case Status to Blank in the isolation workflow', () => {
    const wrapper = getWrapper(blankIsolationMockPatient);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: '' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.state('showCaseStatusModal')).toBe(true);
    expect(wrapper.state('showMonitoringDropdown')).toBe(false);
    expect(wrapper.state('case_status')).toEqual('');
    expect(wrapper.state('confirmedOrProbable')).toBe(false);
    expect(wrapper.state('isolation')).toBe(false);
    expect(modalBody.find('p').text()).toEqual('The case status for the selected record will be updated to blank and moved to the appropriate line list in the Exposure Workflow.');
  });

  it('Correctly renders modal body and is moved to the exposure workflow when changing Case Status to Suspect, Unknown or Not A Case in the isolation workflow', () => {
    const wrapper = getWrapper(blankIsolationMockPatient);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Suspect' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.state('showCaseStatusModal')).toBe(true);
    expect(wrapper.state('showMonitoringDropdown')).toBe(false);
    expect(wrapper.state('case_status')).toEqual('Suspect');
    expect(wrapper.state('confirmedOrProbable')).toBe(false);
    expect(wrapper.state('isolation')).toBe(false);
    expect(modalBody.find('p').text()).toEqual('The case status for the selected record will be updated to Suspect and moved to the appropriate line list in the Exposure Workflow.');
  });

  it('Correctly renders modal body and does not change workflow or line list when when changing Case Status to Suspect, Unknown or Not A Case in the exposure workflow', () => {
    const wrapper = getWrapper(mockPatient2);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Suspect' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.state('showCaseStatusModal')).toBe(true);
    expect(wrapper.state('showMonitoringDropdown')).toBe(false);
    expect(wrapper.state('case_status')).toEqual('Suspect');
    expect(wrapper.state('confirmedOrProbable')).toBe(false);
    expect(wrapper.state('isolation')).toBe(false);
    expect(modalBody.find('p').text()).toEqual('The case status for the selected record will be updated to Suspect.');
  });

  it('Correctly renders modal body and changes line list but not workflow when changing Case Status to Suspect, Unknown or Not A Case in the PUI line list of the exposure workflow', () => {
    const wrapper = getWrapper(mockPatient5);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Suspect' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.state('showCaseStatusModal')).toBe(true);
    expect(wrapper.state('showMonitoringDropdown')).toBe(false);
    expect(wrapper.state('case_status')).toEqual('Suspect');
    expect(wrapper.state('confirmedOrProbable')).toBe(false);
    expect(wrapper.state('isolation')).toBe(false);
    expect(modalBody.find('p').text()).toEqual('Are you sure you want to change case status to "Suspect"? The monitoree will be placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate to continue exposure monitoring and the Latest Public Health Action will be set to "None".');
  });

  it('Correctly renders modal body when changing Case Status to Confirmed or Probable (all other cases)', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
    const modalBody = wrapper.find(Modal.Body);

    // updates state
    expect(wrapper.state('showCaseStatusModal')).toBe(true);
    expect(wrapper.state('showMonitoringDropdown')).toBe(true);
    expect(wrapper.state('case_status')).toEqual('Confirmed');
    expect(wrapper.state('confirmedOrProbable')).toBe(true);
    expect(wrapper.state('disabled')).toBe(true);

    // renders modal elements
    expect(modalBody.find('p').text()).toEqual('Please select what you would like to do:');
    expect(modalBody.find('#monitoring_option').exists()).toBe(true);
    expect(modalBody.find('option').length).toEqual(3);
    monitoringOptionValues.forEach((value, index) => {
      expect(modalBody.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
  });

  it('Changing monitoring option dropdown updates workflow and disable/enables the submit button', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });

    // initial modal state with monitoring option empty
    expect(wrapper.state('monitoring_option')).toEqual('');
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);

    // change monitoring option to End Monitoring
    wrapper.find('#monitoring_option').simulate('change', { target: { id: 'monitoring_option', value: 'End Monitoring' }, persist: jest.fn() });
    wrapper.update();
    expect(wrapper.state('monitoring_option')).toEqual('End Monitoring');
    expect(wrapper.state('isolation')).toEqual(mockPatient1.isolation);
    expect(wrapper.state('monitoring')).toBe(false);
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(false);
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
    expect(wrapper.state('isolation')).toBe(true);
    expect(wrapper.state('monitoring')).toBe(true);
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(false);
    expect(wrapper.find('p').at(1).text()).toEqual('The case status for the selected record will be updated to Confirmed and moved to the appropriate line list in the Isolation Workflow.');

    // back to initial modal state with monitoring option empty
    wrapper.find('#monitoring_option').simulate('change', { target: { id: 'monitoring_option', value: '' }, persist: jest.fn() });
    expect(wrapper.state('monitoring_option')).toEqual('');
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
  });

  it('Toggling HoH radio buttons hides/shows household members table and updates state', () => {
    const wrapper = mount(<CaseStatus patient={mockPatient1} current_user={mockUser1} household_members={[mockPatient2, mockPatient3, mockPatient4]} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} workflow={'global'} />);
    wrapper
      .find('#case_status')
      .hostNodes()
      .simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });

    // initial radio button state
    expect(wrapper.find(ApplyToHousehold).exists()).toBe(true);
    expect(wrapper.find(CustomTable).exists()).toBe(false);
    expect(wrapper.state('apply_to_household')).toBe(false);
    expect(wrapper.find('#apply_to_household_no').hostNodes().prop('checked')).toBe(true);
    expect(wrapper.find('#apply_to_household_yes').hostNodes().prop('checked')).toBe(false);

    // change to apply to all of household
    wrapper
      .find('#apply_to_household_yes')
      .hostNodes()
      .simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.find(CustomTable).exists()).toBe(true);
    expect(wrapper.state('apply_to_household')).toBe(true);
    expect(wrapper.find('#apply_to_household_no').hostNodes().prop('checked')).toBe(false);
    expect(wrapper.find('#apply_to_household_yes').hostNodes().prop('checked')).toBe(true);

    // change back to just this monitoree
    wrapper
      .find('#apply_to_household_no')
      .hostNodes()
      .simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    expect(wrapper.find(CustomTable).exists()).toBe(false);
    expect(wrapper.state('apply_to_household')).toBe(false);
    expect(wrapper.find('#apply_to_household_no').hostNodes().prop('checked')).toBe(true);
    expect(wrapper.find('#apply_to_household_yes').hostNodes().prop('checked')).toBe(false);
  });

  it('Clicking the cancel button closes modal and resets state', () => {
    const wrapper = getWrapper(mockPatient1);

    // closes modal
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
    wrapper.find('#monitoring_option').simulate('change', { target: { id: 'monitoring_option', value: 'End Monitoring' }, persist: jest.fn() });
    expect(wrapper.find(Modal).exists()).toBe(true);
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(false);

    // resets state
    expect(wrapper.state('showCaseStatusModal')).toBe(false);
    expect(wrapper.state('showMonitoringDropdown')).toBe(false);
    expect(wrapper.state('confirmedOrProbable')).toEqual(mockPatient1.case_status === 'Confirmed' || mockPatient1.case_status === 'Probable');
    expect(wrapper.state('apply_to_household')).toBe(false);
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('case_status')).toEqual(mockPatient1.case_status);
    expect(wrapper.state('disabled')).toBe(false);
    expect(wrapper.state('isolation')).toEqual(mockPatient1.isolation);
    expect(wrapper.state('modal_text')).toEqual('');
    expect(wrapper.state('monitoring')).toEqual(mockPatient1.monitoring);
    expect(wrapper.state('monitoring_reason')).toEqual(mockPatient1.monitoring_reason);
    expect(wrapper.state('monitoring_option')).toEqual('');
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getWrapper(mockPatient1);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
    expect(submitSpy).not.toHaveBeenCalled();
    wrapper.find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
