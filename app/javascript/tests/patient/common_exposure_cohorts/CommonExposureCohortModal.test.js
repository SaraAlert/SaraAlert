import React from 'react';
import { shallow } from 'enzyme';
import { Form } from 'react-bootstrap';

import CommonExposureCohortModal from '../../../components/patient/common_exposure_cohorts/CommonExposureCohortModal';

import { mockCommonExposureCohort2 } from '../../mocks/mockCommonExposureCohorts';

const index = 0;
const cohort_names = ['a', 'b', 'c'];
const cohort_locations = ['d', 'e', 'f'];

const onChangeMock = jest.fn();
const onHideMock = jest.fn();

function getWrapper() {
  return shallow(<CommonExposureCohortModal common_exposure_cohort={mockCommonExposureCohort2} common_exposure_cohort_index={index} cohort_names={cohort_names} cohort_locations={cohort_locations} onChange={onChangeMock} onHide={onHideMock} />);
}

describe('CommonExposureCohortsTable', () => {
  it('Properly renders the modal with populated cohort fields', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Form.Control).at(0).prop('value')).toEqual(mockCommonExposureCohort2.cohort_type);
    expect(wrapper.find(Form.Control).at(1).prop('value')).toEqual(mockCommonExposureCohort2.cohort_name);
    expect(wrapper.find(Form.Control).at(2).prop('value')).toEqual(mockCommonExposureCohort2.cohort_location);
  });

  it('Clicking "cancel" calls the onHide method', () => {
    const wrapper = getWrapper(true);
    wrapper.find('#cohort-modal-cancel-button').simulate('click');
    expect(onHideMock).toHaveBeenCalled();
  });

  it('Clicking "save" calls the onChange method with cohort and correct index', () => {
    const wrapper = getWrapper(true);
    wrapper.find('#cohort-modal-save-button').simulate('click');
    expect(onChangeMock).toHaveBeenCalledWith(mockCommonExposureCohort2, index);
  });
});
