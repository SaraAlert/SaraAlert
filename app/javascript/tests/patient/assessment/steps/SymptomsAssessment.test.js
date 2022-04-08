import React from 'react';
import { shallow } from 'enzyme';
import { Button, Card, Form } from 'react-bootstrap';
import moment from 'moment';
import _ from 'lodash';
import ReactTooltip from 'react-tooltip';

import SymptomsAssessment from '../../../../components/patient/assessment/steps/SymptomsAssessment';
import DateInput from '../../../../components/util/DateInput';
import InfoTooltip from '../../../../components/util/InfoTooltip';
import { mockAssessment1 } from '../../../mocks/mockAssessments';
import { mockNewSymptoms, mockSymptoms1 } from '../../../mocks/mockSymptoms';
import { mockTranslations } from '../../../mocks/mockTranslations';
import { mockUser1 } from '../../../mocks/mockUsers';

const submitMock = jest.fn();
const newProps = {
  assessment: {},
  symptoms: mockNewSymptoms,
  idPre: 'new',
};
const editProps = {
  assessment: mockAssessment1,
  symptoms: mockSymptoms1,
  idPre: '777',
};

function getWrapper(props, additionalProps) {
  return shallow(<SymptomsAssessment {...props} patient_initials={'AA'} patient_age={39} lang={'eng'} translations={mockTranslations} submit={submitMock} {...additionalProps} />);
}

function getSymptomsByType(symptoms, type) {
  return _.clone(symptoms)
    .filter(x => {
      return x.type === type;
    })
    .sort((a, b) => {
      return a?.name?.localeCompare(b?.name);
    });
}

function getIntValue(intString) {
  return intString === '' ? null : parseInt(intString);
}

function getFloatValue(floatString) {
  return floatString === '' ? null : _.endsWith(floatString, '.') ? floatString : parseFloat(floatString).toFixed(_.includes(floatString, '.') ? floatString.split('.')[1].length : 0);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('SymptomsAssessment', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper(newProps);
    const boolSymptoms = getSymptomsByType(newProps.symptoms, 'BoolSymptom');
    const floatSymptoms = getSymptomsByType(newProps.symptoms, 'FloatSymptom');
    const intSymptoms = getSymptomsByType(newProps.symptoms, 'IntegerSymptom');
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual(`${mockTranslations['eng']['html']['weblink']['title']} (AA-39)`);
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find({ controlId: 'reported_at' }).exists()).toBe(false);
    expect(wrapper.find(Card.Body).find(Form.Row).at(0).text()).toEqual(mockTranslations['eng']['html']['weblink']['bool-title']);
    expect(wrapper.find(Card.Body).find(Form.Group).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Form.Check).length).toEqual(boolSymptoms.length + 1);
    expect(wrapper.find(Card.Body).find(Form.Control).length).toEqual(floatSymptoms.length + intSymptoms.length);
    expect(wrapper.find(Card.Body).find(Button).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(Button).prop('disabled')).toBe(false);
    expect(wrapper.find(Card.Body).find(Button).text()).toEqual(mockTranslations['eng']['html']['weblink']['submit']);
  });

  it('Properly renders "Reported At" date input when user editing assessment', () => {
    const wrapper = getWrapper(editProps, { current_user: mockUser1 });
    expect(wrapper.find({ controlId: 'reported_at' }).exists()).toBe(true);
    expect(wrapper.find({ controlId: 'reported_at' }).find(Form.Label).exists()).toBe(true);
    expect(wrapper.find({ controlId: 'reported_at' }).find(Form.Label).text()).toEqual('Symptom Report for Date:');
    expect(wrapper.find({ controlId: 'reported_at' }).find(DateInput).exists()).toBe(true);
    expect(wrapper.find({ controlId: 'reported_at' }).find(DateInput).prop('date')).toEqual(editProps.assessment.reported_at);
    expect(wrapper.find({ controlId: 'reported_at' }).find('.time-zone').exists()).toBe(true);
    expect(wrapper.find({ controlId: 'reported_at' }).find('.time-zone').text()).toEqual(moment.tz(moment.tz.guess()).format('z'));
    expect(wrapper.find({ controlId: 'reported_at' }).find(InfoTooltip).exists()).toBe(true);
    expect(wrapper.find({ controlId: 'reported_at' }).find(InfoTooltip).prop('tooltipTextKey')).toEqual('reportedAtTime');
  });

  it('Changing "Reported At" date properly updates state', () => {
    const wrapper = getWrapper(editProps, { current_user: mockUser1 });
    const newDate = moment().subtract(5, 'days').startOf('minute');
    expect(wrapper.state('reportState').reported_at).toEqual(moment(editProps.assessment.reported_at).format('YYYY-MM-DD HH:mm Z'));
    wrapper.find({ controlId: 'reported_at' }).find(DateInput).simulate('change', newDate);
    expect(wrapper.state('reportState').reported_at).toEqual(moment.utc(newDate).tz(moment.tz.guess()).format('YYYY-MM-DD HH:mm Z'));
  });

  it('Properly renders symptom inputs when creating a new report', () => {
    const wrapper = getWrapper(newProps);
    const boolSymptoms = getSymptomsByType(newProps.symptoms, 'BoolSymptom');
    const floatSymptoms = getSymptomsByType(newProps.symptoms, 'FloatSymptom');
    const intSymptoms = getSymptomsByType(newProps.symptoms, 'IntegerSymptom');

    boolSymptoms.forEach((symp, index) => {
      expect(wrapper.find(Form.Check).at(index).prop('checked')).toBe(false);
      expect(wrapper.find(Form.Check).at(index).prop('disabled')).toBe(false);
    });
    expect(wrapper.find(Form.Check).last().prop('checked')).toBe(false);
    expect(wrapper.find(Form.Check).last().prop('disabled')).toBe(false);

    intSymptoms.forEach((symp, index) => {
      expect(wrapper.find(Form.Control).at(index).prop('value')).toEqual('');
    });

    floatSymptoms.forEach((symp, index) => {
      expect(
        wrapper
          .find(Form.Control)
          .at(intSymptoms.length + index)
          .prop('value')
      ).toEqual('');
    });
  });

  it('Properly renders symptom inputs when editing a report', () => {
    const wrapper = getWrapper(editProps);
    const boolSymptoms = getSymptomsByType(editProps.symptoms, 'BoolSymptom');
    const floatSymptoms = getSymptomsByType(editProps.symptoms, 'FloatSymptom');
    const intSymptoms = getSymptomsByType(editProps.symptoms, 'IntegerSymptom');

    boolSymptoms.forEach((symp, index) => {
      expect(wrapper.find(Form.Check).at(index).prop('checked')).toEqual(symp.value);
      expect(wrapper.find(Form.Check).at(index).prop('disabled')).toBe(false);
    });
    expect(wrapper.find(Form.Check).last().prop('checked')).toBe(false);
    expect(wrapper.find(Form.Check).last().prop('disabled')).toBe(true);

    intSymptoms.forEach((symp, index) => {
      expect(wrapper.find(Form.Control).at(index).prop('value')).toEqual(symp.value);
    });

    floatSymptoms.forEach((symp, index) => {
      expect(
        wrapper
          .find(Form.Control)
          .at(intSymptoms.length + index)
          .prop('value')
      ).toEqual(symp.value);
    });
  });

  it('Clicking "I am not experiencing any symptoms" disables all bool symptom checkboxes', () => {
    const wrapper = getWrapper(newProps);
    const boolSymptoms = getSymptomsByType(newProps.symptoms, 'BoolSymptom');
    wrapper.find('#no-symptoms-check').simulate('change', { target: { value: true } });
    boolSymptoms.forEach((symp, index) => {
      expect(wrapper.find(Form.Check).at(index).prop('checked')).toEqual(false);
      expect(wrapper.find(Form.Check).at(index).prop('disabled')).toBe(true);
    });
    expect(wrapper.find(Form.Check).last().prop('checked')).toBe(true);
    expect(wrapper.find(Form.Check).last().prop('disabled')).toBe(false);
  });

  it('Clicking any bool symptom disables the "I am not experiencing any symptoms" checkbox', () => {
    const wrapper = getWrapper(newProps);
    const boolSymptoms = getSymptomsByType(newProps.symptoms, 'BoolSymptom');
    const randomBoolSymp = boolSymptoms[_.random(0, boolSymptoms.length - 1)];

    wrapper.find(`#${randomBoolSymp.name}_idpre${newProps.idPre}`).simulate('change', { target: { id: `${randomBoolSymp.name}_idpre${newProps.idPre}`, checked: true } });
    boolSymptoms.forEach((symp, index) => {
      expect(wrapper.find(Form.Check).at(index).prop('checked')).toEqual(symp.name === randomBoolSymp.name);
      expect(wrapper.find(Form.Check).at(index).prop('disabled')).toBe(false);
    });
    expect(wrapper.find(Form.Check).last().prop('checked')).toBe(false);
    expect(wrapper.find(Form.Check).last().prop('disabled')).toBe(true);
  });

  it('Clicking "I am not experiencing any symptoms" updates state correctly', () => {
    const wrapper = getWrapper(newProps);
    wrapper.find('#no-symptoms-check').simulate('change', { target: { value: true } });
    expect(wrapper.state('noSymptomsCheckbox')).toBe(true);
    expect(wrapper.state('selectedBoolSymptomCount')).toEqual(0);
    wrapper.state('reportState').symptoms.forEach(symp => {
      if (symp.type === 'BoolSymptom') {
        expect(symp.value).toBe(false);
      }
    });
  });

  it('Clicking any bool symptom checkbox updates state correctly', () => {
    const wrapper = getWrapper(newProps);
    let boolSymptoms = getSymptomsByType(editProps.symptoms, 'BoolSymptom');
    let selectedSymptoms = [];

    boolSymptoms.forEach((boolSymp, index) => {
      if (_.sample([true, false])) {
        selectedSymptoms.push(boolSymp.name);
        wrapper
          .find(Form.Check)
          .at(index)
          .simulate('change', { target: { id: `${boolSymp.name}_idpre${newProps.idPre}`, checked: true } });
      }
      expect(wrapper.state('noSymptomsCheckbox')).toBe(false);
      expect(wrapper.state('selectedBoolSymptomCount')).toEqual(selectedSymptoms.length);
      wrapper.state('reportState').symptoms.forEach(symp => {
        if (symp.type === 'BoolSymptom') {
          expect(symp.value).toBe(selectedSymptoms.includes(symp.name));
        }
      });
    });

    boolSymptoms = getSymptomsByType(wrapper.state('reportState').symptoms, 'BoolSymptom');
    boolSymptoms.forEach((boolSymp, index) => {
      if (_.sample([true, false])) {
        if (boolSymp.value) {
          selectedSymptoms = selectedSymptoms.filter(s => s !== boolSymp.name);
        } else {
          selectedSymptoms.push(boolSymp.name);
        }
        wrapper
          .find(Form.Check)
          .at(index)
          .simulate('change', { target: { id: `${boolSymp.name}_idpre${newProps.idPre}`, checked: !boolSymp.value } });
      }
      expect(wrapper.state('noSymptomsCheckbox')).toBe(false);
      expect(wrapper.state('selectedBoolSymptomCount')).toEqual(selectedSymptoms.length);
      wrapper.state('reportState').symptoms.forEach(symp => {
        if (symp.type === 'BoolSymptom') {
          expect(symp.value).toBe(selectedSymptoms.includes(symp.name));
        }
      });
    });
  });

  it('Prevents invalid values for IntegerSymptoms', () => {
    const wrapper = getWrapper(newProps);
    const intSymptoms = getSymptomsByType(newProps.symptoms, 'IntegerSymptom');
    const randomSympIndex = _.random(0, intSymptoms.length - 1);
    const matchingSympIndex = wrapper.state('reportState').symptoms.findIndex(s => s.name === intSymptoms[parseInt(randomSympIndex)].name);
    const validValues = ['', String(0), String(_.random(1, 1000)), String(_.random(-1000, -1))];
    const testValues = validValues.concat(String(_.random(0, 10, true)), String(_.random(-10, 0, true)), false, '45test', 'some string');

    let current = null;
    _.shuffle(testValues).forEach(value => {
      current = validValues.includes(value) ? getIntValue(value) : current;
      wrapper
        .find(Form.Control)
        .at(randomSympIndex)
        .simulate('change', { target: { id: `${intSymptoms[parseInt(randomSympIndex)].name}_idpre${newProps.idPre}`, value: value } });
      expect(wrapper.state('reportState').symptoms[parseInt(matchingSympIndex)].value).toEqual(current);
      expect(wrapper.find(Form.Control).at(randomSympIndex).prop('value')).toEqual(current || '');
    });
  });

  it('Prevents invalid values for FloatSymptoms', () => {
    const wrapper = getWrapper(newProps);
    const intSymptoms = getSymptomsByType(newProps.symptoms, 'IntegerSymptom');
    const floatSymptoms = getSymptomsByType(newProps.symptoms, 'FloatSymptom');
    const randomSympIndex = _.random(0, floatSymptoms.length - 1);
    const matchingSympIndex = wrapper.state('reportState').symptoms.findIndex(s => s.name === floatSymptoms[parseInt(randomSympIndex)].name);
    const validValues = ['', String(0), String(_.random(1, 1000)), String(_.random(-1000, -1)), String(_.random(0, 10, true)), String(_.random(-10, 0, true))];
    const testValues = validValues.concat(false, '45test', 'some string');

    let current = null;
    _.shuffle(testValues).forEach(value => {
      current = validValues.includes(value) ? getFloatValue(value) : current;
      wrapper
        .find(Form.Control)
        .at(intSymptoms.length + randomSympIndex)
        .simulate('change', { target: { id: `${floatSymptoms[parseInt(randomSympIndex)].name}_idpre${newProps.idPre}`, value: value } });
      expect(wrapper.state('reportState').symptoms[parseInt(matchingSympIndex)].value).toEqual(current);
      expect(
        wrapper
          .find(Form.Control)
          .at(intSymptoms.length + randomSympIndex)
          .prop('value')
      ).toEqual(current || '');
    });
  });

  it('Changing text integer and float symptom inputs updates state and value correctly', () => {
    const wrapper = getWrapper(newProps);
    const intSymptoms = getSymptomsByType(newProps.symptoms, 'IntegerSymptom');
    const floatSymptoms = getSymptomsByType(newProps.symptoms, 'FloatSymptom');
    const numberSymptoms = intSymptoms.concat(floatSymptoms);

    numberSymptoms.forEach((numSymp, n_index) => {
      if (_.sample([true, false])) {
        const random = numSymp.type === 'IntegerSymptom' ? String(_.random(-100000, 100000)) : String(_.random(-10, 10, true));
        wrapper
          .find(Form.Control)
          .at(n_index)
          .simulate('change', { target: { id: `${numSymp.name}_idpre${newProps.idPre}`, value: random } });
        numSymp.value = numSymp.type === 'IntegerSymptom' ? getIntValue(random) : getFloatValue(random);
      }
      wrapper
        .state('reportState')
        .symptoms.filter(s => s.type !== 'BoolSymptom')
        .forEach((symp, s_index) => {
          const matchingSymp = symp.type === 'IntegerSymptom' ? intSymptoms.find(s => s.name === symp.name) : floatSymptoms.find(s => s.name === symp.name);
          expect(symp.value).toEqual(matchingSymp.value);
          expect(wrapper.find(Form.Control).at(s_index).prop('value')).toEqual(matchingSymp.value || '');
        });
    });

    numberSymptoms.forEach((numSymp, n_index) => {
      if (_.sample([true, false])) {
        wrapper
          .find(Form.Control)
          .at(n_index)
          .simulate('change', { target: { id: `${numSymp.name}_idpre${newProps.idPre}`, value: '' } });
        numSymp.value = null;
      }
      wrapper
        .state('reportState')
        .symptoms.filter(s => s.type !== 'BoolSymptom')
        .forEach((symp, s_index) => {
          const matchingSymp = symp.type === 'IntegerSymptom' ? intSymptoms.find(s => s.name === symp.name) : floatSymptoms.find(s => s.name === symp.name);
          expect(symp.value).toEqual(matchingSymp.value);
          expect(wrapper.find(Form.Control).at(s_index).prop('value')).toEqual(matchingSymp.value || '');
        });
    });
  });

  it('Enables the submit button on edit when changes have been made', () => {
    const wrapper = getWrapper(editProps, { current_user: mockUser1 });
    const hasChangesSpy = jest.spyOn(wrapper.instance(), 'hasChanges');
    const boolSymptoms = getSymptomsByType(editProps.symptoms, 'BoolSymptom');
    const randomBoolSymp = boolSymptoms[_.random(0, boolSymptoms.length - 1)];
    expect(hasChangesSpy).not.toHaveBeenCalled();
    expect(wrapper.find(Button).prop('disabled')).toBe(true);

    wrapper.find(`#${randomBoolSymp.name}_idpre${editProps.idPre}`).simulate('change', { target: { id: `${randomBoolSymp.name}_idpre${editProps.idPre}`, checked: !randomBoolSymp.value } });
    expect(wrapper.find(Button).prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);
    expect(hasChangesSpy).toHaveBeenCalled();

    wrapper.find(`#${randomBoolSymp.name}_idpre${editProps.idPre}`).simulate('change', { target: { id: `${randomBoolSymp.name}_idpre${editProps.idPre}`, checked: randomBoolSymp.value } });
    expect(wrapper.find(Button).prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual('No updates to submit');
    expect(hasChangesSpy).toHaveBeenCalled();

    wrapper.find({ controlId: 'reported_at' }).find(DateInput).simulate('change', moment(editProps.assessment.reported_at).subtract(5, 'days'));
    expect(wrapper.find(Button).prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);
    expect(hasChangesSpy).toHaveBeenCalled();

    wrapper.find({ controlId: 'reported_at' }).find(DateInput).simulate('change', moment(editProps.assessment.reported_at));
    expect(wrapper.find(Button).prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual('No updates to submit');
    expect(hasChangesSpy).toHaveBeenCalled();
  });

  it('Clicking the submit button calls and props.submit when creating a new report', () => {
    const wrapper = getWrapper(newProps);
    expect(submitMock).not.toHaveBeenCalled();
    wrapper.find(Button).simulate('click');
    expect(submitMock).toHaveBeenCalled();
  });

  it('Clicking the submit button calls navigate but not submit when editing a report with new changes', () => {
    const wrapper = getWrapper(editProps);
    const navigateSpy = jest.spyOn(wrapper.instance(), 'navigate');
    const handleSubmitSpy = jest.spyOn(wrapper.instance(), 'handleSubmit');
    const boolSymptoms = getSymptomsByType(editProps.symptoms, 'BoolSymptom');
    const randomBoolSymp = boolSymptoms[_.random(0, boolSymptoms.length - 1)];
    wrapper.find(`#${randomBoolSymp.name}_idpre${editProps.idPre}`).simulate('change', { target: { id: `${randomBoolSymp.name}_idpre${editProps.idPre}`, checked: !randomBoolSymp.value } });

    expect(navigateSpy).not.toHaveBeenCalled();
    expect(handleSubmitSpy).not.toHaveBeenCalled();
    expect(submitMock).not.toHaveBeenCalled();
    wrapper.find(Button).simulate('click');
    expect(navigateSpy).toHaveBeenCalled();
    expect(handleSubmitSpy).toHaveBeenCalled();
    expect(submitMock).not.toHaveBeenCalled();
  });
});
