import React from 'react';
import { shallow, mount } from 'enzyme';
import _ from 'lodash';
import PublicHealthManagement from '../../../components/enrollment/steps/PublicHealthManagement';
import { blankIsolationMockPatient, mockPatient1 } from '../../mocks/mockPatients';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';

const onChangeMock = jest.fn();
const onPropagatedFieldChangeMock = jest.fn();
const inputLabels = ['PUBLIC HEALTH RISK ASSESSMENT AND MANAGEMENT', 'ASSIGNED JURISDICTION', 'ASSIGNED USER', 'RISK ASSESSMENT', 'MONITORING PLAN'];
const assignedUsers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 21];
const exposureRiskAssessmentOptions = ['', 'High', 'Medium', 'Low', 'No Identified Risk'];
const monitoringPlanOptions = ['', 'None', 'Daily active monitoring', 'Self-monitoring with public health supervision', 'Self-monitoring with delegated supervision', 'Self-observation'];

function getShallowWrapper(patient, hasDependents) {
  const current = {
    isolation: patient.isolation,
    patient: patient,
    propagatedFields: {},
  };
  return shallow(<PublicHealthManagement onChange={onChangeMock} onPropagatedFieldChange={onPropagatedFieldChangeMock} currentState={current} patient={patient} has_dependents={hasDependents} jurisdiction_paths={mockJurisdictionPaths} assigned_users={assignedUsers} schema={{}} errors={{}} authenticity_token={'123'} />);
}

function getMountedWrapper(patient, hasDependents) {
  const current = {
    isolation: patient.isolation,
    patient: patient,
    propagatedFields: {},
  };
  return mount(<PublicHealthManagement onChange={onChangeMock} onPropagatedFieldChange={onPropagatedFieldChangeMock} currentState={current} patient={patient} has_dependents={hasDependents} jurisdiction_paths={mockJurisdictionPaths} assigned_users={assignedUsers} schema={{}} errors={{}} authenticity_token={'123'} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('PublicHealthManagement', () => {
  it('Properly renders all main components when enrolling a new monitoree', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient);
    inputLabels.forEach((label, index) => {
      expect(wrapper.find('label').at(index).text()).toContain(label);
    });

    expect(wrapper.find('#jurisdiction_id').exists()).toBe(true);
    expect(wrapper.find('#jurisdiction_id').prop('value')).toEqual(mockJurisdictionPaths[blankIsolationMockPatient.jurisdiction_id]);
    expect(wrapper.find('#jurisdiction_paths').exists()).toBe(true);
    _.values(mockJurisdictionPaths).forEach((option, index) => {
      expect(wrapper.find('#jurisdiction_paths').find('option').at(index).text()).toContain(option);
    });
    expect(wrapper.find('#update_group_member_jurisdiction_id').exists()).toBe(false);

    expect(wrapper.find('#assigned_user').exists()).toBe(true);
    expect(wrapper.find('#assigned_user').prop('value')).toEqual('');
    expect(wrapper.find('#assigned_users').exists()).toBe(true);
    assignedUsers.forEach((option, index) => {
      expect(wrapper.find('#assigned_users').find('option').at(index).text()).toEqual(String(option));
    });
    expect(wrapper.find('#update_group_member_assigned_user').exists()).toBe(false);

    expect(wrapper.find('#exposure_risk_assessment').exists()).toBe(true);
    expect(wrapper.find('#exposure_risk_assessment').prop('value')).toEqual('');
    exposureRiskAssessmentOptions.forEach((option, index) => {
      expect(wrapper.find('#exposure_risk_assessment').find('option').at(index).text()).toContain(option);
    });

    expect(wrapper.find('#monitoring_plan').exists()).toBe(true);
    expect(wrapper.find('#monitoring_plan').prop('value')).toEqual('');
    monitoringPlanOptions.forEach((option, index) => {
      expect(wrapper.find('#monitoring_plan').find('option').at(index).text()).toContain(option);
    });
  });

  it('Properly renders all main components when editing an existing monitoree', () => {
    const wrapper = getMountedWrapper(mockPatient1);
    inputLabels.forEach((label, index) => {
      expect(wrapper.find('label').at(index).text()).toContain(label);
    });

    expect(wrapper.find('#jurisdiction_id').exists()).toBe(true);
    expect(wrapper.find('#jurisdiction_id').prop('value')).toEqual(mockJurisdictionPaths[mockPatient1.jurisdiction_id]);
    expect(wrapper.find('#jurisdiction_paths').exists()).toBe(true);
    _.values(mockJurisdictionPaths).forEach((option, index) => {
      expect(wrapper.find('#jurisdiction_paths').find('option').at(index).text()).toContain(option);
    });
    expect(wrapper.find('#update_group_member_jurisdiction_id').exists()).toBe(false);

    expect(wrapper.find('#assigned_user').exists()).toBe(true);
    expect(wrapper.find('#assigned_user').prop('value')).toEqual(mockPatient1.assigned_user);
    expect(wrapper.find('#assigned_users').exists()).toBe(true);
    assignedUsers.forEach((option, index) => {
      expect(wrapper.find('#assigned_users').find('option').at(index).text()).toEqual(String(option));
    });
    expect(wrapper.find('#update_group_member_assigned_user').exists()).toBe(false);

    expect(wrapper.find('#exposure_risk_assessment').exists()).toBe(true);
    expect(wrapper.find('#exposure_risk_assessment').prop('value')).toEqual(mockPatient1.exposure_risk_assessment);
    exposureRiskAssessmentOptions.forEach((option, index) => {
      expect(wrapper.find('#exposure_risk_assessment').find('option').at(index).text()).toContain(option);
    });

    expect(wrapper.find('#monitoring_plan').exists()).toBe(true);
    expect(wrapper.find('#monitoring_plan').prop('value')).toEqual(mockPatient1.monitoring_plan);
    monitoringPlanOptions.forEach((option, index) => {
      expect(wrapper.find('#monitoring_plan').find('option').at(index).text()).toContain(option);
    });
  });

  it('Changing Jurisdiction properly updates state and calls props.onChange', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient);
    expect(onChangeMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('jurisdiction_path')).toEqual(mockJurisdictionPaths[blankIsolationMockPatient.jurisdiction_id]);
    expect(wrapper.find('#jurisdiction_id').prop('value')).toEqual(mockJurisdictionPaths[blankIsolationMockPatient.jurisdiction_id]);

    _.shuffle(_.values(mockJurisdictionPaths)).forEach((jurisdiction, index) => {
      wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: jurisdiction } });
      expect(onChangeMock).toHaveBeenCalledTimes(index + 1);
      expect(wrapper.state('jurisdiction_path')).toEqual(jurisdiction);
      expect(wrapper.find('#jurisdiction_id').prop('value')).toEqual(jurisdiction);
    });
  });

  it('Changing Jurisdiction for a HoH displays apply to household toggle button', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient, true);
    expect(wrapper.find('#update_group_member_jurisdiction_id').exists()).toBe(false);
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1, propagatedFields: {} } }, () => {
      expect(wrapper.find('#update_group_member_jurisdiction_id').exists()).toBe(true);
      wrapper.setState({ current: { ...wrapper.state.current, patient: blankIsolationMockPatient } }, () => {
        expect(wrapper.find('#update_group_member_jurisdiction_id').exists()).toBe(false);
      });
    });
  });

  it('Clicking Apply to Household toggle for Jurisdiction calls props.onPropagatedFieldChange', () => {
    const wrapper = getShallowWrapper(blankIsolationMockPatient, true);
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1 }, jurisdiction_path: mockJurisdictionPaths[mockPatient1.jurisdiction_id] }, () => {
      expect(onPropagatedFieldChangeMock).toHaveBeenCalledTimes(0);
      wrapper.find('#update_group_member_jurisdiction_id').simulate('change', { target: { name: 'jurisdiction_id', checked: true } });
      expect(onPropagatedFieldChangeMock).toHaveBeenCalledTimes(1);
      wrapper.find('#update_group_member_jurisdiction_id').simulate('change', { target: { name: 'jurisdiction_id', checked: false } });
      expect(onPropagatedFieldChangeMock).toHaveBeenCalledTimes(2);
    });
  });

  it('Changing Assigned User properly updates state and calls props.onChange', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient);
    expect(onChangeMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.assigned_user).toEqual(blankIsolationMockPatient.assigned_user);
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#assigned_user').prop('value')).toEqual('');

    _.shuffle(assignedUsers).forEach((user, index) => {
      wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: user } });
      expect(onChangeMock).toHaveBeenCalledTimes(index + 1);
      expect(wrapper.state('current').patient.assigned_user).toEqual(user);
      expect(wrapper.state('modified').patient.assigned_user).toEqual(user);
      expect(wrapper.find('#assigned_user').prop('value')).toEqual(user);
    });
  });

  it('Changing Assigned User for a HoH displays apply to household toggle button', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient, true);
    expect(wrapper.find('#update_group_member_assigned_user').exists()).toBe(false);
    wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: mockPatient1.assigned_user } });
    expect(wrapper.find('#update_group_member_assigned_user').exists()).toBe(true);
    wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: blankIsolationMockPatient.assigned_user } });
    expect(wrapper.find('#update_group_member_assigned_user').exists()).toBe(false);
  });

  it('Clicking Apply to Household toggle for Assigned User calls props.setEnrollmentState', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient, true);
    wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: mockPatient1.assigned_user } });
    expect(onPropagatedFieldChangeMock).toHaveBeenCalledTimes(0);
    wrapper.find('input#update_group_member_assigned_user').simulate('change', { target: { name: 'assigned_user', checked: true } });
    expect(onPropagatedFieldChangeMock).toHaveBeenCalledTimes(1);
    wrapper.find('input#update_group_member_assigned_user').simulate('change', { target: { name: 'assigned_user', checked: false } });
    expect(onPropagatedFieldChangeMock).toHaveBeenCalledTimes(2);
  });

  it('Changing Risk Assessment properly updates state and calls props.onChange', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient);
    expect(onChangeMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.exposure_risk_assessment).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#exposure_risk_assessment').prop('value')).toEqual('');

    _.shuffle(exposureRiskAssessmentOptions).forEach((option, index) => {
      wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: option } });
      expect(onChangeMock).toHaveBeenCalledTimes(index + 1);
      expect(wrapper.state('current').patient.exposure_risk_assessment).toEqual(option);
      expect(wrapper.state('modified').patient.exposure_risk_assessment).toEqual(option);
      expect(wrapper.find('#exposure_risk_assessment').prop('value')).toEqual(option);
    });
  });

  it('Changing Monitoring Plan properly updates state and calls props.onChange', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient);
    expect(onChangeMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.monitoring_plan).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#monitoring_plan').prop('value')).toEqual('');

    _.shuffle(monitoringPlanOptions).forEach((option, index) => {
      wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: option } });
      expect(onChangeMock).toHaveBeenCalledTimes(index + 1);
      expect(wrapper.state('current').patient.monitoring_plan).toEqual(option);
      expect(wrapper.state('modified').patient.monitoring_plan).toEqual(option);
      expect(wrapper.find('#monitoring_plan').prop('value')).toEqual(option);
    });
  });
});
