import React from 'react';
import { shallow } from 'enzyme';
import { Alert, Button, Card, Form } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import _ from 'lodash';

import CaseInformation from '../../../components/enrollment/steps/CaseInformation';
import FirstPositiveLaboratory from '../../../components/patient/laboratory/FirstPositiveLaboratory';
import PublicHealthManagement from '../../../components/enrollment/steps/PublicHealthManagement';
import DateInput from '../../../components/util/DateInput';
import { blankIsolationMockPatient, mockPatient1 } from '../../mocks/mockPatients';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockLaboratory1 } from '../../mocks/mockLaboratories';

const previousMock = jest.fn();
const nextMock = jest.fn();
const setEnrollmentStateMock = jest.fn();
const caseStatusOptions = ['', 'Confirmed', 'Probable'];

function getWrapper(patient, showBtn) {
  const current = {
    isolation: true,
    patient: patient,
    propagatedFields: {},
  };
  return shallow(<CaseInformation previous={previousMock} next={nextMock} setEnrollmentState={setEnrollmentStateMock} currentState={current} patient={patient} showPreviousButton={showBtn} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} first_positive_lab={mockLaboratory1} authenticity_token={'123'} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('CaseInformation', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper(blankIsolationMockPatient, true);
    expect(wrapper.find('.sr-only').exists()).toBe(true);
    expect(wrapper.find('.sr-only').text()).toEqual('Monitoree Case Information');
    expect(wrapper.find(Card).exists()).toBe(true);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual('Monitoree Case Information');
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Alert).exists()).toBe(true);
    expect(wrapper.find(Alert).text()).toEqual('You must enter a Symptom Onset Date AND/OR a positive lab result (with a Specimen Collection Date) to enroll this case.');
    expect(wrapper.find(Form).exists()).toBe(true);
    expect(wrapper.find(Button).length).toEqual(2);
    expect(wrapper.find('#enrollment-previous-button').exists()).toBe(true);
    expect(wrapper.find('#enrollment-next-button').exists()).toBe(true);
  });

  it('Properly renders case information inputs when creating a new patient', () => {
    const wrapper = getWrapper(blankIsolationMockPatient);
    const symptomOnsetFormGroup = wrapper.find(Form.Group).at(1);
    const firstPostiveLabFormGroup = wrapper.find(Form.Group).at(2);
    const caseStatusFormGroup = wrapper.find(Form.Group).at(3);
    const notesFormGroup = wrapper.find(Form.Group).at(4);

    expect(symptomOnsetFormGroup.find(Form.Label).text()).toEqual('SYMPTOM ONSET DATE');
    expect(symptomOnsetFormGroup.find(DateInput).prop('date')).toBeNull();
    expect(firstPostiveLabFormGroup.find(FirstPositiveLaboratory).exists()).toBe(true);
    expect(caseStatusFormGroup.find(Form.Label).text()).toEqual('CASE STATUS');
    caseStatusFormGroup
      .find(Form.Control)
      .find('option')
      .forEach((option, index) => {
        expect(option.text()).toEqual(caseStatusOptions[parseInt(index)]);
      });
    expect(caseStatusFormGroup.find(Form.Control).prop('value')).toEqual('');
    expect(notesFormGroup.find(Form.Label).text()).toEqual('NOTES');
    expect(notesFormGroup.find(Form.Control).prop('value')).toEqual('');
    expect(notesFormGroup.find('.character-limit-text').exists()).toBe(true);
    expect(notesFormGroup.find('.character-limit-text').text()).toEqual('2000 characters remaining');
    expect(wrapper.find(PublicHealthManagement).exists()).toBe(true);
  });

  it('Properly renders case information inputs when editing an existing patient', () => {
    const wrapper = getWrapper(mockPatient1);
    const symptomOnsetFormGroup = wrapper.find(Form.Group).at(1);
    const firstPostiveLabFormGroup = wrapper.find(Form.Group).at(2);
    const caseStatusFormGroup = wrapper.find(Form.Group).at(3);
    const notesFormGroup = wrapper.find(Form.Group).at(4);

    expect(symptomOnsetFormGroup.find(Form.Label).text()).toContain('SYMPTOM ONSET DATE');
    expect(symptomOnsetFormGroup.find(Form.Label).find(ReactTooltip).exists()).toBe(true);
    expect(symptomOnsetFormGroup.find(Form.Label).find(ReactTooltip).find('span').text()).toEqual('This date is auto-populated by the system as the date of the earliest report flagged as symptomatic (red highlight) in the reports table. Field is blank when there are no symptomatic reports.');
    expect(symptomOnsetFormGroup.find(DateInput).prop('date')).toEqual(mockPatient1.symptom_onset);
    expect(firstPostiveLabFormGroup.find(FirstPositiveLaboratory).exists()).toBe(true);
    expect(caseStatusFormGroup.find(Form.Label).text()).toEqual('CASE STATUS');
    caseStatusFormGroup
      .find(Form.Control)
      .find('option')
      .forEach((option, index) => {
        expect(option.text()).toEqual(caseStatusOptions[parseInt(index)]);
      });
    expect(caseStatusFormGroup.find(Form.Control).prop('value')).toEqual(mockPatient1.case_status);
    expect(notesFormGroup.find(Form.Label).text()).toEqual('NOTES');
    expect(notesFormGroup.find(Form.Control).prop('value')).toEqual(mockPatient1.exposure_notes);
    expect(notesFormGroup.find('.character-limit-text').exists()).toBe(true);
    expect(notesFormGroup.find('.character-limit-text').text()).toEqual(`${2000 - mockPatient1.exposure_notes.length} characters remaining`);
    expect(wrapper.find(PublicHealthManagement).exists()).toBe(true);
  });

  it('Changing Symptom Onset properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getWrapper(blankIsolationMockPatient);
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
    const wrapper = getWrapper(blankIsolationMockPatient);
    expect(wrapper.find(Form.Control).at(0).prop('value')).toEqual('');
    expect(wrapper.state('current').patient.case_status).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);

    _.times(5, i => {
      let random = _.random(0, caseStatusOptions.length - 1);
      let caseStatus = caseStatusOptions[parseInt(random)];
      wrapper
        .find(Form.Control)
        .at(0)
        .simulate('change', { target: { id: 'case_status', value: caseStatus } });
      expect(setEnrollmentStateMock).toHaveBeenCalledTimes(i + 1);
      expect(wrapper.state('current').patient.case_status).toEqual(caseStatus);
      expect(wrapper.state('modified').patient.case_status).toEqual(caseStatus);
      expect(wrapper.find(Form.Control).at(0).prop('value')).toEqual(caseStatus);
    });
  });

  it('Changing Notes properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getWrapper(blankIsolationMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.exposure_notes).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find(Form.Control).at(1).prop('value')).toEqual('');
    expect(wrapper.find('.character-limit-text').text()).toEqual('2000 characters remaining');

    let note = 'I am a note';
    wrapper
      .find(Form.Control)
      .at(1)
      .simulate('change', { target: { id: 'exposure_notes', value: note } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').patient.exposure_notes).toEqual(note);
    expect(wrapper.state('modified').patient.exposure_notes).toEqual(note);
    expect(wrapper.find(Form.Control).at(1).prop('value')).toEqual(note);
    expect(wrapper.find('.character-limit-text').text()).toEqual(`${2000 - note.length} characters remaining`);

    note = 'I am a different note';
    wrapper
      .find(Form.Control)
      .at(1)
      .simulate('change', { target: { id: 'exposure_notes', value: note } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').patient.exposure_notes).toEqual(note);
    expect(wrapper.state('modified').patient.exposure_notes).toEqual(note);
    expect(wrapper.find(Form.Control).at(1).prop('value')).toEqual(note);
    expect(wrapper.find('.character-limit-text').text()).toEqual(`${2000 - note.length} characters remaining`);

    note = '';
    wrapper
      .find(Form.Control)
      .at(1)
      .simulate('change', { target: { id: 'exposure_notes', value: note } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(3);
    expect(wrapper.state('current').patient.exposure_notes).toEqual(note);
    expect(wrapper.state('modified').patient.exposure_notes).toEqual(note);
    expect(wrapper.find(Form.Control).at(1).prop('value')).toEqual(note);
    expect(wrapper.find('.character-limit-text').text()).toEqual(`${2000 - note.length} characters remaining`);
  });

  it('Hides "Previous" and "Next" buttons if requisite functions are not passed in via props', () => {
    const wrapper = shallow(<CaseInformation currentState={{ isolation: true, patient: blankIsolationMockPatient, propagatedFields: {} }} patient={blankIsolationMockPatient} showPreviousButton={true} jurisdiction_paths={mockJurisdictionPaths} />);
    expect(wrapper.find('#enrollment-previous-button').exists()).toBe(false);
    expect(wrapper.find('#enrollment-next-button').exists()).toBe(false);
  });

  it('Hides the "Previous" button when props.showPreviousButton is false', () => {
    const wrapper = getWrapper(blankIsolationMockPatient);
    expect(wrapper.find('#enrollment-previous-button').exists()).toBe(false);
    expect(wrapper.find('#enrollment-next-button').exists()).toBe(true);
  });

  it('Clicking the "Previous" button calls props.previous', () => {
    const wrapper = getWrapper(blankIsolationMockPatient, true);
    expect(previousMock).not.toHaveBeenCalled();
    wrapper.find('#enrollment-previous-button').simulate('click');
    expect(previousMock).toHaveBeenCalled();
  });

  it('Clicking the "Next" button calls validate method', () => {
    const wrapper = getWrapper(blankIsolationMockPatient);
    const validateSpy = jest.spyOn(wrapper.instance(), 'validate');
    expect(validateSpy).not.toHaveBeenCalled();
    wrapper.find('#enrollment-next-button').simulate('click');
    expect(validateSpy).toHaveBeenCalled();
  });
});
