import React from 'react';
import { shallow, mount, ReactWrapper } from 'enzyme';
import UpdateCaseStatus from '../../../components/public_health/actions/UpdateCaseStatus';
import { mockMonitoringReasons } from '../../mocks/mockMonitoringReasons';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4 } from '../../mocks/mockPatients';

const onCloseMock = jest.fn();
const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

function getShallowWrapper() {
  return shallow(<UpdateCaseStatus
    authenticity_token={authyToken}
    patients={[mockPatient1, mockPatient2, mockPatient3, mockPatient4]}
    monitoring_reasons={mockMonitoringReasons}
    close={onCloseMock}
    />);
}

function getMountedWrapper() {
  return mount(<UpdateCaseStatus
    authenticity_token={authyToken}
    patients={[mockPatient1, mockPatient2, mockPatient3, mockPatient4]}
    monitoring_reasons={mockMonitoringReasons}
    close={onCloseMock}
    />);
}

const CASE_STATUS_OPTIONS = ['', 'Confirmed', 'Probable', 'Suspect', 'Unknown', 'Not a Case']

afterEach(() => {
  jest.clearAllMocks();
});

describe('UpdateCaseStatus', () => {
  it('Properly renders all main components', () => {
    const shallowWrapper = getShallowWrapper();
    shallowWrapper.find('#case_status').find('option').forEach((option, index) => {
      expect(option.text()).toEqual(CASE_STATUS_OPTIONS[index]);
    });
    expect(shallowWrapper.find('ModalFooter').find('Button').at(0).text()).toEqual('Cancel')
    expect(shallowWrapper.find('ModalFooter').find('Button').at(1).text()).toEqual('Submit')
  });

  it('Properly sets case status via the FormControl dropdown', () => {
    // have to `mount` the wrapper so the event object is properly created when simulating change below
    const mountedWrapper = getMountedWrapper();
    CASE_STATUS_OPTIONS.forEach((option, index) => {
      mountedWrapper.find('FormControl').first().simulate('change', { target: { id: 'case_status', type: 'change', value: option } })
      expect(mountedWrapper.state('case_status')).toEqual(option)
    })
  });

  it('Properly does not display any follow-up options when the empty string is selected', () => {
    // have to `mount` the wrapper so the event object is properly created when simulating change below
    const mountedWrapper = getMountedWrapper();
    const option = ''
    mountedWrapper.find('FormControl').first().simulate('change', { target: { id: 'case_status', type: 'change', value: option } })
    expect(mountedWrapper.find('.modal-body').childAt(0).exists()).toBeTruthy()
    expect(mountedWrapper.find('.modal-body').childAt(1).exists()).toBeTruthy()
    // When options other than the empty string ('') are chosen, this element will have more than 2 children
    expect(mountedWrapper.find('.modal-body').childAt(2).exists()).toBeFalsy()
  });

  it('Properly sets the correct follow-up options for "Confirmed", and "Probable"', () => {
    // have to `mount` the wrapper so the event object is properly created when simulating change below
    const mountedWrapper = getMountedWrapper();
    // "Confirmed" and "Probable" have identical behavior in the modal
    ['Confirmed', 'Probable'].forEach(case_status_option => {
      mountedWrapper.find('FormControl').first().simulate('change', { target: { id: 'case_status', type: 'change', value: case_status_option } })

      // We expect to find a second FormControl now, containing more options
      expect(mountedWrapper.find('p').at(1).text()).toContain('Please select what you would like to do:')
      expect(mountedWrapper.find('FormControl').at(1).exists()).toBeTruthy()
      const CASE_STATUS_FOLLOW_UP_OPTIONS = ['', 'End Monitoring', 'Continue Monitoring in Isolation Workflow']
      mountedWrapper.find('FormControl').at(1).find('option').forEach((option, index) => {
        expect(option.text()).toEqual(CASE_STATUS_FOLLOW_UP_OPTIONS[index]);
      });
      expect(mountedWrapper.find('FormGroup').at(0).exists()).toBeTruthy()

      mountedWrapper.find('FormControl').at(1).simulate('change', { target: { id: 'follow_up', type: 'change', value: 'End Monitoring' } })
      expect(mountedWrapper.state('follow_up')).toEqual('End Monitoring')
      expect(mountedWrapper.state('isolation')).toBeUndefined()
      expect(mountedWrapper.state('monitoring')).toBeFalsy()
      expect(mountedWrapper.find('p').at(2).text()).toContain('The selected monitorees will be moved into the "Closed" line list, and will no longer be monitored.')

      mountedWrapper.find('FormControl').at(1).simulate('change', { target: { id: 'follow_up', type: 'change', value: 'Continue Monitoring in Isolation Workflow' } })
      expect(mountedWrapper.state('follow_up')).toEqual('Continue Monitoring in Isolation Workflow')
      expect(mountedWrapper.state('isolation')).toBeTruthy()
      expect(mountedWrapper.state('monitoring')).toBeTruthy()
      expect(mountedWrapper.find('p').at(2).text()).toContain('The selected monitorees will be moved to the isolation workflow and placed in the requiring review, non-reporting, or reporting line list as appropriate.')

      mountedWrapper.find('FormCheckInput').simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: false } })
      expect(mountedWrapper.state('apply_to_household')).toBeFalsy()
      mountedWrapper.find('FormCheckInput').simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: true } })
      expect(mountedWrapper.state('apply_to_household')).toBeTruthy()
    })
  });

  it('Properly sets the correct follow-up options for "Suspect", "Unknown, and "Not a Case"', () => {
    // have to `mount` the wrapper so the event object is properly created when simulating change below
    const mountedWrapper = getMountedWrapper();
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
    const shallowWrapper = getShallowWrapper();

    expect(shallowWrapper.find('Button').at(0).text()).toContain('Cancel');

    expect(onCloseMock).toHaveBeenCalledTimes(0);
    shallowWrapper.find('Button').at(0).simulate('click');
    expect(onCloseMock).toHaveBeenCalled();
  });

  it('Properly calls the submit method', () => {
    const shallowWrapper = getShallowWrapper();
    const submitSpy = jest.spyOn(shallowWrapper.instance(), 'submit');
    shallowWrapper.instance().forceUpdate() // must forceUpdate to properly mount the spy

    expect(shallowWrapper.find('Button').at(1).text()).toContain('Submit');

    expect(submitSpy).toHaveBeenCalledTimes(0);
    shallowWrapper.find('Button').at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });

});
