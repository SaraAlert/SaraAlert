import React from 'react'
import { shallow } from 'enzyme';
import { Button, Modal, Form } from 'react-bootstrap';
import moment from 'moment';
import MonitoringStatus from '../../../components/subject/monitoring_actions/MonitoringStatus'
import InfoTooltip from '../../../components/util/InfoTooltip';
import DateInput from '../../../components/util/DateInput';
import { mockPatient1, mockPatient3 } from '../../mocks/mockPatients';
import { mockMonitoringReasons } from '../../mocks/mockMonitoringReasons'

const currentDate = moment(new Date()).format('YYYY-MM-DD');
const newDate = moment(new Date('9-9-2020')).format('YYYY-MM-DD');
const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const monitoringStatusValues = [ 'Actively Monitoring', 'Not Monitoring' ];

function getWrapper(patient, hasDependents, inHouseholdWithCeInExposure) {
  return shallow(<MonitoringStatus patient={patient} has_dependents={hasDependents} authenticity_token={authyToken}
    in_household_with_member_with_ce_in_exposure={inHouseholdWithCeInExposure} monitoring_reasons={mockMonitoringReasons}/>);
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
    expect(wrapper.find('#monitoring_reason').find('option').length).toEqual(mockMonitoringReasons.length + 1); // the +1 is for the extra blank
    [''].concat(mockMonitoringReasons).forEach(function(value, index) {
        expect(wrapper.find('#monitoring_reason').find('option').at(index).text()).toEqual(value);
    });
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
    expect(wrapper.find('.update-dependent-lde').exists()).toBeFalsy();

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
    expect(modalBody.find('#apply_to_household_no').prop('type')).toEqual('radio');
    expect(modalBody.find('#apply_to_household_no').prop('label')).toEqual('This monitoree only');
    expect(modalBody.find('#apply_to_household_yes').prop('type')).toEqual('radio');
    expect(modalBody.find('#apply_to_household_yes').prop('label')).toEqual('This monitoree and all household members (this will turn Continuous Exposure OFF for all household members)');
  });

  it('Clicking HoH radio buttons toggles this.state.apply_to_household', () => {
    const wrapper = getWrapper(mockPatient1, true);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });

    // initial radio button state
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeFalsy();

    // change to apply to all of household
    wrapper.find('#apply_to_household_yes').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    wrapper.update();
    expect(wrapper.state('apply_to_household')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeTruthy();

    // change back to just this monitoree
    wrapper.find('#apply_to_household_no').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    wrapper.update();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeFalsy();
  });

  it('Clicking the apply to household radio button shows/hides update LDE section', () => {
    const wrapper = getWrapper(mockPatient1, true, true);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });

    // initial radio button state
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('apply_to_household_cm_exp_only')).toBeFalsy();
    expect(wrapper.find('.update-dependent-lde').exists()).toBeTruthy();

    // change to apply to all of household
    wrapper.find('#apply_to_household_yes').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.state('apply_to_household')).toBeTruthy();
    expect(wrapper.state('apply_to_household_cm_exp_only')).toBeFalsy();
    expect(wrapper.find('.update-dependent-lde').exists()).toBeFalsy();

    // change back to just this monitoree
    wrapper.find('#apply_to_household_no').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('apply_to_household_cm_exp_only')).toBeFalsy();
    expect(wrapper.find('.update-dependent-lde').exists()).toBeTruthy();
  });

  it('Changing monitoring reason dropdown updates state', () => {
    const wrapper = getWrapper(mockPatient1, true);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });

    // initial modal state with monitoring reason empty
    expect(wrapper.state('monitoring_reason')).toEqual('');

    // test changing to each enabled monitoring option
    mockMonitoringReasons.shift();
    mockMonitoringReasons.forEach(function(value) {
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

  it('Properly renders radio buttons for updating dependents LDE', () => {
    const wrapper = getWrapper(mockPatient1, true, true);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });

    expect(wrapper.find('.update-dependent-lde').exists()).toBeTruthy();
    expect(wrapper.find('.update-dependent-lde').find('p').at(0).text()).toEqual(`Would you like to update the Last Date of Exposure for all household members who have Continuous Exposure turned ON and are being monitored in the Exposure Workflow?`);
    expect(wrapper.find('.update-dependent-lde').find(Form.Check).length).toEqual(2);
    expect(wrapper.find('#apply_to_household_cm_exp_only_no').prop('type')).toEqual('radio');
    expect(wrapper.find('#apply_to_household_cm_exp_only_no').prop('label')).toEqual('No, household members still have continuous exposure to another case');
    expect(wrapper.find('#apply_to_household_cm_exp_only_no').prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_cm_exp_only_yes').prop('type')).toEqual('radio');
    expect(wrapper.find('.update-dependent-lde').find('p').at(1).text()).toEqual('Yes, household members are no longer being exposed to a case');
    expect(wrapper.find('#apply_to_household_cm_exp_only_yes').prop('checked')).toBeFalsy();
    expect(wrapper.find(DateInput).exists()).toBeFalsy();
  });

  it('Clicking LDE radio buttons toggles this.state.apply_to_household_cm_exp_only', () => {
    const wrapper = getWrapper(mockPatient1, true, true);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });

    // initial radio button state with 'NO' selected
    expect(wrapper.state('apply_to_household_cm_exp_only')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_cm_exp_only_no').prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_cm_exp_only_yes').prop('checked')).toBeFalsy();

    // change to 'YES'
    wrapper.find('#apply_to_household_cm_exp_only_yes').simulate('change', { target: { name: 'apply_to_household_cm_exp_only', id: 'apply_to_household_cm_exp_only_yes' } });
    wrapper.update();
    expect(wrapper.state('apply_to_household_cm_exp_only')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_cm_exp_only_no').prop('checked')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_cm_exp_only_yes').prop('checked')).toBeTruthy();

    // change back to 'NO'
    wrapper.find('#apply_to_household_cm_exp_only_no').simulate('change', { target: { name: 'apply_to_household_cm_exp_only', id: 'apply_to_household_cm_exp_only_no' } });
    wrapper.update();
    expect(wrapper.state('apply_to_household_cm_exp_only')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_cm_exp_only_no').prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_cm_exp_only_yes').prop('checked')).toBeFalsy();
  });

  it('Changing LDE with datepicker updates this.state.apply_to_household_cm_exp_only_date', () => {
    const wrapper = getWrapper(mockPatient1, true, true);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });
    wrapper.find('#apply_to_household_cm_exp_only_yes').simulate('change', { target: { name: 'apply_to_household_cm_exp_only', id: 'apply_to_household_cm_exp_only_yes' } });
    wrapper.update();

    expect(wrapper.find(DateInput).exists()).toBeTruthy();
    expect(wrapper.state('apply_to_household_cm_exp_only_date')).toEqual(currentDate);
    expect(wrapper.find(DateInput).prop('date')).toEqual(currentDate);

    wrapper.find('#apply_to_household_cm_exp_only_date').simulate('change', newDate);
    expect(wrapper.state('apply_to_household_cm_exp_only_date')).toEqual(newDate);
    expect(wrapper.find(DateInput).prop('date')).toEqual(newDate);
  });

  it('Clicking the cancel button closes modal and resets state', () => {
    const wrapper = getWrapper(mockPatient1, true, true);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });
    wrapper.find('#apply_to_household_yes').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    wrapper.find('#monitoring_reason').simulate('change', { target: { id: 'monitoring_reason', value: 'Other' } });
    wrapper.find('#reasoning').simulate('change', { target: { id: 'reasoning', value: 'insert reasoning text here' } });

    // check initial state
    expect(wrapper.state('showMonitoringStatusModal')).toBeTruthy();
    expect(wrapper.state('apply_to_household')).toBeTruthy();
    expect(wrapper.state('reasoning')).toEqual('insert reasoning text here');
    expect(wrapper.state('monitoring')).toEqual(false);
    expect(wrapper.state('monitoring_status')).toEqual('Not Monitoring');
    expect(wrapper.state('monitoring_reason')).toEqual('Other');

    // closes modal
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();

    // resets state
    expect(wrapper.state('showMonitoringStatusModal')).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
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
