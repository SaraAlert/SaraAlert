import React from 'react';
import { shallow } from 'enzyme';
import { Button, Card, Form } from 'react-bootstrap';
import SymptomsAssessment from '../../../../components/patient/assessment/steps/SymptomsAssessment';
import { mockAssessment1, mockAssessment2 } from '../../../mocks/mockAssessments';
import { mockNewSymptoms, mockSymptoms1, mockSymptoms2 } from '../../../mocks/mockSymptoms';
import { mockTranslations } from '../../../mocks/mockTranslations';
import { mockUser1 } from '../../../mocks/mockUsers';

const submitMock = jest.fn();

function getWrapper(assessment, symptoms, idPre, user = null) {
  return shallow(<SymptomsAssessment assessment={assessment} symptoms={symptoms} patient_initials={'AA'} patient_age={39} lang={'eng'} translations={mockTranslations} submit={submitMock} idPre={idPre} current_user={user} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('SymptomsAssessment', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper({}, mockNewSymptoms, 'new');
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual(`${mockTranslations['eng']['html']['weblink']['title']} (AA-39)`);
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Row).at(0).text()).toEqual(mockTranslations['eng']['html']['weblink']['bool-title']);
    expect(wrapper.find(Card.Body).find(Form.Group).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Check).length).toEqual(17);
    expect(wrapper.find(Card.Body).find(Form.Control).length).toEqual(2);
    expect(wrapper.find(Card.Body).find(Button).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Button).text()).toEqual(mockTranslations['eng']['html']['weblink']['submit']);
  });

  it('Properly renders symptom checkboxes when creating a new report', () => {
    const wrapper = getWrapper({}, mockNewSymptoms, 'new');
    const checkboxes = wrapper.find(Form.Check);
    checkboxes.forEach(cb => {
      expect(cb.prop('checked')).toBe(false);
      expect(cb.prop('disabled')).toBe(false);
    });
    const formControls = wrapper.find(Form.Control);
    formControls.forEach(fc => {
      expect(fc.prop('value')).toEqual('');
    });
  });

  it('Properly renders checked bool symptoms when editing a report', () => {
    const wrapper = getWrapper(mockAssessment1, mockSymptoms1, '777');
    const boolSymptoms = mockSymptoms1
      .filter(x => {
        return x.type === 'BoolSymptom';
      })
      .sort((a, b) => {
        return a?.name?.localeCompare(b?.name);
      });
    boolSymptoms.forEach((symp, index) => {
      expect(wrapper.find(Form.Check).at(index).prop('checked')).toEqual(symp.value);
      expect(wrapper.find(Form.Check).at(index).prop('disabled')).toBe(false);
    });
    expect(wrapper.find(Form.Check).at(16).prop('checked')).toBe(false);
    expect(wrapper.find(Form.Check).at(16).prop('disabled')).toBe(true);
    const formControls = wrapper.find(Form.Control);
    formControls.forEach(fc => {
      expect(fc.prop('value')).toEqual('');
    });
  });

  it('Properly renders float & integer symptom values when editing a report', () => {
    const wrapper = getWrapper(mockAssessment2, mockSymptoms2, '777');
    const checkboxes = wrapper.find(Form.Check);
    checkboxes.forEach(cb => {
      expect(cb.prop('checked')).toBe(false);
      expect(cb.prop('disabled')).toBe(false);
    });
    const formControls = wrapper.find(Form.Control);
    expect(formControls.at(0).prop('value')).toEqual(5);
    expect(formControls.at(1).prop('value')).toEqual(1);
  });

  it('Properly renders Reported At date input when user editing assessment', () => {
    const wrapper = getWrapper(mockAssessment1, mockSymptoms1, '777', mockUser1);
    expect(wrapper.find('#reported_at').exists()).toBe(true);
  });

  it('Does not render Reported At date input when monitoree assessment', () => {
    const wrapper = getWrapper(mockAssessment1, mockSymptoms1, '777');
    expect(wrapper.find('#reported_at').exists()).toBe(false);
  });

  it('Clicking "I am not experiencing any symptoms" disables all bool symptom checkboxes', () => {
    const wrapper = getWrapper({}, mockNewSymptoms, 'new');
    wrapper.find('#no-symptoms-check').simulate('change', { target: { value: true } });
    wrapper.find(Form.Check).forEach(cb => {
      if (cb.prop('id') === 'no-symptoms-check') {
        expect(cb.prop('checked')).toBe(true);
        expect(cb.prop('disabled')).toBe(false);
      } else {
        expect(cb.prop('checked')).toBe(false);
        expect(cb.prop('disabled')).toBe(true);
      }
    });
  });

  it('Clicking any bool symptom disables the "I am not experiencing any symptoms" checkbox', () => {
    const wrapper = getWrapper({}, mockNewSymptoms, 'new');
    const checkbox = wrapper.find(Form.Check).at(0);
    checkbox.simulate('change', { target: { id: checkbox.prop('id'), checked: true } });
    wrapper.find(Form.Check).forEach(cb => {
      if (checkbox.prop('id') === cb.prop('id')) {
        expect(cb.prop('checked')).toBe(true);
        expect(cb.prop('disabled')).toBe(false);
      } else if (cb.prop('id') === 'no-symptoms-check') {
        expect(cb.prop('checked')).toBe(false);
        expect(cb.prop('disabled')).toBe(true);
      } else {
        expect(cb.prop('checked')).toBe(false);
        expect(cb.prop('disabled')).toBe(false);
      }
    });
  });

  it('Clicking "I am not experiencing any symptoms" updates state correctly', () => {
    const wrapper = getWrapper({}, mockNewSymptoms, 'new');
    wrapper.find('#no-symptoms-check').simulate('change', { target: { value: true } });
    expect(wrapper.state('noSymptomsCheckbox')).toBe(true);
    expect(wrapper.state('selectedBoolSymptomCount')).toEqual(0);
    wrapper.state('reportState').symptoms.forEach(symp => {
      if (symp.type === 'BoolSymptom') {
        expect(symp.value).toBe(false);
      }
    });
  });

  it('Clicking any bool symptom updates state correctly', () => {
    const wrapper = getWrapper({}, mockNewSymptoms, 'new');
    const checkbox = wrapper.find(Form.Check).at(0);
    const checkboxId = checkbox.prop('id');
    checkbox.simulate('change', { target: { id: checkboxId, checked: true } });
    expect(wrapper.state('noSymptomsCheckbox')).toBe(false);
    expect(wrapper.state('selectedBoolSymptomCount')).toEqual(1);
    wrapper.state('reportState').symptoms.forEach(symp => {
      if (symp.type === 'BoolSymptom') {
        expect(symp.value).toEqual(checkboxId.includes(symp.name));
      }
    });
  });

  it('Clicking the submit button calls and props.submit when creating a new report', () => {
    const wrapper = getWrapper({}, mockNewSymptoms, 'new');
    expect(submitMock).not.toHaveBeenCalled();
    wrapper.find(Button).simulate('click');
    expect(submitMock).toHaveBeenCalled();
  });

  it('Clicking the submit button calls props.submit when editing a report with no new changes', () => {
    const wrapper = getWrapper(mockAssessment1, mockSymptoms1, '777');
    expect(submitMock).not.toHaveBeenCalled();
    wrapper.find(Button).simulate('click');
    expect(submitMock).toHaveBeenCalled();
  });

  it('Clicking the submit button calls navigate but not submit when editing a report with no new changes', () => {
    const wrapper = getWrapper(mockAssessment1, mockSymptoms1, '777');
    const navigateSpy = jest.spyOn(wrapper.instance(), 'navigate');
    const handleSubmitSpy = jest.spyOn(wrapper.instance(), 'handleSubmit');
    const checkbox = wrapper.find(Form.Check).at(7);
    checkbox.simulate('change', { target: { id: checkbox.prop('id'), checked: true } });

    expect(navigateSpy).not.toHaveBeenCalled();
    expect(handleSubmitSpy).not.toHaveBeenCalled();
    expect(submitMock).not.toHaveBeenCalled();
    wrapper.find(Button).simulate('click');
    expect(navigateSpy).toHaveBeenCalled();
    expect(handleSubmitSpy).toHaveBeenCalled();
    expect(submitMock).not.toHaveBeenCalled();
  });
});
