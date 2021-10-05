import React from 'react';
import { shallow } from 'enzyme';
import { Alert, Button, Form, Modal } from 'react-bootstrap';
import _ from 'lodash';
import DeleteDialog from '../../components/util/DeleteDialog';

const mockType = 'Some Object Type';
const deleteMock = jest.fn();
const toggleMock = jest.fn();
const onChangeMock = jest.fn();
const deleteReasons = ['Duplicate entry', 'Entered in error', 'Other'];

function getWrapper() {
  return shallow(<DeleteDialog type={mockType} delete={deleteMock} toggle={toggleMock} onChange={onChangeMock} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('DeleteDialog', () => {
  it('Properly renders all main components of modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBe(true);
    expect(wrapper.find(Modal.Header).exists()).toBe(true);
    expect(wrapper.find(Modal.Title).text()).toEqual(`Delete ${mockType}`);
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('p').at(0).text()).toEqual(`Are you sure you want to delete this ${mockType}? This action cannot be undone. For auditing purposes, this deletion will be available in this record's history export.`);
    expect(wrapper.find(Modal.Body).find('p').at(1).text()).toEqual('Please select reason for deletion:');
    expect(wrapper.find(Modal.Body).find(Form.Control).length).toEqual(1);
    expect(wrapper.find(Modal.Body).find('#delete_reason').exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('#delete_reason').find('option').length).toEqual(4);
    expect(wrapper.find(Modal.Body).find('#delete_reason').find('option').at(0).text()).toEqual('--');
    expect(wrapper.find(Modal.Body).find('#delete_reason').find('option').at(0).prop('disabled')).toBe(true);
    deleteReasons.forEach((reason, index) => {
      expect(
        wrapper
          .find(Modal.Body)
          .find('#delete_reason')
          .find('option')
          .at(index + 1)
          .text()
      ).toEqual(reason);
      expect(
        wrapper
          .find(Modal.Body)
          .find('#delete_reason')
          .find('option')
          .at(index + 1)
          .prop('disabled')
      ).toBeUndefined();
    });
    expect(wrapper.find(Modal.Body).find('#delete_reason_text').exists()).toBe(false);
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(0).prop('disabled')).toBe(false);
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Delete');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(true);
  });

  it('Changing delete reason dropdown enables delete button', () => {
    const wrapper = getWrapper();
    expect(wrapper.state('disabled')).toBe(true);
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(true);
    wrapper.find('#delete_reason').simulate('change', { target: { id: 'delete_reason', value: deleteReasons[0] }, persist: jest.fn() });
    expect(wrapper.state('disabled')).toBe(false);
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(false);
    wrapper.find('#delete_reason').simulate('change', { target: { id: 'delete_reason', value: deleteReasons[1] }, persist: jest.fn() });
    expect(wrapper.state('disabled')).toBe(false);
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(false);
  });

  it('Changing delete button reason dropdown to "Other" shows text input field', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal.Body).find('#delete_reason_text').exists()).toBe(false);
    _.times(5, () => {
      let random = _.random(deleteReasons.length - 1);
      wrapper.find('#delete_reason').simulate('change', { target: { id: 'delete_reason', value: deleteReasons[`${random}`] }, persist: jest.fn() });
      expect(wrapper.find(Modal.Body).find('#delete_reason_text').exists()).toEqual(deleteReasons[`${random}`] === 'Other');
    });
  });

  it('Changing reason dropdown calls props.onChange', () => {
    const wrapper = getWrapper();
    expect(onChangeMock).toHaveBeenCalledTimes(0);
    wrapper.find('#delete_reason').simulate('change', { target: { id: 'delete_reason', value: deleteReasons[0] }, persist: jest.fn() });
    expect(onChangeMock).toHaveBeenCalledTimes(1);
    wrapper.find('#delete_reason').simulate('change', { target: { id: 'delete_reason', value: deleteReasons[1] }, persist: jest.fn() });
    expect(onChangeMock).toHaveBeenCalledTimes(2);
  });

  it('Changing other reason text input calls props.onChange', () => {
    const wrapper = getWrapper();
    expect(onChangeMock).toHaveBeenCalledTimes(0);
    wrapper.find('#delete_reason').simulate('change', { target: { id: 'delete_reason', value: 'Other' }, persist: jest.fn() });
    expect(onChangeMock).toHaveBeenCalledTimes(1);
    wrapper.find('#delete_reason_text').simulate('change', { target: { id: 'delete_reason_text', value: 'some text here' }, persist: jest.fn() });
    expect(onChangeMock).toHaveBeenCalledTimes(2);
    wrapper.find('#delete_reason_text').simulate('change', { target: { id: 'delete_reason_text', value: 'some text here edited' }, persist: jest.fn() });
    expect(onChangeMock).toHaveBeenCalledTimes(3);
  });

  it('Clicking cancel button calls props.toggle', () => {
    const wrapper = getWrapper();
    expect(toggleMock).not.toHaveBeenCalled();
    wrapper.find(Modal.Footer).find(Button).at(0).simulate('click');
    expect(toggleMock).toHaveBeenCalled();
  });

  it('Clicking delete button calls props.delete', () => {
    const wrapper = getWrapper();
    expect(deleteMock).not.toHaveBeenCalled();
    wrapper.find('#delete_reason').simulate('change', { target: { id: 'delete_reason', value: deleteReasons[0] }, persist: jest.fn() });
    expect(deleteMock).not.toHaveBeenCalled();
    wrapper.find(Modal.Footer).find(Button).at(1).simulate('click');
    expect(deleteMock).toHaveBeenCalled();
  });

  it('Clicking delete button disables button and updates state', () => {
    const wrapper = getWrapper();
    expect(wrapper.state('disabled')).toBe(true);
    expect(wrapper.state('loading')).toBe(false);
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(true);
    wrapper.find('#delete_reason').simulate('change', { target: { id: 'delete_reason', value: deleteReasons[0] }, persist: jest.fn() });
    expect(wrapper.state('disabled')).toBe(false);
    expect(wrapper.state('loading')).toBe(false);
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(false);
    wrapper.find(Modal.Footer).find(Button).at(1).simulate('click');
    expect(wrapper.state('disabled')).toBe(false);
    expect(wrapper.state('loading')).toBe(true);
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(true);
  });

  it('Prompts the user for symptom onset if necessary', () => {
    const wrapper = shallow(<DeleteDialog type={mockType} delete={deleteMock} toggle={toggleMock} onChange={onChangeMock} showSymptomOnsetInput={true} />);
    expect(wrapper.find(Alert).text()).toEqual('Warning: Since this record does not have a Symptom Onset Date, deleting this positive lab result may result in the record not ever being eligible to appear on the Records Requiring Review line list. Please consider entering a Symptom Onset Date to prevent this from happening:');
    expect(wrapper.find(Form.Label).text()).toEqual('SYMPTOM ONSET');
    expect(wrapper.find('#symptom_onset_delete_dialog').exists()).toBe(true);
  });

  it('Does not prompt the user for symptom onset if not necessary', () => {
    const wrapper = shallow(<DeleteDialog type={mockType} delete={deleteMock} toggle={toggleMock} onChange={onChangeMock} showSymptomOnsetInput={false} />);
    expect(wrapper.find('#symptom_onset_delete_dialog').exists()).toBe(false);
  });
});
