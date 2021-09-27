import React from 'react';
import { shallow, mount } from 'enzyme';
import { Button, Modal, Form } from 'react-bootstrap';
import moment from 'moment';
import MonitoringStatus from '../../../components/patient/monitoring_actions/MonitoringStatus';
import ApplyToHousehold from '../../../components/patient/household/actions/ApplyToHousehold';
import CustomTable from '../../../components/layout/CustomTable';
import InfoTooltip from '../../../components/util/InfoTooltip';
import DateInput from '../../../components/util/DateInput';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4 } from '../../mocks/mockPatients';
import { mockMonitoringReasons } from '../../mocks/mockMonitoringReasons';

const currentDate = moment(new Date()).format('YYYY-MM-DD');
const newDate = moment(new Date('9-9-2020')).format('YYYY-MM-DD');
const mockToken = 'testMockTokenString12345';
const monitoringStatusValues = ['Actively Monitoring', 'Not Monitoring'];

function getShallowWrapper(patient, householdMembers) {
  return shallow(<MonitoringStatus patient={patient} household_members={householdMembers || []} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} monitoring_reasons={mockMonitoringReasons} workflow={'global'} />);
}

function getMountedWrapper() {
  return mount(<MonitoringStatus patient={mockPatient1} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} household_members={[mockPatient2, mockPatient3, mockPatient4]} authenticity_token={mockToken} monitoring_reasons={mockMonitoringReasons} workflow={'global'} />);
}

describe('MonitoringStatus', () => {
  it('Properly renders all main components', () => {
    const wrapper = getShallowWrapper(mockPatient1);
    expect(wrapper.find(Form.Label).text()).toContain('MONITORING STATUS');
    expect(wrapper.find(InfoTooltip).exists()).toBe(true);
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('monitoringStatus');
    expect(wrapper.find('#monitoring_status').exists()).toBe(true);
    expect(wrapper.find('option').length).toEqual(2);
    monitoringStatusValues.forEach((value, index) => {
      expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#monitoring_status').prop('value')).toEqual('Actively Monitoring');
  });

  it('Changing Monitoring Status opens modal', () => {
    const wrapper = getShallowWrapper(mockPatient1);
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });
    expect(wrapper.find(Modal).exists()).toBe(true);
  });

  it('Properly renders modal', () => {
    const wrapper = getShallowWrapper(mockPatient1);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });
    expect(wrapper.find(Modal.Title).exists()).toBe(true);
    expect(wrapper.find(Modal.Title).text()).toEqual('Monitoring Status');
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');
  });

  it('Correctly renders modal body and sets state when changing to not monitoring', () => {
    const wrapper = getShallowWrapper(mockPatient1);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });

    // renders modal body
    expect(wrapper.find(Modal.Body).find('p').text()).toContain(`Are you sure you want to change monitoring status to "Not Monitoring"?`);
    expect(wrapper.find(Modal.Body).find('p').find('b').text()).toEqual(' This will move the selected record(s) to the Closed line list and turn Continuous Exposure OFF.');
    expect(wrapper.find('#monitoring_reason').exists()).toBe(true);
    expect(wrapper.find('#monitoring_reason').find('option').length).toEqual(mockMonitoringReasons.length + 1); // the +1 is for the extra blank
    [''].concat(mockMonitoringReasons).forEach((value, index) => {
      expect(wrapper.find('#monitoring_reason').find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#reasoning').exists()).toBe(true);

    // sets state
    expect(wrapper.state('showMonitoringStatusModal')).toBe(true);
    expect(wrapper.state('monitoring')).toBe(false);
    expect(wrapper.state('monitoring_status')).toEqual('Not Monitoring');
  });

  it('Correctly renders modal body and sets state when changing to monitoring', () => {
    const wrapper = getShallowWrapper(mockPatient3);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Actively Monitoring' } });

    // renders modal
    expect(wrapper.find(Modal.Body).find('p').text()).toContain(`Are you sure you want to change monitoring status to "Actively Monitoring"?`);
    expect(wrapper.find(Modal.Body).find('p').find('b').text()).toEqual(' This will move the selected record(s) from the Closed line list to the appropriate Active Monitoring line list.');
    expect(wrapper.find('#monitoring_reason').exists()).toBe(false);
    expect(wrapper.find('#reasoning').exists()).toBe(true);
    expect(wrapper.find('.update-dependent-lde').exists()).toBe(false);

    // sets state
    expect(wrapper.state('showMonitoringStatusModal')).toBe(true);
    expect(wrapper.state('monitoring')).toBe(true);
    expect(wrapper.state('monitoring_status')).toEqual('Actively Monitoring');
  });

  it('Toggling HoH radio buttons hides/shows household members table and updates state', () => {
    const wrapper = getMountedWrapper();
    wrapper
      .find('#monitoring_status')
      .hostNodes()
      .simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });

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

  it('Clicking the apply to household radio button shows/hides update LDE section', () => {
    const wrapper = getMountedWrapper();
    wrapper
      .find('#monitoring_status')
      .hostNodes()
      .simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });

    // initial radio button state
    expect(wrapper.state('apply_to_household')).toBe(false);
    expect(wrapper.state('apply_to_household_cm_exp_only')).toBe(false);
    expect(wrapper.find('.update-dependent-lde').exists()).toBe(true);

    // change to apply to all of household
    wrapper
      .find('#apply_to_household_yes')
      .hostNodes()
      .simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.state('apply_to_household')).toBe(true);
    expect(wrapper.state('apply_to_household_cm_exp_only')).toBe(false);
    expect(wrapper.find('.update-dependent-lde').exists()).toBe(false);

    // change back to just this monitoree
    wrapper
      .find('#apply_to_household_no')
      .hostNodes()
      .simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    expect(wrapper.state('apply_to_household')).toBe(false);
    expect(wrapper.state('apply_to_household_cm_exp_only')).toBe(false);
    expect(wrapper.find('.update-dependent-lde').exists()).toBe(true);
  });

  it('Changing monitoring reason dropdown updates state', () => {
    const wrapper = getShallowWrapper(mockPatient1);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });

    // initial modal state with monitoring reason empty
    expect(wrapper.state('monitoring_reason')).toEqual('');

    // test changing to each enabled monitoring option
    mockMonitoringReasons.shift();
    mockMonitoringReasons.forEach(value => {
      wrapper.find('#monitoring_reason').simulate('change', { target: { id: 'monitoring_reason', value: value } });
      expect(wrapper.state('monitoring_reason')).toEqual(value);
      expect(wrapper.state('monitoring')).toBe(false);
      expect(wrapper.state('monitoring_status')).toEqual('Not Monitoring');
    });
  });

  it('Adding reasoning updates state', () => {
    const wrapper = getShallowWrapper(mockPatient3);
    const handleChangeSpy = jest.spyOn(wrapper.instance(), 'handleChange');
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Actively Monitoring' } });
    expect(wrapper.find('#reasoning').exists()).toBe(true);
    wrapper.find('#reasoning').simulate('change', { target: { id: 'reasoning', value: 'insert reasoning text here' } });
    expect(handleChangeSpy).toHaveBeenCalled();
    expect(wrapper.state('reasoning')).toEqual('insert reasoning text here');
  });

  it('Properly renders radio buttons for updating dependents LDE', () => {
    const wrapper = getMountedWrapper(mockPatient1);
    wrapper
      .find('#monitoring_status')
      .hostNodes()
      .simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });

    expect(wrapper.find('.update-dependent-lde').exists()).toBe(true);
    expect(wrapper.find('.update-dependent-lde').find('p').at(0).text()).toEqual(`Would you like to update the Last Date of Exposure for all household members who have Continuous Exposure turned ON and are being monitored in the Exposure Workflow?`);
    expect(wrapper.find('.update-dependent-lde').find(Form.Check).length).toEqual(2);
    expect(wrapper.find('#apply_to_household_cm_exp_only_no').hostNodes().prop('type')).toEqual('radio');
    expect(wrapper.find('.update-dependent-lde').find('label').at(0).text()).toEqual('No, household members still have continuous exposure to another case');
    expect(wrapper.find('#apply_to_household_cm_exp_only_no').hostNodes().prop('checked')).toBe(true);
    expect(wrapper.find('#apply_to_household_cm_exp_only_yes').hostNodes().prop('type')).toEqual('radio');
    expect(wrapper.find('.update-dependent-lde').find('label').at(1).text()).toEqual('Yes, household members are no longer being exposed to a case');
    expect(wrapper.find('#apply_to_household_cm_exp_only_yes').hostNodes().prop('checked')).toBe(false);
    expect(wrapper.find(DateInput).exists()).toBe(false);
  });

  it('Clicking LDE radio buttons toggles this.state.apply_to_household_cm_exp_only', () => {
    const wrapper = getMountedWrapper(mockPatient1);
    wrapper
      .find('#monitoring_status')
      .hostNodes()
      .simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });

    // initial radio button state with 'NO' selected
    expect(wrapper.state('apply_to_household_cm_exp_only')).toBe(false);
    expect(wrapper.find('#apply_to_household_cm_exp_only_no').hostNodes().prop('checked')).toBe(true);
    expect(wrapper.find('#apply_to_household_cm_exp_only_yes').hostNodes().prop('checked')).toBe(false);

    // change to 'YES'
    wrapper
      .find('#apply_to_household_cm_exp_only_yes')
      .hostNodes()
      .simulate('change', { target: { name: 'apply_to_household_cm_exp_only', id: 'apply_to_household_cm_exp_only_yes' } });
    wrapper.update();
    expect(wrapper.state('apply_to_household_cm_exp_only')).toBe(true);
    expect(wrapper.find('#apply_to_household_cm_exp_only_no').hostNodes().prop('checked')).toBe(false);
    expect(wrapper.find('#apply_to_household_cm_exp_only_yes').hostNodes().prop('checked')).toBe(true);

    // change back to 'NO'
    wrapper
      .find('#apply_to_household_cm_exp_only_no')
      .hostNodes()
      .simulate('change', { target: { name: 'apply_to_household_cm_exp_only', id: 'apply_to_household_cm_exp_only_no' } });
    wrapper.update();
    expect(wrapper.state('apply_to_household_cm_exp_only')).toBe(false);
    expect(wrapper.find('#apply_to_household_cm_exp_only_no').hostNodes().prop('checked')).toBe(true);
    expect(wrapper.find('#apply_to_household_cm_exp_only_yes').hostNodes().prop('checked')).toBe(false);
  });

  it('Changing LDE with datepicker updates this.state.apply_to_household_cm_exp_only_date', () => {
    const wrapper = getShallowWrapper(mockPatient1, [mockPatient2, mockPatient3, mockPatient4]);
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });
    wrapper.find('#apply_to_household_cm_exp_only_yes').simulate('change', { target: { name: 'apply_to_household_cm_exp_only', id: 'apply_to_household_cm_exp_only_yes' } });
    wrapper.update();

    expect(wrapper.find(DateInput).exists()).toBe(true);
    expect(wrapper.state('apply_to_household_cm_exp_only_date')).toEqual(currentDate);
    expect(wrapper.find(DateInput).prop('date')).toEqual(currentDate);

    wrapper.find('#apply_to_household_cm_exp_only_date').simulate('change', newDate);
    expect(wrapper.state('apply_to_household_cm_exp_only_date')).toEqual(newDate);
    expect(wrapper.find(DateInput).prop('date')).toEqual(newDate);
  });

  it('Clicking the cancel button closes modal and resets state', () => {
    const wrapper = getMountedWrapper();
    wrapper
      .find('#monitoring_status')
      .hostNodes()
      .simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });
    wrapper
      .find('#apply_to_household_yes')
      .hostNodes()
      .simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    wrapper
      .find('tbody')
      .find('tr')
      .forEach(row => {
        row.find('input').simulate('change', { target: { checked: true } });
      });
    wrapper
      .find('#monitoring_reason')
      .hostNodes()
      .simulate('change', { target: { id: 'monitoring_reason', value: 'Other' } });
    wrapper
      .find('#reasoning')
      .hostNodes()
      .simulate('change', { target: { id: 'reasoning', value: 'insert reasoning text here' } });

    // check initial state
    expect(wrapper.state('showMonitoringStatusModal')).toBe(true);
    expect(wrapper.state('apply_to_household')).toBe(true);
    expect(wrapper.state('apply_to_household_ids')).toEqual([18, 56, 69]);
    expect(wrapper.state('reasoning')).toEqual('insert reasoning text here');
    expect(wrapper.state('monitoring')).toBe(false);
    expect(wrapper.state('monitoring_status')).toEqual('Not Monitoring');
    expect(wrapper.state('monitoring_reason')).toEqual('Other');

    // closes modal
    expect(wrapper.find(Modal).exists()).toBe(true);
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(false);

    // resets state
    expect(wrapper.state('showMonitoringStatusModal')).toBe(false);
    expect(wrapper.state('apply_to_household')).toBe(false);
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('reasoning')).toEqual('');
    expect(wrapper.state('monitoring')).toEqual(mockPatient1.monitoring);
    expect(wrapper.state('monitoring_status')).toEqual('Actively Monitoring');
    expect(wrapper.state('monitoring_reason')).toEqual('');
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getShallowWrapper(mockPatient1);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.find('#monitoring_status').simulate('change', { target: { id: 'monitoring_status', value: 'Not Monitoring' } });
    expect(submitSpy).not.toHaveBeenCalled();
    wrapper.find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
