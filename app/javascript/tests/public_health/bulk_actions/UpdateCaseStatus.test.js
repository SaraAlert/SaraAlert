import React from 'react';
import { shallow } from 'enzyme';
import { Button, Form, Modal } from 'react-bootstrap';
import UpdateCaseStatus from '../../../components/public_health/bulk_actions/UpdateCaseStatus';
import { mockMonitoringReasons } from '../../mocks/mockMonitoringReasons';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4, mockPatient5, mockPatient6 } from '../../mocks/mockPatients';

const onCloseMock = jest.fn();
const mockToken = 'testMockTokenString12345';
const CASE_STATUS_OPTIONS = ['', 'Confirmed', 'Probable', 'Suspect', 'Unknown', 'Not a Case'];
const available_workflows = [
  { name: 'exposure', label: 'Exposure' },
  { name: 'isolation', label: 'Isolation' },
  { name: 'global', label: 'Global' },
];

function simulateStateChange(patientsArray) {
  // UpdateCaseStatus makes an asynchronous call to obtain values about the selectedPatients
  // Since we have the full patient objects here, simulate that call by running the same code
  // as the callback here. This sets the State properly so the component behaves as expected
  const distinctCaseStatus = [...new Set(patientsArray.map(x => x.case_status))];
  const distinctIsolation = [...new Set(patientsArray.map(x => x.isolation))];
  const distinctMonitoring = [...new Set(patientsArray.map(x => x.monitoring))];

  const state_updates = {};
  if (distinctCaseStatus.length === 1 && distinctCaseStatus[0] !== null) {
    state_updates.initialCaseStatus = distinctCaseStatus[0];
    state_updates.case_status = distinctCaseStatus[0];
  }
  if (distinctIsolation.length === 1 && distinctIsolation[0] !== null) {
    state_updates.initialIsolation = distinctIsolation[0];
    state_updates.isolation = distinctIsolation[0];
  }
  if (distinctMonitoring.length === 1 && distinctMonitoring[0] !== null) {
    state_updates.initialMonitoring = distinctMonitoring[0];
    state_updates.monitoring = distinctMonitoring[0];
  }
  return state_updates;
}

function getWrapper(patientsArray) {
  let wrapper = shallow(<UpdateCaseStatus authenticity_token={mockToken} patients={patientsArray} monitoring_reasons={mockMonitoringReasons} close={onCloseMock} available_workflows={available_workflows} />);

  let state_updates = simulateStateChange(patientsArray);
  if (Object.keys(state_updates).length) {
    wrapper.setState(state_updates);
    // no need to use a callback here as the state changes
    // appear to be performed serially
  }
  return wrapper;
}

describe('UpdateCaseStatus', () => {
  it('Properly renders all main components for Patients who are in Exposure only', () => {
    // mockPatien2 and mockPatient3 are both in the Exposure workflow
    const wrapper = getWrapper([mockPatient2, mockPatient5]);
    expect(wrapper.find(Modal.Body).find('p').at(0).text()).toContain('Please select the desired case status to be assigned to all selected patients:');
    wrapper
      .find('#case_status')
      .find('option')
      .forEach((option, index) => {
        expect(option.text()).toEqual(CASE_STATUS_OPTIONS[Number(index)]);
      });
    expect(wrapper.find(Modal.Body).find('p').at(1).text()).toContain('The selected cases will remain in the exposure workflow.');
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Submit');
  });

  it('Properly renders all main components for Patients who are in Isolation only', () => {
    // mockPatient6 is in the Isolation workflow, but is not closed
    const wrapper = getWrapper([mockPatient6]);
    expect(wrapper.find(Modal.Body).find('p').at(0).text()).toContain('Please select the desired case status to be assigned to all selected patients:');
    wrapper
      .find('#case_status')
      .find('option')
      .forEach((option, index) => {
        expect(option.text()).toEqual(CASE_STATUS_OPTIONS[Number(index)]);
      });
    expect(wrapper.find(Modal.Body).find('p').at(1).text()).toContain('The selected cases will be moved from the isolation workflow to the exposure workflow and placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate.');
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Submit');
  });

  it('Properly sets the correct follow-up options for "Confirmed", and "Probable" in the Exposure Workflow', () => {
    // mockPatient5 is in the Exposure Workflow and is not closed
    const wrapper = getWrapper([mockPatient5]);
    ['Confirmed', 'Probable'].forEach(case_status_option => {
      wrapper
        .find(Form.Control)
        .first()
        .simulate('change', { target: { id: 'case_status', type: 'change', value: case_status_option }, persist: jest.fn() });
      expect(wrapper.state('case_status')).toEqual(case_status_option);

      const CASE_STATUS_FOLLOW_UP_OPTIONS = ['', 'End Monitoring', 'Continue Monitoring in Isolation Workflow'];
      wrapper
        .find(Form.Control)
        .at(1)
        .find('option')
        .forEach((option, index) => {
          expect(option.text()).toEqual(CASE_STATUS_FOLLOW_UP_OPTIONS[Number(index)]);
        });

      // The follow_up options for `End Monitoring` and `Continue Monitoring in Isolation Workflow` are different, so test them separately
      // > `End Monitoring` Tests
      wrapper
        .find(Form.Control)
        .at(1)
        .simulate('change', { target: { id: 'follow_up', type: 'change', value: 'End Monitoring' }, persist: jest.fn() });
      expect(wrapper.state('follow_up')).toEqual('End Monitoring');
      expect(wrapper.find(Form.Control).length).toEqual(4);
      expect(wrapper.find('p').at(2).text()).toContain('The selected monitorees will be moved into the Closed line list, and will no longer be monitored.');
      const monitoringReasonOptions = [''].concat(mockMonitoringReasons);
      wrapper
        .find('#monitoring_reason')
        .find('option')
        .forEach((option, index) => {
          expect(option.text()).toEqual(monitoringReasonOptions[Number(index)]);
          wrapper.find('#monitoring_reason').simulate('change', { target: { id: 'monitoring_reason', value: option }, persist: jest.fn() });
          expect(wrapper.state('monitoring_reason')).toEqual(option);
        });
      const mockReasoning = 'I Shall Call Him Squishy And He Shall Be Mine And He Shall Be My Squishy.';
      wrapper
        .find(Form.Group)
        .at(1)
        .find(Form.Control)
        .simulate('change', { target: { id: 'reasoning', value: mockReasoning }, persist: jest.fn() });
      expect(wrapper.state('reasoning')).toEqual(mockReasoning);
      expect(
        wrapper
          .find('.character-limit-text')
          .first()
          .text()
      ).toContain(`${2000 - mockReasoning.length} characters remaining`);

      // > `Continue Monitoring in Isolation Workflow` Tests
      wrapper
        .find(Form.Control)
        .at(1)
        .simulate('change', { target: { id: 'follow_up', type: 'change', value: 'Continue Monitoring in Isolation Workflow' }, persist: jest.fn() });
      expect(wrapper.state('follow_up')).toEqual('Continue Monitoring in Isolation Workflow');
      expect(wrapper.find('p').at(2).text()).toContain('The selected monitorees will be moved to the isolation workflow and placed in the requiring review, non-reporting, or reporting line list as appropriate.');
      wrapper.find(Form.Check).simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: false }, persist: jest.fn() });
      expect(wrapper.state('apply_to_household')).toBeFalsy();
      wrapper.find(Form.Check).simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: true }, persist: jest.fn() });
      expect(wrapper.state('apply_to_household')).toBeTruthy();
    });
  });

  it('Properly sets the correct follow-up options for "Confirmed", and "Probable" in the Isolation Workflow', () => {
    // mockPatient6 is in the Isolation workflow, but is not closed
    const wrapper = getWrapper([mockPatient6]);
    ['Confirmed', 'Probable'].forEach(case_status_option => {
      wrapper
        .find(Form.Control)
        .first()
        .simulate('change', { target: { id: 'case_status', type: 'change', value: case_status_option }, persist: jest.fn() });
      expect(wrapper.state('case_status')).toEqual(case_status_option);
      expect(
        wrapper
          .find('p')
          .at(1)
          .text()
      ).toContain('The selected cases will remain in the isolation workflow.');
      // there are no dropdowns for "Suspect", "Unknown" and "Not a Case"
      expect(wrapper.find(Form.Control).at(1).exists()).toBeFalsy();
      wrapper.find(Form.Check).simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: false }, persist: jest.fn() });
      expect(wrapper.state('apply_to_household')).toBeFalsy();
      wrapper.find(Form.Check).simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: true }, persist: jest.fn() });
      expect(wrapper.state('apply_to_household')).toBeTruthy();
    });
  });

  it('Properly sets the correct follow-up options for all selected monitorees are already closed', () => {
    // mockPatient5 is in the Exposure Workflow and is not closed
    const wrapper = getWrapper([mockPatient2, mockPatient3]);
    ['Confirmed', 'Probable'].forEach(case_status_option => {
      wrapper
        .find(Form.Control)
        .first()
        .simulate('change', { target: { id: 'case_status', type: 'change', value: case_status_option }, persist: jest.fn() });
      expect(wrapper.state('case_status')).toEqual(case_status_option);
      expect(wrapper.state('allSelectedAreClosed')).toBeTruthy();

      // When all are closed, there is no follow-up dropdown, so this shoud be 3, instead of the usual 4
      expect(wrapper.find(Form.Control).length).toEqual(3);

      const monitoringReasonOptions = [''].concat(mockMonitoringReasons);
      wrapper
        .find('#monitoring_reason')
        .find('option')
        .forEach((option, index) => {
          expect(option.text()).toEqual(monitoringReasonOptions[Number(index)]);
          wrapper.find('#monitoring_reason').simulate('change', { target: { id: 'monitoring_reason', value: option }, persist: jest.fn() });
          expect(wrapper.state('monitoring_reason')).toEqual(option);
        });
      const mockReasoning = 'I Shall Call Him Squishy And He Shall Be Mine And He Shall Be My Squishy.';
      wrapper
        .find(Form.Group)
        .at(1)
        .find(Form.Control)
        .simulate('change', { target: { id: 'reasoning', value: mockReasoning }, persist: jest.fn() });
      expect(wrapper.state('reasoning')).toEqual(mockReasoning);
      expect(
        wrapper
          .find('.character-limit-text')
          .first()
          .text()
      ).toContain(`${2000 - mockReasoning.length} characters remaining`);
    });
  });

  it('Properly sets the correct follow-up options for "", "Suspect", "Unknown, and "Not a Case" for the Isolation Workflow', () => {
    // mockPatient6 is in the Isolation workflow, but is not closed
    const wrapper = getWrapper([mockPatient6]);
    // "", "Suspect", "Unknown" and "Not a Case" have identical behavior in the modal
    ['', 'Suspect', 'Unknown', 'Not a Case'].forEach(case_status_option => {
      wrapper
        .find(Form.Control)
        .first()
        .simulate('change', { target: { id: 'case_status', type: 'change', value: case_status_option }, persist: jest.fn() });

      expect(
        wrapper
          .find('p')
          .at(1)
          .text()
      ).toContain('The selected cases will be moved from the isolation workflow to the exposure workflow and placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate.');
      // there are no dropdowns for "Suspect", "Unknown" and "Not a Case"
      expect(wrapper.find(Form.Control).at(1).exists()).toBeFalsy();
      wrapper.find(Form.Check).simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: false }, persist: jest.fn() });
      expect(wrapper.state('apply_to_household')).toBeFalsy();
      wrapper.find(Form.Check).simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: true }, persist: jest.fn() });
      expect(wrapper.state('apply_to_household')).toBeTruthy();
    });
  });

  it('Properly sets the correct follow-up options for "", "Suspect", "Unknown, and "Not a Case" for the Exposure Workflow', () => {
    // mockPatient5 is in the Exposure Workflow and is not closed
    const wrapper = getWrapper([mockPatient5]);
    // "", "Suspect", "Unknown" and "Not a Case" have identical behavior in the modal
    ['', 'Suspect', 'Unknown', 'Not a Case'].forEach(case_status_option => {
      wrapper
        .find(Form.Control)
        .first()
        .simulate('change', { target: { id: 'case_status', type: 'change', value: case_status_option }, persist: jest.fn() });

      expect(
        wrapper
          .find('p')
          .at(1)
          .text()
      ).toContain('The selected cases will remain in the exposure workflow.');
      // there are no dropdowns for "Suspect", "Unknown" and "Not a Case"
      expect(wrapper.find(Form.Control).at(1).exists()).toBeFalsy();
      wrapper.find(Form.Check).simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: false }, persist: jest.fn() });
      expect(wrapper.state('apply_to_household')).toBeFalsy();
      wrapper.find(Form.Check).simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: true }, persist: jest.fn() });
      expect(wrapper.state('apply_to_household')).toBeTruthy();
    });
  });

  it('Properly calls the close method', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient2, mockPatient3, mockPatient4]);
    expect(wrapper.find(Button).at(0).text()).toContain('Cancel');
    expect(onCloseMock).not.toHaveBeenCalled();
    wrapper.find(Button).at(0).simulate('click');
    expect(onCloseMock).toHaveBeenCalled();
  });

  it('Properly calls the submit method', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient2, mockPatient3, mockPatient4]);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.instance().forceUpdate(); // must forceUpdate to properly mount the spy

    expect(wrapper.find(Button).at(1).text()).toContain('Submit');
    expect(submitSpy).not.toHaveBeenCalled();
    wrapper.find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
