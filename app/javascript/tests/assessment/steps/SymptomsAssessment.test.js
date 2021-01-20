import React from 'react'
import { shallow } from 'enzyme';
import { Button, Card, Form } from 'react-bootstrap';
import SymptomsAssessment from '../../../components/assessment/steps/SymptomsAssessment.js'
import { mockAssessment1, mockAssessment2 } from '../../mocks/mockAssessments.js';
import { mockNewSymptoms, mockSymptoms1, mockSymptoms2 } from '../../mocks/mockSymptoms.js';
import { mockTranslations } from '../../mocks/mockTranslations'

const submitMock = jest.fn();

function getWrapper(assessment, symptoms, idPre) {
  return shallow(<SymptomsAssessment assessment={assessment} symptoms={symptoms} patient_initials={'AA'} patient_age={39} lang={'en'}
    translations={mockTranslations} submit={submitMock} idPre={idPre} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('SymptomsAssessment', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper({}, mockNewSymptoms, 'new');
    expect(wrapper.find(Card.Header).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).text()).toEqual(`${mockTranslations['en']['web']['title']} (AA-39)`);
    expect(wrapper.find(Card.Body).exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Row).at(0).text()).toEqual(mockTranslations['en']['web']['bool-title']);
    expect(wrapper.find(Card.Body).find(Form.Group).exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Form.Check).length).toEqual(17);
    expect(wrapper.find(Card.Body).find(Form.Control).length).toEqual(1);
    expect(wrapper.find(Card.Body).find(Button).exists()).toBeTruthy();
    expect(wrapper.find(Card.Body).find(Button).text()).toEqual(mockTranslations['en']['web']['submit']);
  });

  it('Properly renders symptom checkboxes when creating a new report', () => {
    const wrapper = getWrapper({}, mockNewSymptoms, 'new');
    const checkboxes = wrapper.find(Form.Check);
    checkboxes.forEach(cb => {
      expect(cb.prop('checked')).toBeFalsy();
      expect(cb.prop('disabled')).toBeFalsy();
    });
    expect(wrapper.find(Form.Control).prop('value')).toEqual('');
  });

  it('Properly renders checked bool symptoms when editing a report', () => {
    const wrapper = getWrapper(mockAssessment1, mockSymptoms1, '777');
    const boolSymptoms = mockSymptoms1.filter(x => { return x.type === 'BoolSymptom'; }).sort((a, b) => {return a?.name?.localeCompare(b?.name); });
    boolSymptoms.forEach(function(symp, index) {
      expect(wrapper.find(Form.Check).at(index).prop('checked')).toEqual(symp.value);
      expect(wrapper.find(Form.Check).at(index).prop('disabled')).toBeFalsy();
    });
    expect(wrapper.find(Form.Check).at(16).prop('checked')).toBeFalsy();
    expect(wrapper.find(Form.Check).at(16).prop('disabled')).toBeTruthy();
    expect(wrapper.find(Form.Control).prop('value')).toEqual('');
  });

  it('Properly renders float symptom values when editing a report', () => {
    const wrapper = getWrapper(mockAssessment2, mockSymptoms2, '777');
    const checkboxes = wrapper.find(Form.Check);
    checkboxes.forEach(cb => {
      expect(cb.prop('checked')).toBeFalsy();
      expect(cb.prop('disabled')).toBeFalsy();
    });
    expect(wrapper.find(Form.Control).prop('value')).toEqual(1);
  });

  it('Clicking "I am not experiencing any symptoms" disables all bool symptom checkboxes', () => {
    const wrapper = getWrapper({}, mockNewSymptoms, 'new');
    wrapper.find('#no-symptoms-check').simulate('change', { target: { value: true } });
    wrapper.find(Form.Check).forEach(cb => {
      if (cb.prop('id') === 'no-symptoms-check') {
        expect(cb.prop('checked')).toBeTruthy();
        expect(cb.prop('disabled')).toBeFalsy();
      } else {
        expect(cb.prop('checked')).toBeFalsy();
        expect(cb.prop('disabled')).toBeTruthy();
      }
    });
  });

  it('Clicking any bool symptom disables the "I am not experiencing any symptoms" checkbox', () => {
    const wrapper = getWrapper({}, mockNewSymptoms, 'new');
    const checkbox = wrapper.find(Form.Check).at(0);
    checkbox.simulate('change', { target: { id: checkbox.prop('id'), value: true } });
    wrapper.find(Form.Check).forEach(cb => {
      if (checkbox.prop('id') === cb.prop('id')) {
        expect(cb.prop('checked')).toBeTruthy();
        expect(cb.prop('disabled')).toBeFalsy();
      } else if (cb.prop('id') === 'no-symptoms-check') {
        expect(cb.prop('checked')).toBeFalsy();
        expect(cb.prop('disabled')).toBeTruthy();
      } else {
        expect(cb.prop('checked')).toBeFalsy();
        expect(cb.prop('disabled')).toBeFalsy();
      }
    });
  });

  it('Clicking "I am not experiencing any symptoms" updates state correctly', () => {
    const wrapper = getWrapper({}, mockNewSymptoms, 'new');
    wrapper.find('#no-symptoms-check').simulate('change', { target: { value: true } });
    expect(wrapper.state('noSymptomsCheckbox')).toBeTruthy();
    expect(wrapper.state('selectedBoolSymptomCount')).toEqual(0);
    wrapper.state('reportState').symptoms.forEach(symp => {
      if (symp.type === 'BoolSymptom') {
        expect(symp.value).toEqual(false);
      }
    });
  });

  it('Clicking any bool symptom updates state correctly', () => {
    const wrapper = getWrapper({}, mockNewSymptoms, 'new');
    const checkbox = wrapper.find(Form.Check).at(0);
    const checkboxId = checkbox.prop('id');
    checkbox.simulate('change', { target: { id: checkboxId, value: true } });
    expect(wrapper.state('noSymptomsCheckbox')).toBeFalsy();
    expect(wrapper.state('selectedBoolSymptomCount')).toEqual(1);
    wrapper.state('reportState').symptoms.forEach(symp => {
      if (symp.type === 'BoolSymptom') {
        expect(symp.value).toEqual(checkboxId.includes(symp.name));
      }
    });
  });

  it('Clicking the submit button calls and props.submit when creating a new report', () => {
    const wrapper = getWrapper({}, mockNewSymptoms, 'new');
    expect(submitMock).toHaveBeenCalledTimes(0);
    wrapper.find(Button).simulate('click');
    expect(submitMock).toHaveBeenCalled();
  });

  it('Clicking the submit button calls props.submit when editing a report with no new changes', () => {
    const wrapper = getWrapper(mockAssessment1, mockSymptoms1, '777');
    expect(submitMock).toHaveBeenCalledTimes(0);
    wrapper.find(Button).simulate('click');
    expect(submitMock).toHaveBeenCalled();
  });

  it('Clicking the submit button calls navigate but not submit when editing a report with no new changes', () => {
    const wrapper = getWrapper(mockAssessment1, mockSymptoms1, '777');
    const navigateSpy = jest.spyOn(wrapper.instance(), 'navigate');
    const handleSubmitSpy = jest.spyOn(wrapper.instance(), 'handleSubmit');
    const checkbox = wrapper.find(Form.Check).at(7);
    checkbox.simulate('change', { target: { id: checkbox.prop('id'), value: true } });

    expect(navigateSpy).toHaveBeenCalledTimes(0);
    expect(handleSubmitSpy).toHaveBeenCalledTimes(0);
    expect(submitMock).toHaveBeenCalledTimes(0);
    wrapper.find(Button).simulate('click');
    expect(navigateSpy).toHaveBeenCalled();
    expect(handleSubmitSpy).toHaveBeenCalled();
    expect(submitMock).toHaveBeenCalledTimes(0);
  });
});
