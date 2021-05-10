import React from 'react';
import { mount } from 'enzyme';
import UpdateCaseStatus from '../../../components/public_health/actions/UpdateCaseStatus';
import { mockMonitoringReasons } from '../../mocks/mockMonitoringReasons';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4, mockPatient5 } from '../../mocks/mockPatients';

const onCloseMock = jest.fn();
const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

function simulateStateChange (patientsArray) {
  // UpdateCaseStatus makes an asynchronous call to obtain values about the selectedPatients
  // Since we have the full patient objects here, simulate that call by running the same code
  // as the callback here. This sets the State properly so the component behaves as expected
  const distinctCaseStatus = [...new Set(patientsArray.map(x=>x.case_status))];
  const distinctIsolation = [...new Set(patientsArray.map(x=>x.isolation))];
  const distinctMonitoring = [...new Set(patientsArray.map(x=>x.monitoring))];

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
  return state_updates
}

function getMountedWrapper(patientsArray) {
  let instance = mount(<UpdateCaseStatus
    authenticity_token={authyToken}
    patients={patientsArray}
    monitoring_reasons={mockMonitoringReasons}
    close={onCloseMock}
    />);

  let state_updates = simulateStateChange(patientsArray)
  if (Object.keys(state_updates).length) {
    instance.setState(state_updates)
    // no need to use a callback here as the state changes
    // appear to be performed serially
  }
  return instance
}

const CASE_STATUS_OPTIONS = ['', 'Confirmed', 'Probable', 'Suspect', 'Unknown', 'Not a Case']

afterEach(() => {
  jest.clearAllMocks();
});

describe('UpdateCaseStatus', () => {
  it('Properly renders all main components for Patients who are in Exposure only', () => {
    // mockPatien2 and mockPatient3 are both in the Exposure workflow
    const mountedWrapper = getMountedWrapper([mockPatient2, mockPatient5]);
    expect(mountedWrapper.find('.modal-body').find('p').at(0).text()).toContain('Please select the desired case status to be assigned to all selected patients:')
    mountedWrapper.find('#case_status').find('option').forEach((option, index) => {
      expect(option.text()).toEqual(CASE_STATUS_OPTIONS[index]);
    });
    expect(mountedWrapper.find('.modal-body').find('p').at(1).text()).toContain('The selected cases will remain in the exposure workflow.')
    expect(mountedWrapper.find('ModalFooter').find('Button').at(0).text()).toEqual('Cancel')
    expect(mountedWrapper.find('ModalFooter').find('Button').at(1).text()).toEqual('Submit')
  });

  it('Properly renders all main components for Patients who are in Isolation only', () => {
    // mockPatien1 and mockPatient4 are both in the Isolation workflow
    const mountedWrapper = getMountedWrapper([mockPatient1, mockPatient4]);
    expect(mountedWrapper.find('.modal-body').find('p').at(0).text()).toContain('Please select the desired case status to be assigned to all selected patients:')
    mountedWrapper.find('#case_status').find('option').forEach((option, index) => {
      expect(option.text()).toEqual(CASE_STATUS_OPTIONS[index]);
    });
    expect(mountedWrapper.find('.modal-body').find('p').at(1).text()).toContain('The selected cases will be moved from the isolation workflow to the exposure workflow and placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate.')
    expect(mountedWrapper.find('ModalFooter').find('Button').at(0).text()).toEqual('Cancel')
    expect(mountedWrapper.find('ModalFooter').find('Button').at(1).text()).toEqual('Submit')
  });

  it('Properly renders all main components for Patients who are in both workflows', () => {
    const mountedWrapper = getMountedWrapper([mockPatient1, mockPatient2, mockPatient3, mockPatient4]);
    expect(mountedWrapper.find('.modal-body').find('p').at(0).text()).toContain('Please select the desired case status to be assigned to all selected patients:')
    mountedWrapper.find('#case_status').find('option').forEach((option, index) => {
      expect(option.text()).toEqual(CASE_STATUS_OPTIONS[index]);
    });
    // The behavior here is the same as if they were in the isolation workflow
    expect(mountedWrapper.find('.modal-body').find('p').at(1).text()).toContain('The selected cases will be moved from the isolation workflow to the exposure workflow and placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate.')
    expect(mountedWrapper.find('ModalFooter').find('Button').at(0).text()).toEqual('Cancel')
    expect(mountedWrapper.find('ModalFooter').find('Button').at(1).text()).toEqual('Submit')
  });

  it('Properly does not display any follow-up options when the empty string is selected', () => {
    // have to `mount` the wrapper so the event object is properly created when simulating change below
    const mountedWrapper = getMountedWrapper([mockPatient1, mockPatient2, mockPatient3, mockPatient4]);
    const option = ''
    mountedWrapper.find('FormControl').first().simulate('change', { target: { id: 'case_status', type: 'change', value: option } })
    expect(mountedWrapper.state('case_status')).toEqual(option)
    // When '' is selected, there will be 4 children (other selections will have more nodes appear with additional choices)
    expect(mountedWrapper.find('.modal-body').children().length).toEqual(4)
    expect(mountedWrapper.find('.modal-body').children().at(0).text()).toContain('Please select the desired case status to be assigned to all selected patients:')
    // mountedWrapper.find('.modal-body').children().at(1) is a dropdown
    expect(mountedWrapper.find('.modal-body').children().at(2).text()).toContain('The selected cases will be moved from the isolation workflow to the exposure workflow and placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate.')
    expect(mountedWrapper.find('.modal-body').children().at(3).text()).toContain('Apply this change to the entire household that these monitorees are responsible for, if it applies.')
  });

  it('Properly sets the correct follow-up options for "Confirmed", and "Probable"', () => {
    // mockPatient5 is in the Exposure Workflow and is not closed
    const mountedWrapper = getMountedWrapper([mockPatient5]);
    ['Confirmed', 'Probable'].forEach(case_status_option => {
      mountedWrapper.find('FormControl').first().simulate('change', { target: { id: 'case_status', type: 'change', value: case_status_option } })
      expect(mountedWrapper.state('case_status')).toEqual(case_status_option)

      const CASE_STATUS_FOLLOW_UP_OPTIONS = ['', 'End Monitoring', 'Continue Monitoring in Isolation Workflow']
      mountedWrapper.find('FormControl').at(1).find('option').forEach((option, index) => {
        expect(option.text()).toEqual(CASE_STATUS_FOLLOW_UP_OPTIONS[index]);
      });

      // The follow_up options for `End Monitoring` and `Continue Monitoring in Isolation Workflow` are different, so test them separately
      // > `End Monitoring` Tests
      mountedWrapper.find('FormControl').at(1).simulate('change', { target: { id: 'follow_up', type: 'change', value: 'End Monitoring' } })
      expect(mountedWrapper.state('follow_up')).toEqual('End Monitoring')
      expect(mountedWrapper.find('FormControl').length).toEqual(4)
      expect(mountedWrapper.find('p').at(2).text()).toContain('The selected monitorees will be moved into the "Closed" line list, and will no longer be monitored.')
      const monitoringReasonOptions = [''].concat(mockMonitoringReasons)
      mountedWrapper.find('#monitoring_reason').find('option').forEach((option, index) => {
        expect(option.text()).toEqual(monitoringReasonOptions[index]);
        mountedWrapper.find('#monitoring_reason').simulate('change', { target: { id: 'monitoring_reason', value: option } })
        expect(mountedWrapper.state('monitoring_reason')).toEqual(option)
      });
      const mockReasoning = "I Shall Call Him Squishy And He Shall Be Mine And He Shall Be My Squishy.";
      mountedWrapper.find('#reasoning').simulate('change', { target: { id: 'reasoning', value: mockReasoning } })
      expect(mountedWrapper.state('reasoning')).toEqual(mockReasoning)
      expect(mountedWrapper.find('.notes-character-limit').first().text()).toContain(`${2000-mockReasoning.length} characters remaining`)

      // > `Continue Monitoring in Isolation Workflow` Tests
      mountedWrapper.find('FormControl').at(1).simulate('change', { target: { id: 'follow_up', type: 'change', value: 'Continue Monitoring in Isolation Workflow' } })
      expect(mountedWrapper.state('follow_up')).toEqual('Continue Monitoring in Isolation Workflow')
      expect(mountedWrapper.find('p').at(2).text()).toContain('The selected monitorees will be moved to the isolation workflow and placed in the requiring review, non-reporting, or reporting line list as appropriate.')
      mountedWrapper.find('FormCheckInput').simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: false } })
      expect(mountedWrapper.state('apply_to_household')).toBeFalsy()
      mountedWrapper.find('FormCheckInput').simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: true } })
      expect(mountedWrapper.state('apply_to_household')).toBeTruthy()
    })
  });

  it('Properly sets the correct follow-up options for all selected monitorees are already closed', () => {
    // mockPatient5 is in the Exposure Workflow and is not closed
    const mountedWrapper = getMountedWrapper([mockPatient2, mockPatient3]);
    ['Confirmed', 'Probable'].forEach(case_status_option => {
      mountedWrapper.find('FormControl').first().simulate('change', { target: { id: 'case_status', type: 'change', value: case_status_option } })
      expect(mountedWrapper.state('case_status')).toEqual(case_status_option)
      expect(mountedWrapper.state('allSelectedAreClosed')).toBeTruthy()

      // When all are closed, there is no follow-up dropdown, so this shoud be 3, instead of the usual 4
      expect(mountedWrapper.find('FormControl').length).toEqual(3)

      const monitoringReasonOptions = [''].concat(mockMonitoringReasons)
      mountedWrapper.find('#monitoring_reason').find('option').forEach((option, index) => {
        expect(option.text()).toEqual(monitoringReasonOptions[index]);
        mountedWrapper.find('#monitoring_reason').simulate('change', { target: { id: 'monitoring_reason', value: option } })
        expect(mountedWrapper.state('monitoring_reason')).toEqual(option)
      });
      const mockReasoning = "I Shall Call Him Squishy And He Shall Be Mine And He Shall Be My Squishy.";
      mountedWrapper.find('#reasoning').simulate('change', { target: { id: 'reasoning', value: mockReasoning } })
      expect(mountedWrapper.state('reasoning')).toEqual(mockReasoning)
      expect(mountedWrapper.find('.notes-character-limit').first().text()).toContain(`${2000-mockReasoning.length} characters remaining`)
    })
  });

  it('Properly sets the correct follow-up options for "Suspect", "Unknown, and "Not a Case"', () => {
    // have to `mount` the wrapper so the event object is properly created when simulating change below
    const mountedWrapper = getMountedWrapper([mockPatient1, mockPatient2, mockPatient3, mockPatient4]);
    // "Suspect", "Unknown" and "Not a Case" have identical behavior in the modal
    ['Suspect', 'Unknown', 'Not a Case'].forEach(case_status_option => {
      mountedWrapper.find('FormControl').first().simulate('change', { target: { id: 'case_status', type: 'change', value: case_status_option } })

      expect(mountedWrapper.find('p').at(1).text()).toContain('The selected cases will be moved from the isolation workflow to the exposure workflow and placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate.')
      // there are no dropdowns for "Suspect", "Unknown" and "Not a Case"
      expect(mountedWrapper.find('FormControl').at(1).exists()).toBeFalsy()

      mountedWrapper.find('FormCheckInput').simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: false } })
      expect(mountedWrapper.state('apply_to_household')).toBeFalsy()
      mountedWrapper.find('FormCheckInput').simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: true } })
      expect(mountedWrapper.state('apply_to_household')).toBeTruthy()
    })
  });

  it('Properly calls the close method', () => {
    const mountedWrapper = getMountedWrapper([mockPatient1, mockPatient2, mockPatient3, mockPatient4]);

    expect(mountedWrapper.find('Button').at(0).text()).toContain('Cancel');
    expect(onCloseMock).toHaveBeenCalledTimes(0);
    mountedWrapper.find('Button').at(0).simulate('click');
    expect(onCloseMock).toHaveBeenCalled();
  });

  it('Properly calls the submit method', () => {
    const mountedWrapper = getMountedWrapper([mockPatient1, mockPatient2, mockPatient3, mockPatient4]);
    const submitSpy = jest.spyOn(mountedWrapper.instance(), 'submit');
    mountedWrapper.instance().forceUpdate() // must forceUpdate to properly mount the spy

    expect(mountedWrapper.find('Button').at(1).text()).toContain('Submit');
    expect(submitSpy).toHaveBeenCalledTimes(0);
    mountedWrapper.find('Button').at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });

});
