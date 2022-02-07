import React from 'react';
import { shallow } from 'enzyme';
import { Button } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import moment from 'moment';

import FirstPositiveLaboratory from '../../../components/patient/laboratory/FirstPositiveLaboratory';
import { mockLaboratory1 } from '../../mocks/mockLaboratories';

import LaboratoryModal from '../../../components/patient/laboratory/LaboratoryModal';

function getWrapper(additionalProps) {
  return shallow(<FirstPositiveLaboratory lab={mockLaboratory1} {...additionalProps} />);
}

describe('FirstPositiveLaboratory', () => {
  it('Properly renders a button to enter a lab result if lab is null', () => {
    const wrapper = getWrapper({ lab: null });
    expect(wrapper.find(Button).text()).toEqual('Enter Lab Result');
    expect(wrapper.find('#edit-first-positive-lab').exists()).toBe(false);
    expect(wrapper.find('#delete-first-positive-lab').exists()).toBe(false);
    expect(wrapper.find('.first-positive-lab-result-field-name').exists()).toBe(false);
  });

  it('Properly opens the laboratory modal when user clicks on the enter lab result button', () => {
    const wrapper = getWrapper({ lab: null });
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(LaboratoryModal).exists()).toBe(true);
  });

  it('Properly renders lab result details when lab is present', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(LaboratoryModal).exists()).toBe(false);
    expect(wrapper.find('#edit-first-positive-lab').exists()).toBe(true);
    expect(wrapper.find('#delete-first-positive-lab').exists()).toBe(true);
    expect(wrapper.find('#delete-first-positive-lab').prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);
    expect(wrapper.find('.first-positive-lab-result-field-name').length).toEqual(4);
    expect(wrapper.find('.first-positive-lab-result-field-value').length).toEqual(4);
    expect(wrapper.find('.first-positive-lab-result-field-name').at(0).text()).toEqual('Type: ');
    expect(wrapper.find('.first-positive-lab-result-field-value').at(0).text()).toEqual(mockLaboratory1.lab_type);
    expect(wrapper.find('.first-positive-lab-result-field-name').at(1).text()).toEqual('Specimen Collection Date: ');
    expect(wrapper.find('.first-positive-lab-result-field-value').at(1).text()).toEqual(moment(mockLaboratory1.specimen_collection).format('MM/DD/YYYY'));
    expect(wrapper.find('.first-positive-lab-result-field-name').at(2).text()).toEqual('Report Date: ');
    expect(wrapper.find('.first-positive-lab-result-field-value').at(2).text()).toEqual(moment(mockLaboratory1.report).format('MM/DD/YYYY'));
    expect(wrapper.find('.first-positive-lab-result-field-name').at(3).text()).toEqual('Result: ');
    expect(wrapper.find('.first-positive-lab-result-field-value').at(3).text()).toEqual(mockLaboratory1.result);
  });

  it('Properly opens LaboratoryModal when the edit button is clicked', () => {
    const wrapper = getWrapper();
    wrapper.find('#edit-first-positive-lab').simulate('click');
    expect(wrapper.find(LaboratoryModal).exists()).toBe(true);
  });

  it('Properly calls onChange with a null lab when the delete button is clicked', () => {
    const wrapper = getWrapper();
    const handleDeleteSpy = jest.spyOn(wrapper.instance(), 'handleDelete');
    wrapper.instance().forceUpdate();
    wrapper.find('#delete-first-positive-lab').simulate('click');
    expect(handleDeleteSpy).toHaveBeenCalled();
  });

  it('Disables the delete button when the preventDelete flag is set', () => {
    const wrapper = getWrapper({ preventDelete: true });
    expect(wrapper.find('#delete-first-positive-lab').prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual("Existing lab results must be deleted from the Lab Results table in the monitoree's record");
  });
});
