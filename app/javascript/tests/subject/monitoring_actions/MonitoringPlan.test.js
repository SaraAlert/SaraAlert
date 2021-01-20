import React from 'react'
import { shallow } from 'enzyme';
import { Button, Modal, Form } from 'react-bootstrap';
import MonitoringPlan from '../../../components/subject/monitoring_actions/MonitoringPlan'
import InfoTooltip from '../../../components/util/InfoTooltip';
import { mockPatient1 } from '../../mocks/mockPatients';

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const monitoringPlanOptions = [ '', 'None', 'Daily active monitoring', 'Self-monitoring with public health supervision', 'Self-monitoring with delegated supervision', 'Self-observation' ];

function getWrapper(patient, hasDependents) {
  return shallow(<MonitoringPlan patient={patient} has_dependents={hasDependents} authenticity_token={authyToken} />);
}

describe('MonitoringPlan', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper(mockPatient1, false);
    expect(wrapper.find(Form.Label).text().includes('MONITORING PLAN')).toBeTruthy();
    expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('monitoringPlan');
    expect(wrapper.find('#monitoring_plan').exists()).toBeTruthy();
    expect(wrapper.find('option').length).toEqual(6);
    monitoringPlanOptions.forEach(function(value, index) {
        expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#monitoring_plan').prop('value')).toEqual(mockPatient1.monitoring_plan);
  });

  it('Changing Monitoring Plan opens modal', () => {
    const wrapper = getWrapper(mockPatient1, false);
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders modal and sets state correctly', () => {
    const wrapper = getWrapper(mockPatient1, false);
    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });
    
    // renders properly
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Monitoring Plan');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').text()).toEqual(`Are you sure you want to change monitoring plan to "None"?`);
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');

    // sets state correctly
    expect(wrapper.state('showMonitoringPlanModal')).toBeTruthy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('monitoring_plan')).toEqual('None');
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Properly renders radio buttons for HoH', () => {
    const wrapper = getWrapper(mockPatient1, true);
    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });
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
    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });

    // initial radio button state
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeFalsy();

    // change to apply to all of household
    wrapper.find('#apply_to_household_yes').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    wrapper.update()
    expect(wrapper.state('apply_to_household')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeTruthy();

    // change back to just this monitoree
    wrapper.find('#apply_to_household_no').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    wrapper.update()
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeFalsy();
  });

  it('Adding reasoning updates state', () => {
    const wrapper = getWrapper(mockPatient1, false);
    const handleChangeSpy = jest.spyOn(wrapper.instance(), 'handleReasoningChange');
    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });

    expect(wrapper.find('#reasoning').exists()).toBeTruthy();
    wrapper.find('#reasoning').simulate('change', { target: { id: 'reasoning', value: 'insert reasoning text here' } });
    expect(handleChangeSpy).toHaveBeenCalled();
    expect(wrapper.state('reasoning')).toEqual('insert reasoning text here');
  });

  it('Clicking the cancel button closes modal and resets state', () => {
    const wrapper = getWrapper(mockPatient1, false);
    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });

    // closes modal
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();

    // resets state
    expect(wrapper.state('showMonitoringPlanModal')).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('monitoring_plan')).toEqual(mockPatient1.monitoring_plan);
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getWrapper(mockPatient1, false);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');

    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
