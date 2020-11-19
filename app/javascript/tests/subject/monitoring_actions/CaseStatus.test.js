import React from 'react'
import { shallow } from 'enzyme';
import { Button, Modal, Form } from 'react-bootstrap';
import CaseStatus from '../../../components/subject/monitoring_actions/CaseStatus'
import InfoTooltip from '../../../components/util/InfoTooltip';
import { blankMockPatient, mockPatient1, mockPatient2, mockPatient3, mockPatient4, mockPatient5 } from '../../mocks/mockPatients';

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const caseStatusValues = [ '', 'Confirmed', 'Probable', 'Suspect', 'Unknown', 'Not a Case' ];
const monitoringOptionValues = [ '', 'End Monitoring', 'Continue Monitoring in Isolation Workflow' ];

function getWrapper(patient, hasDependents) {
    return shallow(<CaseStatus patient={patient} has_dependents={hasDependents} authenticity_token={authyToken} />);
}

describe('CaseStatus', () => {
    it('Properly renders all main components', () => {
        const wrapper = getWrapper(mockPatient1, false);
        expect(wrapper.find(Form.Label).text().includes('CASE STATUS')).toBeTruthy();
        expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
        expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('caseStatus');
        expect(wrapper.find('#case_status').exists()).toBeTruthy();
        expect(wrapper.find('option').length).toEqual(6);
        caseStatusValues.forEach(function(value, index) {
            expect(wrapper.find('option').at(index).text()).toEqual(value);
        });
        expect(wrapper.find('#case_status').prop('value')).toEqual(mockPatient1.case_status);
    });

    it('Changing Case Status opens modal', () => {
        const wrapper = getWrapper(mockPatient1, false);
        expect(wrapper.find(Modal).exists()).toBeFalsy();
        wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
        expect(wrapper.find(Modal).exists()).toBeTruthy();
    });

    it('Properly renders modal', () => {
        const wrapper = getWrapper(mockPatient1, false);
        wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
        expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
        expect(wrapper.find(Modal.Title).text()).toEqual('Case Status');
        expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
        expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
        expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
        expect(wrapper.find(Button).at(1).text()).toEqual('Submit');
    });

    it('Correctly renders modal body and does not change line list or workflow for closed record', () => {
        const wrapper = getWrapper(mockPatient3, false);
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

    it('Correctly renders modal body and and does not change line list or workflow when changing Case Status to blank', () => {
        const wrapper = getWrapper(mockPatient1, false);
        wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: '' }, persist: jest.fn() });
        const modalBody = wrapper.find(Modal.Body);

        expect(wrapper.state('showCaseStatusModal')).toBeTruthy();
        expect(wrapper.state('showMonitoringDropdown')).toBeFalsy();
        expect(wrapper.state('case_status')).toEqual('');
        expect(wrapper.state('confirmedOrProbable')).toBeFalsy();
        expect(wrapper.state('isolation')).toEqual(mockPatient1.isolation);
        expect(wrapper.state('monitoring')).toBeTruthy();
        expect(modalBody.find('p').text()).toEqual(`Are you sure you want to change case status from ${mockPatient1.case_status} to blank? The monitoree will remain in the same workflow.`);
    });

    it('Correctly renders modal body and updates to exposure workflow when changing Case Status to Suspect, Unknown or Not a Case from Confirmed or Probable in isolation workflow', () => {
        const wrapper = getWrapper(mockPatient4, false);
        wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Unknown' }, persist: jest.fn() });
        const modalBody = wrapper.find(Modal.Body);

        expect(wrapper.state('showCaseStatusModal')).toBeTruthy();
        expect(wrapper.state('showMonitoringDropdown')).toBeFalsy();
        expect(wrapper.state('case_status')).toEqual('Unknown');
        expect(wrapper.state('confirmedOrProbable')).toBeFalsy();
        expect(wrapper.state('isolation')).toBeFalsy();
        expect(modalBody.find('p').text()).toEqual('This case will be moved to the exposure workflow and will be placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate to continue exposure monitoring.');
    });

    it('Correctly renders modal body and does not change workflow or line list when updating Case Status to Confirmed from Probable or vice versa for a record in the Isolation workflow', () => {
        const wrapper = getWrapper(mockPatient4, false);
        wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
        const modalBody = wrapper.find(Modal.Body);

        expect(wrapper.state('showCaseStatusModal')).toBeTruthy();
        expect(wrapper.state('showMonitoringDropdown')).toBeFalsy();
        expect(wrapper.state('case_status')).toEqual('Confirmed');
        expect(wrapper.state('confirmedOrProbable')).toBeTruthy();
        expect(wrapper.state('isolation')).toBeTruthy();
        expect(modalBody.find('p').text()).toEqual(`Are you sure you want to change the case status from ${mockPatient4.case_status} to Confirmed? The record will remain in the isolation workflow.`);
    });

    it('Correctly renders modal body and is moved to the exposure workflow when changing Case Status to Suspect, Unknown or Not A Case in the isolation workflow', () => {
        const wrapper = getWrapper(blankMockPatient, false);
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
        const wrapper = getWrapper(mockPatient2, false);
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
        const wrapper = getWrapper(mockPatient5, false);
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
        const wrapper = getWrapper(mockPatient1, false);
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
        monitoringOptionValues.forEach(function(value, index) {
            expect(modalBody.find('option').at(index).text()).toEqual(value);
        });
        expect(wrapper.find(Button).at(1).prop('disabled')).toBeTruthy();
    });

    it('Changing monitoring option dropdown updates workflow and disable/enables the submit button', () => {
        const wrapper = getWrapper(mockPatient1, false);
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

    it('Properly renders radio buttons for HoH', () => {
        const wrapper = getWrapper(mockPatient1, true);
        wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
        const modalBody = wrapper.find(Modal.Body);

        expect(modalBody.find(Form.Group).exists()).toBeTruthy();
        expect(modalBody.find(Form.Check).length).toEqual(2);
        expect(modalBody.find('#apply_to_household_no').prop('type')).toEqual('radio');
        expect(modalBody.find('#apply_to_household_no').prop('label')).toEqual('This monitoree only');
        expect(modalBody.find('#apply_to_household_yes').prop('type')).toEqual('radio');
        expect(modalBody.find('#apply_to_household_yes').prop('label')).toEqual('This monitoree and all household members');
    });

    it('Clicking HoH radio buttons toggles this.state.apply_to_household', () => {
        const wrapper = getWrapper(mockPatient1, true);
        wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });

        // initial radio button state
        expect(wrapper.state('apply_to_household')).toBeFalsy();
        expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeTruthy();
        expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeFalsy();

        // change to apply to all of household
        wrapper.find('#apply_to_household_yes').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' }, persist: jest.fn() });
        wrapper.update();
        expect(wrapper.state('apply_to_household')).toBeTruthy();
        expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeFalsy();
        expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeTruthy();

        // change back to just this monitoree
        wrapper.find('#apply_to_household_no').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' }, persist: jest.fn() });
        wrapper.update();
        expect(wrapper.state('apply_to_household')).toBeFalsy();
        expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeTruthy();
        expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeFalsy();
    });

    it('Clicking the cancel button closes modal and resets state', () => {
        const wrapper = getWrapper(mockPatient1, false);

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
        expect(wrapper.state('case_status')).toEqual(mockPatient1.case_status);
        expect(wrapper.state('disabled')).toBeFalsy();
        expect(wrapper.state('isolation')).toEqual(mockPatient1.isolation);
        expect(wrapper.state('modal_text')).toEqual('');
        expect(wrapper.state('monitoring')).toEqual(mockPatient1.monitoring);
        expect(wrapper.state('monitoring_reason')).toEqual(mockPatient1.monitoring_reason);
        expect(wrapper.state('monitoring_option')).toEqual('');
    });

    it('Clicking the submit button calls the submit method', () => {
        const wrapper = getWrapper(mockPatient1, false);
        const submitSpy = jest.spyOn(wrapper.instance(), 'submit');

        wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: 'Confirmed' }, persist: jest.fn() });
        expect(submitSpy).toHaveBeenCalledTimes(0);
        wrapper.find(Button).at(1).simulate('click');
        expect(submitSpy).toHaveBeenCalled();
    });
});
