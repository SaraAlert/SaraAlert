import React from 'react'
import { shallow } from 'enzyme';
import { Button, Modal, Form } from 'react-bootstrap';
import GenericAction from '../../components/subject/GenericAction'
import InfoTooltip from '../../components/util/InfoTooltip';
import { mockPatient1, mockPatient2, mockPatient3 } from '../mocks/mockPatients';

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const exposureRiskAssessmentOptions = [ '', 'High', 'Medium', 'Low', 'No Identified Risk' ];
const publicHealthActionOptions = [ 'None', 'Recommended medical evaluation of symptoms', 'Document results of medical evaluation', 'Recommended laboratory testing' ];
const monitoringPlanOptions = [ 'None', 'Daily active monitoring', 'Self-monitoring with public health supervision', 'Self-monitoring with delegated supervision', 'Self-observation' ];

function getExposureRiskAssessmentWrapper(patient, hasGroupMembers) {
  return shallow(<GenericAction patient={patient} title={'EXPOSURE RISK ASSESSMENT'} monitoringAction={'exposure_risk_assessment'}
    options={exposureRiskAssessmentOptions} tooltipKey={'exposureRiskAssessment'} has_group_members={hasGroupMembers} authenticity_token={authyToken} />);
}

function getMonitoringPlanWrapper(patient, hasGroupMembers) {
  return shallow(<GenericAction patient={patient} title={'MONITORING PLAN'} monitoringAction={'monitoring_plan'}
    options={monitoringPlanOptions} tooltipKey={'monitoringPlan'} has_group_members={hasGroupMembers} authenticity_token={authyToken} />);
}

function getPublicHealthActionWrapper(patient, hasGroupMembers) {
  const tooltipKey = patient.isolation ? 'latestPublicHealthActionInIsolation' : 'latestPublicHealthActionInExposure';
  return shallow(<GenericAction patient={patient} title={'LATEST PUBLIC HEALTH ACTION'} monitoringAction={'public_health_action'}
    options={publicHealthActionOptions} tooltipKey={tooltipKey} has_group_members={hasGroupMembers} authenticity_token={authyToken} />);
}

describe('GenericAction', () => {
  it('Properly renders all main components for Exposure Risk Assessment', () => {
    const wrapper = getExposureRiskAssessmentWrapper(mockPatient1, false);
    expect(wrapper.find(Form.Label).text().includes('EXPOSURE RISK ASSESSMENT')).toBeTruthy();
    expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('exposureRiskAssessment');
    expect(wrapper.find('#exposure_risk_assessment').exists()).toBeTruthy();
    expect(wrapper.find('#monitoring_plan').exists()).toBeFalsy();
    expect(wrapper.find('#public_health_action').exists()).toBeFalsy();
    expect(wrapper.find('option').length).toEqual(5);
    exposureRiskAssessmentOptions.forEach(function(value, index) {
        expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#exposure_risk_assessment').prop('value')).toEqual(mockPatient1.exposure_risk_assessment);
  });

  it('Properly renders all main components for Monitoring Plan', () => {
    const wrapper = getMonitoringPlanWrapper(mockPatient1, false);
    expect(wrapper.find(Form.Label).text().includes('MONITORING PLAN')).toBeTruthy();
    expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('monitoringPlan');
    expect(wrapper.find('#monitoring_plan').exists()).toBeTruthy();
    expect(wrapper.find('#exposure_risk_assessment').exists()).toBeFalsy();
    expect(wrapper.find('#public_health_action').exists()).toBeFalsy();
    expect(wrapper.find('option').length).toEqual(5);
    monitoringPlanOptions.forEach(function(value, index) {
        expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#monitoring_plan').prop('value')).toEqual(mockPatient1.monitoring_plan);
  });

  it('Properly renders all main components for Public Health Action', () => {
    const wrapper = getPublicHealthActionWrapper(mockPatient1, false);
    expect(wrapper.find(Form.Label).text().includes('LATEST PUBLIC HEALTH ACTION')).toBeTruthy();
    expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('latestPublicHealthActionInIsolation');
    expect(wrapper.find('#public_health_action').exists()).toBeTruthy();
    expect(wrapper.find('#exposure_risk_assessment').exists()).toBeFalsy();
    expect(wrapper.find('#monitoring_plan').exists()).toBeFalsy();
    expect(wrapper.find('option').length).toEqual(4);
    publicHealthActionOptions.forEach(function(value, index) {
        expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#public_health_action').prop('value')).toEqual(mockPatient1.public_health_action);
  });

  it('Changing Exposure Risk Assessment opens modal', () => {
    const wrapper = getExposureRiskAssessmentWrapper(mockPatient1, false);
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Changing Monitoring Plan opens modal', () => {
    const wrapper = getMonitoringPlanWrapper(mockPatient1, false);
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Changing Public Health Action opens modal', () => {
    const wrapper = getPublicHealthActionWrapper(mockPatient1, false);
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#public_health_action').simulate('change', { target: { id: 'public_health_action', value: 'Recommended laboratory testing' } });
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders Exposure Risk Assessment modal and sets state correctly', () => {
    const wrapper = getExposureRiskAssessmentWrapper(mockPatient1, false);
    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });
    
    // renders properly
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Exposure Risk Assessment');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').text()).toEqual(`Are you sure you want to change exposure risk assessment to "High"?`);
    expect(wrapper.find(Modal.Body).find('p').find('b').exists()).toBeFalsy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');

    // sets state correctly
    expect(wrapper.state('showExposureRiskAssessmentModal')).toBeTruthy();
    expect(wrapper.state('showMonitoringPlanModal')).toBeFalsy();
    expect(wrapper.state('showPublicHealthActionModal')).toBeFalsy();
    expect(wrapper.state('apply_to_group')).toBeFalsy();
    expect(wrapper.state('exposure_risk_assessment')).toEqual('High');
    expect(wrapper.state('monitoring_plan')).toEqual(mockPatient1.monitoring_plan);
    expect(wrapper.state('public_health_action')).toEqual(mockPatient1.public_health_action);
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Properly renders Monitoring Plan modal and sets state correctly', () => {
    const wrapper = getMonitoringPlanWrapper(mockPatient1, false);
    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });
    
    // renders properly
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Monitoring Plan');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').text()).toEqual(`Are you sure you want to change monitoring plan to "None"?`);
    expect(wrapper.find(Modal.Body).find('p').find('b').exists()).toBeFalsy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');

    // sets state correctly
    expect(wrapper.state('showExposureRiskAssessmentModal')).toBeFalsy();
    expect(wrapper.state('showMonitoringPlanModal')).toBeTruthy();
    expect(wrapper.state('showPublicHealthActionModal')).toBeFalsy();
    expect(wrapper.state('apply_to_group')).toBeFalsy();
    expect(wrapper.state('exposure_risk_assessment')).toEqual(mockPatient1.exposure_risk_assessment);
    expect(wrapper.state('monitoring_plan')).toEqual('None');
    expect(wrapper.state('public_health_action')).toEqual(mockPatient1.public_health_action);
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Properly renders Public Health Action modal and sets state correctly for monitorees in the closed line list', () => {
    const wrapper = getPublicHealthActionWrapper(mockPatient3, false);
    wrapper.find('#public_health_action').simulate('change', { target: { id: 'public_health_action', value: 'Recommended laboratory testing' } });
    
    // renders properly
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Public Health Action');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').text().includes(`Are you sure you want to change latest public health action to "Recommended laboratory testing"?`)).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').find('b').text()).toEqual(` Since this record is on the "Closed" line list, updating this value will not move this record to another line list. If this individual should be actively monitored, please update the record's Monitoring Status.`);
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');

    // sets state correctly
    expect(wrapper.state('showExposureRiskAssessmentModal')).toBeFalsy();
    expect(wrapper.state('showMonitoringPlanModal')).toBeFalsy();
    expect(wrapper.state('showPublicHealthActionModal')).toBeTruthy();
    expect(wrapper.state('apply_to_group')).toBeFalsy();
    expect(wrapper.state('exposure_risk_assessment')).toEqual(mockPatient3.exposure_risk_assessment);
    expect(wrapper.state('monitoring_plan')).toEqual(mockPatient3.monitoring_plan);
    expect(wrapper.state('public_health_action')).toEqual('Recommended laboratory testing');
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Properly renders Public Health Action modal and sets state correctly for monitorees in the isolation workflow', () => {
    const wrapper = getPublicHealthActionWrapper(mockPatient1, true);
    wrapper.find('#public_health_action').simulate('change', { target: { id: 'public_health_action', value: 'Recommended laboratory testing' } });
    
    // renders properly
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Public Health Action');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').at(0).text().includes(`Are you sure you want to change latest public health action to "Recommended laboratory testing"?`)).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').at(0).find('b').text()).toEqual(' This will not impact the line list on which this record appears.');
    expect(wrapper.find(Modal.Body).find('i').exists()).toBeFalsy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');

    // sets state correctly
    expect(wrapper.state('showExposureRiskAssessmentModal')).toBeFalsy();
    expect(wrapper.state('showMonitoringPlanModal')).toBeFalsy();
    expect(wrapper.state('showPublicHealthActionModal')).toBeTruthy();
    expect(wrapper.state('apply_to_group')).toBeFalsy();
    expect(wrapper.state('exposure_risk_assessment')).toEqual(mockPatient1.exposure_risk_assessment);
    expect(wrapper.state('monitoring_plan')).toEqual(mockPatient1.monitoring_plan);
    expect(wrapper.state('public_health_action')).toEqual('Recommended laboratory testing');
    expect(wrapper.state('reasoning')).toEqual('');

    // renders household warning if apply_to_group selected
    wrapper.find('#apply_to_group_yes').simulate('change', { target: { name: 'apply_to_group', id: 'apply_to_group_yes' } });
    expect(wrapper.find(Modal.Body).find('i').text()).toEqual(`If any household members are being monitored in the exposure workflow, those records will appear on the PUI line list if any public health action other than "None" is selected above. If any household members are being monitored in the isolation workflow, this update will not impact the line list on which those records appear.`);
  });

  it('Properly renders Public Health Action modal and sets state correctly for monitorees in the exposure workflow', () => {
    const wrapper = getPublicHealthActionWrapper(mockPatient2, true);
    wrapper.find('#public_health_action').simulate('change', { target: { id: 'public_health_action', value: 'Recommended laboratory testing' } });
    
    // renders properly
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Public Health Action');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').at(0).text().includes(`Are you sure you want to change latest public health action to "Recommended laboratory testing"?`)).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').at(0).find('b').text()).toEqual(' The monitoree will be moved into the PUI line list.');
    expect(wrapper.find(Modal.Body).find('i').exists()).toBeFalsy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');

    // sets state correctly
    expect(wrapper.state('showExposureRiskAssessmentModal')).toBeFalsy();
    expect(wrapper.state('showMonitoringPlanModal')).toBeFalsy();
    expect(wrapper.state('showPublicHealthActionModal')).toBeTruthy();
    expect(wrapper.state('apply_to_group')).toBeFalsy();
    expect(wrapper.state('exposure_risk_assessment')).toEqual(mockPatient2.exposure_risk_assessment);
    expect(wrapper.state('monitoring_plan')).toEqual(mockPatient2.monitoring_plan);
    expect(wrapper.state('public_health_action')).toEqual('Recommended laboratory testing');
    expect(wrapper.state('reasoning')).toEqual('');

    // renders household warning if apply_to_group selected
    wrapper.find('#apply_to_group_yes').simulate('change', { target: { name: 'apply_to_group', id: 'apply_to_group_yes' } });
    expect(wrapper.find(Modal.Body).find('i').text()).toEqual(`If any household members are being monitored in the exposure workflow, those records will appear on the PUI line list if any public health action other than "None" is selected above. If any household members are being monitored in the isolation workflow, this update will not impact the line list on which those records appear.`);
  });

  it('Properly renders radio buttons for HoH', () => {
    const wrapper = getExposureRiskAssessmentWrapper(mockPatient1, true);
    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });
    const modalBody = wrapper.find(Modal.Body);

    expect(modalBody.find(Form.Group).exists()).toBeTruthy();
    expect(modalBody.find(Form.Check).length).toEqual(2);
    expect(modalBody.find('#apply_to_group_no').prop('type')).toEqual('radio');
    expect(modalBody.find('#apply_to_group_no').prop('label')).toEqual('This monitoree only');
    expect(modalBody.find('#apply_to_group_yes').prop('type')).toEqual('radio');
    expect(modalBody.find('#apply_to_group_yes').prop('label')).toEqual('This monitoree and all household members');
  });

  it('Clicking HoH radio buttons toggles this.state.apply_to_group', () => {
    const wrapper = getExposureRiskAssessmentWrapper(mockPatient1, true);
    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });

    // initial radio button state
    expect(wrapper.state('apply_to_group')).toBeFalsy();
    expect(wrapper.find('#apply_to_group_no').prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_group_yes').prop('checked')).toBeFalsy();

    // change to apply to all of household
    wrapper.find('#apply_to_group_yes').simulate('change', { target: { name: 'apply_to_group', id: 'apply_to_group_yes' } });
    wrapper.update()
    expect(wrapper.state('apply_to_group')).toBeTruthy();
    expect(wrapper.find('#apply_to_group_no').prop('checked')).toBeFalsy();
    expect(wrapper.find('#apply_to_group_yes').prop('checked')).toBeTruthy();

    // change back to just this monitoree
    wrapper.find('#apply_to_group_no').simulate('change', { target: { name: 'apply_to_group', id: 'apply_to_group_no' } });
    wrapper.update()
    expect(wrapper.state('apply_to_group')).toBeFalsy();
    expect(wrapper.find('#apply_to_group_no').prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_group_yes').prop('checked')).toBeFalsy();
  });

  it('Adding reasoning updates state', () => {
    const wrapper = getExposureRiskAssessmentWrapper(mockPatient1, false);
    const handleChangeSpy = jest.spyOn(wrapper.instance(), 'handleChange');
    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });

    expect(wrapper.find('#reasoning').exists()).toBeTruthy();
    wrapper.find('#reasoning').simulate('change', { target: { id: 'reasoning', value: 'insert reasoning text here' } });
    expect(handleChangeSpy).toHaveBeenCalled();
    expect(wrapper.state('reasoning')).toEqual('insert reasoning text here');
  });

  it('Clicking the cancel button closes Exposure Risk Assessment modal and resets state', () => {
    const wrapper = getExposureRiskAssessmentWrapper(mockPatient1, false);
    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });

    // closes modal
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();

    // resets state
    expect(wrapper.state('showExposureRiskAssessmentModal')).toBeFalsy();
    expect(wrapper.state('showMonitoringPlanModal')).toBeFalsy();
    expect(wrapper.state('showPublicHealthActionModal')).toBeFalsy();
    expect(wrapper.state('apply_to_group')).toBeFalsy();
    expect(wrapper.state('exposure_risk_assessment')).toEqual(mockPatient1.exposure_risk_assessment);
    expect(wrapper.state('monitoring_plan')).toEqual(mockPatient1.monitoring_plan);
    expect(wrapper.state('public_health_action')).toEqual(mockPatient1.public_health_action);
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Clicking the cancel button closes Monitoring Plan modal and resets state', () => {
    const wrapper = getMonitoringPlanWrapper(mockPatient1, false);
    wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: 'None' } });

    // closes modal
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();

    // resets state
    expect(wrapper.state('showExposureRiskAssessmentModal')).toBeFalsy();
    expect(wrapper.state('showMonitoringPlanModal')).toBeFalsy();
    expect(wrapper.state('showPublicHealthActionModal')).toBeFalsy();
    expect(wrapper.state('apply_to_group')).toBeFalsy();
    expect(wrapper.state('exposure_risk_assessment')).toEqual(mockPatient1.exposure_risk_assessment);
    expect(wrapper.state('monitoring_plan')).toEqual(mockPatient1.monitoring_plan);
    expect(wrapper.state('public_health_action')).toEqual(mockPatient1.public_health_action);
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Clicking the cancel button closes Public Health Action modal and resets state', () => {
    const wrapper = getPublicHealthActionWrapper(mockPatient1, false);
    wrapper.find('#public_health_action').simulate('change', { target: { id: 'public_health_action', value: 'Recommended laboratory testing' } });

    // closes modal
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();

    // resets state
    expect(wrapper.state('showExposureRiskAssessmentModal')).toBeFalsy();
    expect(wrapper.state('showMonitoringPlanModal')).toBeFalsy();
    expect(wrapper.state('showPublicHealthActionModal')).toBeFalsy();
    expect(wrapper.state('apply_to_group')).toBeFalsy();
    expect(wrapper.state('exposure_risk_assessment')).toEqual(mockPatient1.exposure_risk_assessment);
    expect(wrapper.state('monitoring_plan')).toEqual(mockPatient1.monitoring_plan);
    expect(wrapper.state('public_health_action')).toEqual(mockPatient1.public_health_action);
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getExposureRiskAssessmentWrapper(mockPatient1, true);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');

    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
