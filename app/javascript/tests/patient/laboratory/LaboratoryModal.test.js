import React from 'react';
import { shallow } from 'enzyme';
import { Alert, Button, Form, Modal } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import _ from 'lodash';

import LaboratoryModal from '../../../components/patient/laboratory/LaboratoryModal';
import DateInput from '../../../components/util/DateInput';
import { mockLaboratoryBlank, mockLaboratory1 } from '../../mocks/mockLaboratories';

const onSaveMock = jest.fn();
const onCloseMock = jest.fn();
const LAB_TYPES = ['PCR', 'Antigen', 'Total Antibody', 'IgG Antibody', 'IgM Antibody', 'IgA Antibody', 'Other'];
const RESULTS = ['positive', 'negative', 'indeterminate', 'other'];
const INPUT_FIELDS = [
  { name: 'lab_type', label: 'Lab Test Type', type: 'select', options: LAB_TYPES },
  { name: 'specimen_collection', label: 'Specimen Collection Date', type: 'date' },
  { name: 'report', label: 'Report Date', type: 'date' },
  { name: 'result', label: 'Result', type: 'select', options: RESULTS },
];
let activeLab;

function getWrapper(editMode, additionalProps) {
  activeLab = editMode ? mockLaboratory1 : mockLaboratoryBlank;
  return shallow(<LaboratoryModal editMode={editMode} currentLabData={activeLab} onSave={onSaveMock} onClose={onCloseMock} {...additionalProps} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('LaboratoryModal', () => {
  it('Properly renders main components when adding new lab', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.find(Modal).exists()).toBe(true);
    expect(wrapper.find(Modal).find('h1').text()).toEqual('Add New Lab Result');
    expect(wrapper.find(Modal.Header).exists()).toBe(true);
    expect(wrapper.find(Modal.Title).text()).toEqual('Add New Lab Result');
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find(Form.Group).length).toEqual(INPUT_FIELDS.length);
    INPUT_FIELDS.forEach((field, fieldIndex) => {
      const input = wrapper.find(Modal.Body).find(Form.Group).at(fieldIndex);
      if (field.type === 'select') {
        expect(input.find(Form.Label).exists()).toBe(true);
        expect(input.find(Form.Label).text()).toContain(field.label);
        expect(input.find(Form.Control).exists()).toBe(true);
        field.options.forEach((option, optionIndex) => {
          expect(
            input
              .find(Form.Control)
              .find('option')
              .at(optionIndex + 1)
              .text()
          ).toEqual(option);
        });
        expect(input.find(Form.Control).prop('value')).toEqual('');
        expect(wrapper.state(field.name)).toEqual('');
      } else if (field.type === 'date') {
        expect(input.find(Form.Label).exists()).toBe(true);
        expect(input.find(Form.Label).text()).toContain(field.label);
        expect(input.find(DateInput).exists()).toBe(true);
        expect(input.find(DateInput).prop('date')).toBeNull();
        expect(wrapper.state(field.name)).toBeNull();
      }
    });
    expect(wrapper.find(Modal.Body).find('.symptom-onset-warning').exists()).toBe(false);
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Button).length).toEqual(2);
    expect(wrapper.find(Button).first().text()).toContain('Cancel');
    expect(wrapper.find(Button).last().text()).toContain('Create');
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual('Please enter at least one field.');
  });

  it('Properly renders main components when editing an existing lab', () => {
    const wrapper = getWrapper(true);
    expect(wrapper.find(Modal).exists()).toBe(true);
    expect(wrapper.find(Modal).find('h1').text()).toEqual('Edit Lab Result');
    expect(wrapper.find(Modal.Header).exists()).toBe(true);
    expect(wrapper.find(Modal.Title).text()).toEqual('Edit Lab Result');
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find(Form.Group).length).toEqual(INPUT_FIELDS.length);
    INPUT_FIELDS.forEach((field, fieldIndex) => {
      const input = wrapper.find(Modal.Body).find(Form.Group).at(fieldIndex);
      if (field.type === 'select') {
        expect(input.find(Form.Label).exists()).toBe(true);
        expect(input.find(Form.Label).text()).toContain(field.label);
        expect(input.find(Form.Control).exists()).toBe(true);
        field.options.forEach((option, optionIndex) => {
          expect(
            input
              .find(Form.Control)
              .find('option')
              .at(optionIndex + 1)
              .text()
          ).toEqual(option);
        });
        expect(input.find(Form.Control).prop('value')).toEqual(activeLab[field.name]);
        expect(wrapper.state(field.name)).toEqual(activeLab[field.name]);
      } else if (field.type === 'date') {
        expect(input.find(Form.Label).exists()).toBe(true);
        expect(input.find(Form.Label).text()).toContain(field.label);
        expect(input.find(DateInput).exists()).toBe(true);
        expect(input.find(DateInput).prop('date')).toEqual(activeLab[field.name]);
        expect(wrapper.state(field.name)).toEqual(activeLab[field.name]);
      }
    });
    expect(wrapper.find(Modal.Body).find('.symptom-onset-warning').exists()).toBe(false);
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Button).length).toEqual(2);
    expect(wrapper.find(Button).first().text()).toContain('Cancel');
    expect(wrapper.find(Button).last().text()).toContain('Update');
    expect(wrapper.find(Button).last().prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);
  });

  it('Changing "Lab Test Type" properly updates state and enables/disables the submit button', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.state('lab_type')).toEqual('');
    expect(wrapper.find({ controlId: 'lab_type' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'lab_type' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'lab_type', value: mockLaboratory1.lab_type } });
    expect(wrapper.state('lab_type')).toEqual(mockLaboratory1.lab_type);
    expect(wrapper.find({ controlId: 'lab_type' }).find(Form.Control).prop('value')).toEqual(mockLaboratory1.lab_type);
    expect(wrapper.find(Button).last().prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);

    wrapper
      .find({ controlId: 'lab_type' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'lab_type', value: '' } });
    expect(wrapper.state('lab_type')).toEqual('');
    expect(wrapper.find({ controlId: 'lab_type' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
  });

  it('Changing "Specimen Collection" properly updates state and enables/disables the submit button', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.state('specimen_collection')).toBeNull();
    expect(wrapper.find('#specimen_collection').prop('date')).toBeNull();
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper.find('#specimen_collection').simulate('change', mockLaboratory1.specimen_collection);
    expect(wrapper.state('specimen_collection')).toEqual(mockLaboratory1.specimen_collection);
    expect(wrapper.find('#specimen_collection').prop('date')).toEqual(mockLaboratory1.specimen_collection);
    expect(wrapper.find(Button).last().prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);

    wrapper.find('#specimen_collection').simulate('change', null);
    expect(wrapper.state('specimen_collection')).toBeNull();
    expect(wrapper.find('#specimen_collection').prop('date')).toBeNull();
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
  });

  it('Changing "Report" properly updates state and enables/disables the submit button', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.state('report')).toBeNull();
    expect(wrapper.find('#report').prop('date')).toBeNull();
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper.find('#report').simulate('change', mockLaboratory1.report);
    expect(wrapper.state('report')).toEqual(mockLaboratory1.report);
    expect(wrapper.find('#report').prop('date')).toEqual(mockLaboratory1.report);
    expect(wrapper.find(Button).last().prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);

    wrapper.find('#report').simulate('change', null);
    expect(wrapper.state('report')).toBeNull();
    expect(wrapper.find('#report').prop('date')).toBeNull();
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
  });

  it('Changing "Result" properly updates state and enables/disables the submit button', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.state('result')).toEqual('');
    expect(wrapper.find({ controlId: 'result' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'result' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'result', value: mockLaboratory1.result } });
    expect(wrapper.state('result')).toEqual(mockLaboratory1.result);
    expect(wrapper.find({ controlId: 'result' }).find(Form.Control).prop('value')).toEqual(mockLaboratory1.result);
    expect(wrapper.find(Button).last().prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);

    wrapper
      .find({ controlId: 'result' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'result', value: '' } });
    expect(wrapper.state('result')).toEqual('');
    expect(wrapper.find({ controlId: 'result' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
  });

  it('Setting "Result" before "Specimen Collection" prevents submission', done => {
    const wrapper = getWrapper(false);
    wrapper.find('#specimen_collection').simulate('change', '2022-01-04');
    wrapper.find('#report').simulate('change', '2022-01-01');
    expect(wrapper.state('errors')).toEqual({});
    expect(onSaveMock).not.toHaveBeenCalled();

    wrapper.find(Button).last().simulate('click');
    setTimeout(() => {
      // the submit method calls the schema.validate which is an async method
      // as a result, a timeout is necessary for validate to finish and the callback to be hit
      expect(wrapper.state('errors')).toEqual({ report: ['Report Date cannot be before Specimen Collection Date.'] });
      expect(onSaveMock).not.toHaveBeenCalled();
      done();
    }, 1000);
  });

  it('Changing inputs calls updateValidations and clearSymptomOnset', done => {
    const wrapper = getWrapper(false);
    const updateValidationsSpy = jest.spyOn(wrapper.instance(), 'updateValidations');
    const clearSymptomOnsetSpy = jest.spyOn(wrapper.instance(), 'clearSymptomOnset');
    wrapper.instance().forceUpdate();
    expect(updateValidationsSpy).not.toHaveBeenCalled();
    expect(clearSymptomOnsetSpy).not.toHaveBeenCalled();

    _.shuffle(INPUT_FIELDS).forEach((field, index) => {
      // additional set timeout neccessary to handle setTimeout within a loop
      setTimeout(() => {
        if (field.type === 'select') {
          wrapper
            .find({ controlId: field.name })
            .find(Form.Control)
            .simulate('change', { target: { id: field.name, value: mockLaboratory1[field.name] } });
        } else if (field.type === 'date') {
          wrapper.find(`#${field.name}`).simulate('change', mockLaboratory1[field.name]);
        }
        setTimeout(() => {
          // the handleChange methods call these methods in the setState callback
          // as a result, a timeout is necessary for the callback to be hit
          expect(updateValidationsSpy).toHaveBeenCalledTimes(index + 1);
          expect(clearSymptomOnsetSpy).toHaveBeenCalledTimes(index + 1);
          if (index === INPUT_FIELDS.length - 1) done();
        }, 500);
      }, 1000 * index);
    });
  });

  it('Properly renders results dropdown if props.firstPositiveLab', () => {
    const wrapper = getWrapper(false, { firstPositiveLab: true });
    expect(wrapper.state('result')).toEqual('positive');
    expect(wrapper.find({ controlId: 'result' }).find(Form.Control).prop('value')).toEqual('positive');
    expect(wrapper.find({ controlId: 'result' }).find(Form.Control).prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual('Please enter Specimen Collection Date.');
  });

  it('Changing "Specimen Collection" enables/disables the submit button when props.firstPositiveLab', () => {
    const wrapper = getWrapper(false, { firstPositiveLab: true });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    // Set values in each input randomly
    let foundSpecimenCollection = false;
    _.shuffle(INPUT_FIELDS).forEach(field => {
      if (field.name === 'specimen_collection') {
        foundSpecimenCollection = true;
      }
      if (field.type === 'select') {
        if (!wrapper.find({ controlId: field.name }).find(Form.Control).prop('disabled')) {
          wrapper
            .find({ controlId: field.name })
            .find(Form.Control)
            .simulate('change', { target: { id: field.name, value: mockLaboratory1[field.name] } });
          expect(wrapper.find(Button).last().prop('disabled')).toBe(!foundSpecimenCollection);
          expect(wrapper.find(ReactTooltip).exists()).toBe(!foundSpecimenCollection);
        }
      } else if (field.type === 'date') {
        wrapper.find(`#${field.name}`).simulate('change', mockLaboratory1[field.name]);
        expect(wrapper.find(Button).last().prop('disabled')).toBe(!foundSpecimenCollection);
        expect(wrapper.find(ReactTooltip).exists()).toBe(!foundSpecimenCollection);
      }
    });

    // Clear values in each input randomly
    foundSpecimenCollection = false;
    _.shuffle(INPUT_FIELDS).forEach(field => {
      if (field.name === 'specimen_collection') {
        foundSpecimenCollection = true;
      }
      if (field.type === 'select') {
        if (!wrapper.find({ controlId: field.name }).find(Form.Control).prop('disabled')) {
          wrapper
            .find({ controlId: field.name })
            .find(Form.Control)
            .simulate('change', { target: { id: field.name, value: '' } });
          expect(wrapper.find(Button).last().prop('disabled')).toBe(foundSpecimenCollection);
          expect(wrapper.find(ReactTooltip).exists()).toBe(foundSpecimenCollection);
        }
      } else if (field.type === 'date') {
        wrapper.find(`#${field.name}`).simulate('change', null);
        expect(wrapper.find(Button).last().prop('disabled')).toBe(foundSpecimenCollection);
        expect(wrapper.find(ReactTooltip).exists()).toBe(foundSpecimenCollection);
      }
    });
  });

  it('Properly renders Symptom Onset warning', () => {
    const wrapper = getWrapper(true, { isolation: true, only_positive_lab: true });
    expect(wrapper.find('.symptom-onset-warning').exists()).toBe(false);
    wrapper
      .find({ controlId: 'result' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'result', value: 'negative' } });
    expect(wrapper.find('.symptom-onset-warning').exists()).toBe(true);
    expect(wrapper.find('.symptom-onset-warning').find(Alert).exists()).toBe(true);
    expect(wrapper.find('.symptom-onset-warning').find(Alert).text()).toEqual('Warning: Since this record does not have a Symptom Onset Date, updating this lab from a positive result or clearing the Specimen Collection Date may result in the record not ever being eligible to appear on the Records Requiring Review line list. Please consider undoing these changes or entering a Symptom Onset Date:');
    expect(wrapper.find('.symptom-onset-warning').find(Form.Label).exists()).toBe(true);
    expect(wrapper.find('.symptom-onset-warning').find(Form.Label).text()).toEqual('Symptom Onset');
    expect(wrapper.find('.symptom-onset-warning').find(DateInput).exists()).toBe(true);
    wrapper
      .find({ controlId: 'result' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'result', value: 'positive' } });
    expect(wrapper.find('.symptom-onset-warning').exists()).toBe(false);
  });

  it('Changing Symptom Onset date properly updates state', () => {
    const wrapper = getWrapper(true, { isolation: true, only_positive_lab: true });
    expect(wrapper.state('specimen_collection')).toEqual(activeLab.specimen_collection);
    expect(wrapper.find('#specimen_collection').prop('date')).toEqual(activeLab.specimen_collection);
    expect(wrapper.state('result')).toEqual(activeLab.result);
    expect(wrapper.find({ controlId: 'result' }).find(Form.Control).prop('value')).toEqual(activeLab.result);
    expect(wrapper.state('symptom_onset')).toBeNull();

    wrapper
      .find({ controlId: 'result' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'result', value: 'negative' } });
    expect(wrapper.state('specimen_collection')).toEqual(activeLab.specimen_collection);
    expect(wrapper.find('#specimen_collection').prop('date')).toEqual(activeLab.specimen_collection);
    expect(wrapper.state('result')).toEqual('negative');
    expect(wrapper.find({ controlId: 'result' }).find(Form.Control).prop('value')).toEqual('negative');
    expect(wrapper.state('symptom_onset')).toBeNull();
    expect(wrapper.find('#symptom_onset_lab').prop('date')).toBeNull();

    wrapper.find('#symptom_onset_lab').simulate('change', '2022-01-02');
    expect(wrapper.state('specimen_collection')).toEqual(activeLab.specimen_collection);
    expect(wrapper.find('#specimen_collection').prop('date')).toEqual(activeLab.specimen_collection);
    expect(wrapper.state('result')).toEqual('negative');
    expect(wrapper.find({ controlId: 'result' }).find(Form.Control).prop('value')).toEqual('negative');
    expect(wrapper.state('symptom_onset')).toEqual('2022-01-02');
    expect(wrapper.find('#symptom_onset_lab').prop('date')).toEqual('2022-01-02');

    wrapper.find('#specimen_collection').simulate('change', null);
    expect(wrapper.state('specimen_collection')).toBeNull();
    expect(wrapper.find('#specimen_collection').prop('date')).toBeNull();
    expect(wrapper.state('result')).toEqual('negative');
    expect(wrapper.find({ controlId: 'result' }).find(Form.Control).prop('value')).toEqual('negative');
    expect(wrapper.state('symptom_onset')).toEqual('2022-01-02');
    expect(wrapper.find('#symptom_onset_lab').prop('date')).toEqual('2022-01-02');

    wrapper
      .find({ controlId: 'result' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'result', value: 'positive' } });
    expect(wrapper.state('specimen_collection')).toBeNull();
    expect(wrapper.find('#specimen_collection').prop('date')).toBeNull();
    expect(wrapper.state('result')).toEqual('positive');
    expect(wrapper.find({ controlId: 'result' }).find(Form.Control).prop('value')).toEqual('positive');
    expect(wrapper.state('symptom_onset')).toEqual('2022-01-02');
    expect(wrapper.find('#symptom_onset_lab').prop('date')).toEqual('2022-01-02');

    wrapper.find('#specimen_collection').simulate('change', activeLab.specimen_collection);
    expect(wrapper.state('specimen_collection')).toEqual(activeLab.specimen_collection);
    expect(wrapper.find('#specimen_collection').prop('date')).toEqual(activeLab.specimen_collection);
    expect(wrapper.state('result')).toEqual('positive');
    expect(wrapper.find({ controlId: 'result' }).find(Form.Control).prop('value')).toEqual('positive');
    expect(wrapper.state('symptom_onset')).toBeNull();
  });

  it('Clicking the cancel button calls props.onClose', () => {
    const wrapper = getWrapper(false);
    expect(onCloseMock).not.toHaveBeenCalled();
    wrapper.find(Button).first().simulate('click');
    expect(onCloseMock).toHaveBeenCalled();
  });

  it('Clicking the submit button calls props.onSave and disables the button', done => {
    const wrapper = getWrapper(false);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.instance().forceUpdate();
    expect(submitSpy).not.toHaveBeenCalled();
    expect(onSaveMock).not.toHaveBeenCalled();
    expect(wrapper.state('loading')).toBe(false);
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);

    wrapper
      .find({ controlId: 'lab_type' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'lab_type', value: mockLaboratory1.lab_type } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(false);

    wrapper.find(Button).last().simulate('click');
    expect(submitSpy).toHaveBeenCalled();
    setTimeout(() => {
      // the submit method calls the schema.validate which is an async method
      // as a result, a timeout is necessary for validate to finish and the callback to be hit
      let lab = { lab_type: mockLaboratory1.lab_type, report: null, result: '', specimen_collection: null };
      expect(onSaveMock).toHaveBeenCalledWith(lab, null);
      expect(wrapper.state('loading')).toBe(true);
      expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
      done();
    }, 500);
  });
});
