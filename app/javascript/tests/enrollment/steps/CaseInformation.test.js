import React from 'react';
import { shallow, mount } from 'enzyme';
import { Alert, Button, Card, Form } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import _ from 'lodash';

import CaseInformation from '../../../components/enrollment/steps/CaseInformation';
import FirstPositiveLaboratory from '../../../components/patient/laboratory/FirstPositiveLaboratory';
import DateInput from '../../../components/util/DateInput';
import { blankIsolationMockPatient, mockPatient1, mockPatient4 } from '../../mocks/mockPatients';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockLaboratory1 } from '../../mocks/mockLaboratories';

const previousMock = jest.fn();
const nextMock = jest.fn();
const setEnrollmentStateMock = jest.fn();
const inputLabels = ['SYMPTOM ONSET DATE', 'CASE STATUS', 'NOTES', 'PUBLIC HEALTH RISK ASSESSMENT AND MANAGEMENT', 'ASSIGNED JURISDICTION', 'ASSIGNED USER', 'RISK ASSESSMENT', 'MONITORING PLAN'];
const caseStatusOptions = ['', 'Confirmed', 'Probable'];
const assignedUsers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 21];
const exposureRiskAssessmentOptions = ['', 'High', 'Medium', 'Low', 'No Identified Risk'];
const monitoringPlanOptions = ['', 'None', 'Daily active monitoring', 'Self-monitoring with public health supervision', 'Self-monitoring with delegated supervision', 'Self-observation'];

function getShallowWrapper(patient, hideBtn, hasDependents) {
  const current = {
    isolation: true,
    patient: patient,
    propagatedFields: {},
  };
  return shallow(<CaseInformation previous={previousMock} next={nextMock} setEnrollmentState={setEnrollmentStateMock} currentState={current} patient={patient} hidePreviousButton={hideBtn} has_dependents={hasDependents} jurisdiction_paths={mockJurisdictionPaths} assigned_users={assignedUsers} first_positive_lab={mockLaboratory1} authenticity_token={'123'} />);
}

function getMountedWrapper(patient, hideBtn, hasDependents) {
  const current = {
    isolation: true,
    patient: patient,
    propagatedFields: {},
  };
  return mount(<CaseInformation previous={previousMock} next={nextMock} setEnrollmentState={setEnrollmentStateMock} currentState={current} patient={patient} hidePreviousButton={hideBtn} has_dependents={hasDependents} jurisdiction_paths={mockJurisdictionPaths} assigned_users={assignedUsers} first_positive_lab={mockLaboratory1} authenticity_token={'123'} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('CaseInformation', () => {
  it('Properly renders all main components', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient);
    expect(wrapper.find('h1.sr-only').exists()).toBe(true);
    expect(wrapper.find('h1.sr-only').text()).toEqual('Monitoree Case Information');
    expect(wrapper.find(Card).exists()).toBe(true);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual('Monitoree Case Information');
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Alert).exists()).toBe(true);
    expect(wrapper.find(Alert).text()).toEqual('You must enter a Symptom Onset Date AND/OR a positive lab result (with a Specimen Collection Date) to enroll this case.');
    expect(wrapper.find(Form).exists()).toBe(true);
    expect(wrapper.find('#symptom_onset').exists()).toBe(true);
    expect(wrapper.find(FirstPositiveLaboratory).exists()).toBe(true);
    expect(wrapper.find('#case_status').exists()).toBe(true);
    expect(wrapper.find('#exposure_notes').exists()).toBe(true);
    expect(wrapper.find('.character-limit-text').exists()).toBe(true);
    expect(wrapper.find('#jurisdiction_id').exists()).toBe(true);
    expect(wrapper.find('#jurisdiction_paths').exists()).toBe(true);
    _.values(mockJurisdictionPaths).forEach((option, index) => {
      expect(wrapper.find('#jurisdiction_paths').find('option').at(index).text()).toContain(option);
    });
    expect(wrapper.find('#update_group_member_jurisdiction_id').exists()).toBe(false);
    expect(wrapper.find('#assigned_user').exists()).toBe(true);
    expect(wrapper.find('#assigned_users').exists()).toBe(true);
    assignedUsers.forEach((option, index) => {
      expect(wrapper.find('#assigned_users').find('option').at(index).text()).toContain(option);
    });
    expect(wrapper.find('#update_group_member_assigned_user').exists()).toBe(false);
    expect(wrapper.find('#exposure_risk_assessment').exists()).toBe(true);
    exposureRiskAssessmentOptions.forEach((option, index) => {
      expect(wrapper.find('#exposure_risk_assessment').find('option').at(index).text()).toContain(option);
    });
    expect(wrapper.find('#monitoring_plan').exists()).toBe(true);
    monitoringPlanOptions.forEach((option, index) => {
      expect(wrapper.find('#monitoring_plan').find('option').at(index).text()).toContain(option);
    });
    expect(wrapper.find('#enrollment-previous-button').exists()).toBe(true);
    expect(wrapper.find('#enrollment-previous-button').hostNodes().text()).toEqual('Previous');
    expect(wrapper.find('#enrollment-next-button').exists()).toBe(true);
    expect(wrapper.find('#enrollment-next-button').hostNodes().text()).toEqual('Next');
  });

  it('Properly renders case information inputs when creating a new patient', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient);
    inputLabels.forEach((label, index) => {
      expect(wrapper.find('label').at(index).text()).toContain(label);
    });

    expect(wrapper.find(DateInput).prop('date')).toBeNull();
    expect(wrapper.find('#case_status').prop('value')).toEqual('');
    expect(wrapper.find('#exposure_notes').prop('value')).toEqual('');
    expect(wrapper.find('.character-limit-text').text()).toEqual('2000 characters remaining');
    expect(wrapper.find('#jurisdiction_id').prop('value')).toEqual(mockJurisdictionPaths[blankIsolationMockPatient.jurisdiction_id]);
    expect(wrapper.find('#assigned_user').prop('value')).toEqual('');
    expect(wrapper.find('#exposure_risk_assessment').prop('value')).toEqual('');
    expect(wrapper.find('#monitoring_plan').prop('value')).toEqual('');
  });

  it('Properly renders case information inputs when editing an existing patient', () => {
    const wrapper = getMountedWrapper(mockPatient1);
    inputLabels.forEach((label, index) => {
      expect(wrapper.find('label').at(index).text()).toContain(label);
    });

    expect(wrapper.find(DateInput).prop('date')).toEqual(mockPatient1.symptom_onset);
    expect(wrapper.find('#case_status').prop('value')).toEqual(mockPatient1.case_status);
    expect(wrapper.find('#exposure_notes').prop('value')).toEqual(mockPatient1.exposure_notes);
    expect(wrapper.find('.character-limit-text').text()).toEqual(`${2000 - mockPatient1.exposure_notes.length} characters remaining`);
    expect(wrapper.find('#jurisdiction_id').prop('value')).toEqual(mockJurisdictionPaths[mockPatient1.jurisdiction_id]);
    expect(wrapper.find('#assigned_user').prop('value')).toEqual(mockPatient1.assigned_user);
    expect(wrapper.find('#exposure_risk_assessment').prop('value')).toEqual(mockPatient1.exposure_risk_assessment);
    expect(wrapper.find('#monitoring_plan').prop('value')).toEqual(mockPatient1.monitoring_plan);
  });

  it('Properly renders symptom onset icon and tooltip', () => {
    const blankSOWrapper = getShallowWrapper(blankIsolationMockPatient);
    expect(blankSOWrapper.find(DateInput).prop('date')).toBeNull;
    expect(blankSOWrapper.find('i').exists()).toBe(false);
    expect(blankSOWrapper.find(ReactTooltip).exists()).toBe(false);

    const userSOWrapper = getShallowWrapper(mockPatient4);
    expect(userSOWrapper.find(DateInput).prop('date')).toEqual(mockPatient4.symptom_onset);
    expect(userSOWrapper.find('i').exists()).toBe(true);
    expect(userSOWrapper.find('i').hasClass('fa-user')).toBe(true);
    expect(userSOWrapper.find(ReactTooltip).exists()).toBe(true);
    expect(userSOWrapper.find(ReactTooltip).find('span').text()).toEqual('This date was set by a user');

    const systemSOWrapper = getShallowWrapper(mockPatient1);
    expect(systemSOWrapper.find(DateInput).prop('date')).toEqual(mockPatient1.symptom_onset);
    expect(systemSOWrapper.find('i').exists()).toBe(true);
    expect(systemSOWrapper.find('i').hasClass('fa-desktop')).toBe(true);
    expect(systemSOWrapper.find(ReactTooltip).exists()).toBe(true);
    expect(systemSOWrapper.find(ReactTooltip).find('span').text()).toEqual('This date is auto-populated by the system as the date of the earliest report flagged as symptomatic (red highlight) in the reports table. Field is blank when there are no symptomatic reports.');
  });

  it('Changing Symptom Onset properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getShallowWrapper(blankIsolationMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.symptom_onset).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find(DateInput).prop('date')).toBeNull();
    expect(wrapper.find(Alert).exists()).toBe(true);

    wrapper.find(DateInput).simulate('change', '2021-07-17');
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').patient.symptom_onset).toEqual('2021-07-17');
    expect(wrapper.state('modified').patient.symptom_onset).toEqual('2021-07-17');
    expect(wrapper.find(DateInput).prop('date')).toEqual('2021-07-17');
    expect(wrapper.find(Alert).exists()).toBe(false);

    wrapper.find(DateInput).simulate('change', null);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').patient.symptom_onset).toBeNull();
    expect(wrapper.state('modified').patient.symptom_onset).toBeNull();
    expect(wrapper.find(DateInput).prop('date')).toBeNull();
    expect(wrapper.find(Alert).exists()).toBe(true);
  });

  it('Changing Case Status properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.case_status).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#case_status').prop('value')).toEqual('');

    _.shuffle(caseStatusOptions).forEach((option, index) => {
      wrapper.find('#case_status').simulate('change', { target: { id: 'case_status', value: option } });
      expect(setEnrollmentStateMock).toHaveBeenCalledTimes(index + 1);
      expect(wrapper.state('current').patient.case_status).toEqual(option);
      expect(wrapper.state('modified').patient.case_status).toEqual(option);
      expect(wrapper.find('#case_status').prop('value')).toEqual(option);
    });
  });

  it('Changing Notes properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.exposure_notes).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#exposure_notes').prop('value')).toEqual('');
    expect(wrapper.find('.character-limit-text').text()).toEqual('2000 characters remaining');

    let note = 'I am a note';
    wrapper.find('#exposure_notes').simulate('change', { target: { id: 'exposure_notes', value: note } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').patient.exposure_notes).toEqual(note);
    expect(wrapper.state('modified').patient.exposure_notes).toEqual(note);
    expect(wrapper.find('#exposure_notes').prop('value')).toEqual(note);
    expect(wrapper.find('.character-limit-text').text()).toEqual(`${2000 - note.length} characters remaining`);

    note = 'I am a different note';
    wrapper.find('#exposure_notes').simulate('change', { target: { id: 'exposure_notes', value: note } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').patient.exposure_notes).toEqual(note);
    expect(wrapper.state('modified').patient.exposure_notes).toEqual(note);
    expect(wrapper.find('#exposure_notes').prop('value')).toEqual(note);
    expect(wrapper.find('.character-limit-text').text()).toEqual(`${2000 - note.length} characters remaining`);

    note = '';
    wrapper.find('#exposure_notes').simulate('change', { target: { id: 'exposure_notes', value: note } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(3);
    expect(wrapper.state('current').patient.exposure_notes).toEqual(note);
    expect(wrapper.state('modified').patient.exposure_notes).toEqual(note);
    expect(wrapper.find('#exposure_notes').prop('value')).toEqual(note);
    expect(wrapper.find('.character-limit-text').text()).toEqual(`${2000 - note.length} characters remaining`);
  });

  it('Changing Jurisdiction properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('jurisdiction_path')).toEqual(mockJurisdictionPaths[blankIsolationMockPatient.jurisdiction_id]);
    expect(wrapper.find('#jurisdiction_id').prop('value')).toEqual(mockJurisdictionPaths[blankIsolationMockPatient.jurisdiction_id]);

    _.shuffle(_.values(mockJurisdictionPaths)).forEach((jurisdiction, index) => {
      wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: jurisdiction } });
      expect(setEnrollmentStateMock).toHaveBeenCalledTimes(index + 1);
      expect(wrapper.state('jurisdiction_path')).toEqual(jurisdiction);
      expect(wrapper.find('#jurisdiction_id').prop('value')).toEqual(jurisdiction);
    });
  });

  it('Changing Jurisdiction for a HoH displays apply to household toggle button', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient, false, true);
    expect(wrapper.find('#update_group_member_jurisdiction_id').exists()).toBe(false);
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1, propagatedFields: {} } }, () => {
      expect(wrapper.find('#update_group_member_jurisdiction_id').exists()).toBe(true);
      wrapper.setState({ current: { ...wrapper.state.current, patient: blankIsolationMockPatient } }, () => {
        expect(wrapper.find('#update_group_member_jurisdiction_id').exists()).toBe(false);
      });
    });
  });

  it('Clicking Apply to Household toggle for Jurisdiction properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getShallowWrapper(blankIsolationMockPatient, false, true);
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1, propagatedFields: {} }, jurisdiction_path: mockJurisdictionPaths[mockPatient1.jurisdiction_id] }, () => {
      expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
      expect(wrapper.state('current').propagatedFields).toEqual({});
      expect(wrapper.state('modified').propagatedFields).toBeUndefined();
      expect(wrapper.find('#update_group_member_jurisdiction_id').prop('checked')).toBe(false);

      wrapper.find('#update_group_member_jurisdiction_id').simulate('change', { target: { name: 'jurisdiction_id', checked: true } });
      expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
      expect(wrapper.state('current').propagatedFields.jurisdiction_id).toBe(true);
      expect(wrapper.state('modified').propagatedFields.jurisdiction_id).toBe(true);
      expect(wrapper.find('#update_group_member_jurisdiction_id').prop('checked')).toBe(true);

      wrapper.find('#update_group_member_jurisdiction_id').simulate('change', { target: { name: 'jurisdiction_id', checked: false } });
      expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
      expect(wrapper.state('current').propagatedFields.jurisdiction_id).toBe(false);
      expect(wrapper.state('modified').propagatedFields.jurisdiction_id).toBe(false);
      expect(wrapper.find('#update_group_member_jurisdiction_id').prop('checked')).toBe(false);
    });
  });

  it('Changing Assigned User properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.assigned_user).toEqual(blankIsolationMockPatient.assigned_user);
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#assigned_user').prop('value')).toEqual('');

    _.shuffle(assignedUsers).forEach((user, index) => {
      wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: user } });
      expect(setEnrollmentStateMock).toHaveBeenCalledTimes(index + 1);
      expect(wrapper.state('current').patient.assigned_user).toEqual(user);
      expect(wrapper.state('modified').patient.assigned_user).toEqual(user);
      expect(wrapper.find('#assigned_user').prop('value')).toEqual(user);
    });
  });

  it('Changing Assigned User for a HoH displays apply to household toggle button', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient, false, true);
    expect(wrapper.find('#update_group_member_assigned_user').exists()).toBe(false);
    wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: mockPatient1.assigned_user } });
    expect(wrapper.find('#update_group_member_assigned_user').exists()).toBe(true);
    wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: blankIsolationMockPatient.assigned_user } });
    expect(wrapper.find('#update_group_member_assigned_user').exists()).toBe(false);
  });

  it('Clicking Apply to Household toggle for Assigned User properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient, false, true);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);

    wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: mockPatient1.assigned_user } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').propagatedFields).toEqual({});
    expect(wrapper.state('modified').propagatedFields).toBeUndefined();
    expect(wrapper.find('input#update_group_member_assigned_user').prop('checked')).toBe(false);

    wrapper.find('input#update_group_member_assigned_user').simulate('change', { target: { name: 'assigned_user', checked: true } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').propagatedFields.assigned_user).toBe(true);
    expect(wrapper.state('modified').propagatedFields.assigned_user).toBe(true);
    expect(wrapper.find('input#update_group_member_assigned_user').prop('checked')).toBe(true);

    wrapper.find('input#update_group_member_assigned_user').simulate('change', { target: { name: 'assigned_user', checked: false } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(3);
    expect(wrapper.state('current').propagatedFields.assigned_user).toBe(false);
    expect(wrapper.state('modified').propagatedFields.assigned_user).toBe(false);
    expect(wrapper.find('input#update_group_member_assigned_user').prop('checked')).toBe(false);
  });

  it('Changing Risk Assessment properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.exposure_risk_assessment).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#exposure_risk_assessment').prop('value')).toEqual('');

    _.shuffle(exposureRiskAssessmentOptions).forEach((option, index) => {
      wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: option } });
      expect(setEnrollmentStateMock).toHaveBeenCalledTimes(index + 1);
      expect(wrapper.state('current').patient.exposure_risk_assessment).toEqual(option);
      expect(wrapper.state('modified').patient.exposure_risk_assessment).toEqual(option);
      expect(wrapper.find('#exposure_risk_assessment').prop('value')).toEqual(option);
    });
  });

  it('Changing Monitoring Plan properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getMountedWrapper(blankIsolationMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.monitoring_plan).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#monitoring_plan').prop('value')).toEqual('');

    _.shuffle(monitoringPlanOptions).forEach((option, index) => {
      wrapper.find('#monitoring_plan').simulate('change', { target: { id: 'monitoring_plan', value: option } });
      expect(setEnrollmentStateMock).toHaveBeenCalledTimes(index + 1);
      expect(wrapper.state('current').patient.monitoring_plan).toEqual(option);
      expect(wrapper.state('modified').patient.monitoring_plan).toEqual(option);
      expect(wrapper.find('#monitoring_plan').prop('value')).toEqual(option);
    });
  });

  it('Hides "Previous" and "Next" buttons if requisite functions are not passed in via props', () => {
    const wrapper = shallow(<CaseInformation currentState={{ isolation: true, patient: blankIsolationMockPatient, propagatedFields: {} }} patient={blankIsolationMockPatient} hidePreviousButton={false} jurisdiction_paths={mockJurisdictionPaths} />);
    expect(wrapper.find(Button).length).toEqual(0);
    expect(wrapper.find('#enrollment-previous-button').exists()).toBe(false);
    expect(wrapper.find('#enrollment-next-button').exists()).toBe(false);
  });

  it('Hides the "Previous" button when props.hidePreviousButton is true', () => {
    const wrapper = getShallowWrapper(blankIsolationMockPatient, true);
    expect(wrapper.find(Button).length).toEqual(1);
    expect(wrapper.find('#enrollment-previous-button').exists()).toBe(false);
    expect(wrapper.find('#enrollment-next-button').exists()).toBe(true);
  });

  it('Clicking the "Previous" button calls props.previous', () => {
    const wrapper = getShallowWrapper(blankIsolationMockPatient);
    expect(previousMock).not.toHaveBeenCalled();
    wrapper.find('#enrollment-previous-button').simulate('click');
    expect(previousMock).toHaveBeenCalled();
  });

  it('Clicking the "Next" button calls validate method', () => {
    const wrapper = getShallowWrapper(blankIsolationMockPatient);
    const validateSpy = jest.spyOn(wrapper.instance(), 'validate');
    expect(validateSpy).not.toHaveBeenCalled();
    wrapper.find('#enrollment-next-button').simulate('click');
    expect(validateSpy).toHaveBeenCalled();
  });
});
