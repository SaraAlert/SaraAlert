import React from 'react'
import { shallow } from 'enzyme';
import { Button, Modal, Form } from 'react-bootstrap';
import MonitoringStatus from '../../components/subject/MonitoringStatus'
import InfoTooltip from '../../components/util/InfoTooltip';
import { mockPatient1, mockPatient3 } from '../mocks/mockPatients';

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const monitoringStatusValues = [ 'Actively Monitoring', 'Not Monitoring' ];
const monitoringReasons = [ '--', 'Completed Monitoring', 'Meets Case Definition', 'Lost to follow-up during monitoring period', 'Lost to follow-up (contact never established)', 'Transferred to another jurisdiction', 'Person Under Investigation (PUI)', 'Case confirmed', 'Meets criteria to discontinue isolation', 'Deceased', 'Duplicate', 'Other' ];

function getWrapper(patient, hasGroupMembers, inAGroup) {
  return shallow(<MonitoringStatus patient={patient} has_group_members={hasGroupMembers} in_a_group={inAGroup}
    isolation={patient.isolation} authenticity_token={authyToken} />);
}

describe('MonitoringStatus', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper(mockPatient1, false);
    expect(wrapper.find(Form.Label).text().includes('MONITORING STATUS')).toBeTruthy();
    expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('monitoringStatus');
    expect(wrapper.find('#monitoring_status').exists()).toBeTruthy();
    expect(wrapper.find('option').length).toEqual(2);
    monitoringStatusValues.forEach(function(value, index) {
        expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#monitoring_status').prop('value')).toEqual('Actively Monitoring');
  });

  it('Changing Monitoring Status opens modal', () => {
    const wrapper = getWrapper(mockPatient1, false);
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders modal', () => {
    const wrapper = getWrapper(mockPatient1, false);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Monitoring Status');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');
  });

  it('Correctly renders modal body and sets state when changing to not monitoring', () => {
    const wrapper = getWrapper(mockPatient1, false);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });

    // renders modal body
    expect(wrapper.find(Modal.Body).find('p').text().includes(`Are you sure you want to change monitoring status to "Not Monitoring"?`)).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').find('b').text()).toEqual(' This will move the selected record(s) to the Closed line list and turn Continuous Exposure OFF.');
    expect(wrapper.find('#monitoring_reason').exists()).toBeTruthy();
    expect(wrapper.find('#monitoring_reason').find('option').length).toEqual(12);
    monitoringReasons.forEach(function(value, index) {
      expect(wrapper.find('#monitoring_reason').find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#monitoring_reason').find('option').at(0).prop('disabled')).toBeTruthy();
    expect(wrapper.find('#reasoning').exists()).toBeTruthy();

    // sets state
    expect(wrapper.state('showMonitoringStatusModal')).toBeTruthy();
    expect(wrapper.state('monitoring')).toBeFalsy();
    expect(wrapper.state('monitoring_status')).toEqual('Not Monitoring');
  });

  it('Correctly renders modal body and sets state when changing to monitoring', () => {
    const wrapper = getWrapper(mockPatient3, false);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Actively Monitoring' } });

    // renders modal
    expect(wrapper.find(Modal.Body).find('p').text().includes(`Are you sure you want to change monitoring status to "Actively Monitoring"?`)).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').find('b').text()).toEqual(' This will move the selected record(s) from the Closed line list to the appropriate Active Monitoring line list.');
    expect(wrapper.find('#monitoring_reason').exists()).toBeFalsy();
    expect(wrapper.find('#reasoning').exists()).toBeTruthy();

    // sets state
    expect(wrapper.state('showMonitoringStatusModal')).toBeTruthy();
    expect(wrapper.state('monitoring')).toBeTruthy();
    expect(wrapper.state('monitoring_status')).toEqual('Actively Monitoring');
  });

  it('Properly renders radio buttons for HoH', () => {
    const wrapper = getWrapper(mockPatient1, true);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });
    const modalBody = wrapper.find(Modal.Body);

    expect(modalBody.find(Form.Group).exists()).toBeTruthy();
    expect(modalBody.find(Form.Check).length).toEqual(2);
    expect(modalBody.find('#apply_to_group_no').prop('type')).toEqual('radio');
    expect(modalBody.find('#apply_to_group_no').prop('label')).toEqual('This monitoree only');
    expect(modalBody.find('#apply_to_group_yes').prop('type')).toEqual('radio');
    expect(modalBody.find('#apply_to_group_yes').prop('label')).toEqual('This monitoree and all household members');
  });

  it('Clicking HoH radio buttons toggles this.state.apply_to_group', () => {
    const wrapper = getWrapper(mockPatient1, true);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });

    // initial radio button state
    expect(wrapper.state('apply_to_group')).toBeFalsy();
    expect(wrapper.find('#apply_to_group_no').prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_group_yes').prop('checked')).toBeFalsy();

    // change to apply to all of household
    wrapper.find('#apply_to_group_yes').simulate('change', { target: { name: 'apply_to_group', id: 'apply_to_group_yes' } });
    wrapper.update();
    expect(wrapper.state('apply_to_group')).toBeTruthy();
    expect(wrapper.find('#apply_to_group_no').prop('checked')).toBeFalsy();
    expect(wrapper.find('#apply_to_group_yes').prop('checked')).toBeTruthy();

    // change back to just this monitoree
    wrapper.find('#apply_to_group_yes').simulate('change', { target: { name: 'apply_to_group', id: 'apply_to_group_no' } });
    wrapper.update();
    expect(wrapper.state('apply_to_group')).toBeFalsy();
    expect(wrapper.find('#apply_to_group_no').prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_group_yes').prop('checked')).toBeFalsy();
  });

  it('Changing monitoring reason dropdown updates state', () => {
    const wrapper = getWrapper(mockPatient1, true);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });

    // initial modal state with monitoring reason empty
    expect(wrapper.state('monitoring_reason')).toEqual('');

    // test changing to each enabled monitoring option
    monitoringReasons.shift();
    monitoringReasons.forEach(function(value) {
      wrapper.find('#monitoring_reason').simulate('change', { target: { id: 'monitoring_reason', value: value } });
      expect(wrapper.state('monitoring_reason')).toEqual(value);
      expect(wrapper.state('monitoring')).toEqual(false);
      expect(wrapper.state('monitoring_status')).toEqual('Not Monitoring');
    });
  });

  it('Adding reasoning updates state', () => {
    const wrapper = getWrapper(mockPatient3, false);
    const handleChangeSpy = jest.spyOn(wrapper.instance(), 'handleChange');
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Actively Monitoring' } });

    expect(wrapper.find('#reasoning').exists()).toBeTruthy();
    wrapper.find('#reasoning').simulate('change', { target: { id: 'reasoning', value: 'insert reasoning text here' } });
    expect(handleChangeSpy).toHaveBeenCalled();
    expect(wrapper.state('reasoning')).toEqual('insert reasoning text here');
  });

  // ADD: in a group LDE stuff

  it('Clicking the cancel button closes modal and resets state', () => {
    const wrapper = getWrapper(mockPatient1, false);

    // closes modal
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();

    // resets state
    expect(wrapper.state('showMonitoringStatusModal')).toBeFalsy();
    expect(wrapper.state('apply_to_group')).toBeFalsy();
    expect(wrapper.state('reasoning')).toEqual('');
    expect(wrapper.state('monitoring')).toEqual(mockPatient1.monitoring);
    expect(wrapper.state('monitoring_status')).toEqual('Actively Monitoring');
    expect(wrapper.state('monitoring_reason')).toEqual('');
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getWrapper(mockPatient1, false);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');

    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});