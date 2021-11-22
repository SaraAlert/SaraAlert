import React from 'react';
import { shallow } from 'enzyme';
import { Button, Form, Modal } from 'react-bootstrap';
import CommonExposureCohortModal from '../../../components/patient/common_exposure_cohorts/CommonExposureCohortModal';
import { mockCommonExposureCohort2 } from '../../mocks/mockCommonExposureCohorts';

const index = 0;
const cohort_names = ['a', 'b', 'c'];
const cohort_locations = ['d', 'e', 'f'];
const onChangeMock = jest.fn();
const onHideMock = jest.fn();

function getWrapper(cohort) {
  return shallow(<CommonExposureCohortModal common_exposure_cohort={cohort} common_exposure_cohort_index={index} cohort_names={cohort_names} cohort_locations={cohort_locations} onChange={onChangeMock} onHide={onHideMock} />);
}

describe('CommonExposureCohortsTable', () => {
  it('Properly renders main modal components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBe(true);
    expect(wrapper.find(Modal.Header).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
  });

  it('Properly renders the modal with populated empty', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal.Title).text()).toEqual('Add Common Exposure Cohort');
    expect(wrapper.find({ controlId: 'cohort_type' }).exists()).toBe(true);
    expect(wrapper.find({ controlId: 'cohort_type' }).find(Form.Label).text()).toEqual('Cohort Type');
    expect(wrapper.find({ controlId: 'cohort_type' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.find({ controlId: 'cohort_name' }).exists()).toBe(true);
    expect(wrapper.find({ controlId: 'cohort_name' }).find(Form.Label).text()).toEqual('Cohort Name/Description');
    expect(wrapper.find({ controlId: 'cohort_name' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.find({ controlId: 'cohort_location' }).exists()).toBe(true);
    expect(wrapper.find({ controlId: 'cohort_location' }).find(Form.Label).text()).toEqual('Cohort Location');
    expect(wrapper.find({ controlId: 'cohort_location' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.find('#cohort-modal-cancel-button').text()).toEqual('Cancel');
    expect(wrapper.find('#cohort-modal-save-button').text()).toEqual('Save');
    expect(wrapper.find('#cohort-modal-save-button').prop('disabled')).toEqual(true);
  });

  it('Properly renders the modal with populated cohort fields', () => {
    const wrapper = getWrapper(mockCommonExposureCohort2);
    expect(wrapper.find(Modal.Title).text()).toEqual('Update Common Exposure Cohort');
    expect(wrapper.find({ controlId: 'cohort_type' }).exists()).toBe(true);
    expect(wrapper.find({ controlId: 'cohort_type' }).find(Form.Label).text()).toEqual('Cohort Type');
    expect(wrapper.find({ controlId: 'cohort_type' }).find(Form.Control).prop('value')).toEqual(mockCommonExposureCohort2.cohort_type);
    expect(wrapper.find({ controlId: 'cohort_name' }).exists()).toBe(true);
    expect(wrapper.find({ controlId: 'cohort_name' }).find(Form.Label).text()).toEqual('Cohort Name/Description');
    expect(wrapper.find({ controlId: 'cohort_name' }).find(Form.Control).prop('value')).toEqual(mockCommonExposureCohort2.cohort_name);
    expect(wrapper.find({ controlId: 'cohort_location' }).exists()).toBe(true);
    expect(wrapper.find({ controlId: 'cohort_location' }).find(Form.Label).text()).toEqual('Cohort Location');
    expect(wrapper.find({ controlId: 'cohort_location' }).find(Form.Control).prop('value')).toEqual(mockCommonExposureCohort2.cohort_location);
    expect(wrapper.find('#cohort-modal-cancel-button').text()).toEqual('Cancel');
    expect(wrapper.find('#cohort-modal-save-button').text()).toEqual('Update');
    expect(wrapper.find('#cohort-modal-save-button').prop('disabled')).toEqual(false);
  });

  it('Changing cohort type dropdown updates state and disable/enables the submit button', () => {
    const wrapper = getWrapper();
    expect(wrapper.find({ controlId: 'cohort_type' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.state('common_exposure_cohort')).toEqual({});
    expect(wrapper.find('#cohort-modal-save-button').prop('disabled')).toEqual(true);

    wrapper
      .find({ controlId: 'cohort_type' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cohort_type', value: 'abc' }, persist: jest.fn() });
    expect(wrapper.find({ controlId: 'cohort_type' }).find(Form.Control).prop('value')).toEqual('abc');
    expect(wrapper.state('common_exposure_cohort').cohort_type).toEqual('abc');
    expect(wrapper.find('#cohort-modal-save-button').prop('disabled')).toEqual(false);

    wrapper
      .find({ controlId: 'cohort_type' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cohort_type', value: '' }, persist: jest.fn() });
    expect(wrapper.find({ controlId: 'cohort_type' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.state('common_exposure_cohort').cohort_type).toEqual('');
    expect(wrapper.find('#cohort-modal-save-button').prop('disabled')).toEqual(true);
  });

  it('Changing cohort name dropdown updates state and disable/enables the submit button', () => {
    const wrapper = getWrapper();
    expect(wrapper.find({ controlId: 'cohort_name' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.state('common_exposure_cohort')).toEqual({});
    expect(wrapper.find('#cohort-modal-save-button').prop('disabled')).toEqual(true);

    wrapper
      .find({ controlId: 'cohort_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cohort_name', value: 'abc' }, persist: jest.fn() });
    expect(wrapper.find({ controlId: 'cohort_name' }).find(Form.Control).prop('value')).toEqual('abc');
    expect(wrapper.state('common_exposure_cohort').cohort_name).toEqual('abc');
    expect(wrapper.find('#cohort-modal-save-button').prop('disabled')).toEqual(false);

    wrapper
      .find({ controlId: 'cohort_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cohort_name', value: '' }, persist: jest.fn() });
    expect(wrapper.find({ controlId: 'cohort_name' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.state('common_exposure_cohort').cohort_name).toEqual('');
    expect(wrapper.find('#cohort-modal-save-button').prop('disabled')).toEqual(true);
  });

  it('Changing cohort location dropdown updates state and disable/enables the submit button', () => {
    const wrapper = getWrapper();
    expect(wrapper.find({ controlId: 'cohort_location' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.state('common_exposure_cohort')).toEqual({});
    expect(wrapper.find('#cohort-modal-save-button').prop('disabled')).toEqual(true);

    wrapper
      .find({ controlId: 'cohort_location' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cohort_location', value: 'abc' }, persist: jest.fn() });
    expect(wrapper.find({ controlId: 'cohort_location' }).find(Form.Control).prop('value')).toEqual('abc');
    expect(wrapper.state('common_exposure_cohort').cohort_location).toEqual('abc');
    expect(wrapper.find('#cohort-modal-save-button').prop('disabled')).toEqual(false);

    wrapper
      .find({ controlId: 'cohort_location' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cohort_location', value: '' }, persist: jest.fn() });
    expect(wrapper.find({ controlId: 'cohort_location' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.state('common_exposure_cohort').cohort_location).toEqual('');
    expect(wrapper.find('#cohort-modal-save-button').prop('disabled')).toEqual(true);
  });

  it('Clicking "cancel" calls the onHide method', () => {
    const wrapper = getWrapper(mockCommonExposureCohort2);
    wrapper.find('#cohort-modal-cancel-button').simulate('click');
    expect(onHideMock).toHaveBeenCalled();
  });

  it('Clicking "save" calls the onChange method with cohort and correct index', () => {
    const wrapper = getWrapper(mockCommonExposureCohort2);
    wrapper.find('#cohort-modal-save-button').simulate('click');
    expect(onChangeMock).toHaveBeenCalledWith(mockCommonExposureCohort2, index);
  });
});
