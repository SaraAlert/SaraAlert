import React from 'react';
import { shallow, mount } from 'enzyme';
import { Button, Modal, Form } from 'react-bootstrap';
import MonitoringPlan from '../../../components/patient/monitoring_actions/MonitoringPlan';
import ApplyToHousehold from '../../../components/patient/household/actions/ApplyToHousehold';
import CustomTable from '../../../components/layout/CustomTable';
import InfoTooltip from '../../../components/util/InfoTooltip';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4 } from '../../mocks/mockPatients';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';

const mockToken = 'testMockTokenString12345';
const monitoringPlanOptions = ['', 'None', 'Daily active monitoring', 'Self-monitoring with public health supervision', 'Self-monitoring with delegated supervision', 'Self-observation'];

function getWrapper() {
  return shallow(<MonitoringPlan patient={mockPatient1} household_members={[]} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} workflow={'global'} />);
}

describe('MonitoringPlan', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Form.Label).text()).toContain('MONITORING PLAN');
    expect(wrapper.find(InfoTooltip).exists()).toBe(true);
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('monitoringPlan');
    expect(wrapper.find('#monitoring_plan').exists()).toBe(true);
    expect(wrapper.find('option').length).toEqual(6);
    monitoringPlanOptions.forEach((value, index) => {
      expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#monitoring_plan').prop('value')).toEqual(mockPatient1.monitoring_plan);
  });

  it('Changing Monitoring Plan opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });
    expect(wrapper.find(Modal).exists()).toBe(true);
  });

  it('Properly renders modal and sets state correctly', () => {
    const wrapper = getWrapper();
    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });

    // renders properly
    expect(wrapper.find(Modal.Title).exists()).toBe(true);
    expect(wrapper.find(Modal.Title).text()).toEqual('Monitoring Plan');
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('p').text()).toEqual(`Are you sure you want to change monitoring plan to "None"?`);
    expect(wrapper.find(Modal.Body).find(ApplyToHousehold).exists()).toBe(false);
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');

    // sets state correctly
    expect(wrapper.state('showMonitoringPlanModal')).toBe(true);
    expect(wrapper.state('apply_to_household')).toBe(false);
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('monitoring_plan')).toEqual('None');
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Toggling HoH radio buttons hides/shows household members table and updates state', () => {
    const wrapper = mount(<MonitoringPlan patient={mockPatient1} household_members={[mockPatient2, mockPatient3, mockPatient4]} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} workflow={'global'} />);
    wrapper
      .find('#monitoring_plan')
      .hostNodes()
      .simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });

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

  it('Adding reasoning updates state', () => {
    const wrapper = getWrapper();
    const handleChangeSpy = jest.spyOn(wrapper.instance(), 'handleReasoningChange');
    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });
    expect(wrapper.find('#reasoning').exists()).toBe(true);
    wrapper.find('#reasoning').simulate('change', { target: { id: 'reasoning', value: 'insert reasoning text here' } });
    expect(handleChangeSpy).toHaveBeenCalled();
    expect(wrapper.state('reasoning')).toEqual('insert reasoning text here');
  });

  it('Clicking the cancel button closes modal and resets state', () => {
    const wrapper = getWrapper();
    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });

    // closes modal
    expect(wrapper.find(Modal).exists()).toBe(true);
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(false);

    // resets state
    expect(wrapper.state('showMonitoringPlanModal')).toBe(false);
    expect(wrapper.state('apply_to_household')).toBe(false);
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('monitoring_plan')).toEqual(mockPatient1.monitoring_plan);
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getWrapper();
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });
    expect(submitSpy).not.toHaveBeenCalled();
    wrapper.find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
