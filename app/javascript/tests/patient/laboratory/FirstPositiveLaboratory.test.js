import React from 'react';
import { shallow } from 'enzyme';
import { Button } from 'react-bootstrap';
import moment from 'moment';

import FirstPositiveLaboratory from '../../../components/patient/laboratory/FirstPositiveLaboratory';
import { mockLaboratory1 } from '../../mocks/mockLaboratories';

import LaboratoryModal from '../../../components/patient/laboratory/LaboratoryModal';

function getWrapper(lab) {
  return shallow(<FirstPositiveLaboratory lab={lab} />);
}

describe('FirstPositiveLaboratory', () => {
  it('Properly renders a button to enter a lab result if lab is null', () => {
    const wrapper = getWrapper(null);
    expect(wrapper.find(Button).text()).toEqual('Enter Lab Result');
    expect(wrapper.find('#edit-first_positive_lab').exists()).toBeFalsy();
    expect(wrapper.find('#delete-first_positive_lab').exists()).toBeFalsy();
    expect(wrapper.find('.first-positive-lab-result-field-name').exists()).toBeFalsy();
  });

  it('Properly opens the laboratory modal when user clicks on the enter lab result button', () => {
    const wrapper = getWrapper(null);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(LaboratoryModal).exists()).toBeTruthy();
  });

  it('Properly renders lab result details when lab is present', () => {
    const wrapper = getWrapper(mockLaboratory1);
    expect(wrapper.find(LaboratoryModal).exists()).toBeFalsy();
    expect(wrapper.find('#edit-first_positive_lab').exists()).toBeTruthy();
    expect(wrapper.find('#delete-first_positive_lab').exists()).toBeTruthy();
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
    const wrapper = getWrapper(mockLaboratory1);
    wrapper.find('#edit-first_positive_lab').simulate('click');
    expect(wrapper.find(LaboratoryModal).exists()).toBeTruthy();
  });

  it('Properly calls onChange with a null lab when the delete button is clicked', () => {
    const wrapper = getWrapper(mockLaboratory1);
    const handleDeleteSpy = jest.spyOn(wrapper.instance(), 'handleDelete');
    wrapper.instance().forceUpdate();
    wrapper.find('#delete-first_positive_lab').simulate('click');
    expect(handleDeleteSpy).toHaveBeenCalled();
  });
});
