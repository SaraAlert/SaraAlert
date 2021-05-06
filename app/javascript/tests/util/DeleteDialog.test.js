import React from 'react';
import { shallow } from 'enzyme';
import { Button, Form, Modal } from 'react-bootstrap';
import _ from 'lodash';
import DeleteDialog from '../../components/util/DeleteDialog';

const mockType = 'Some Object Type'
const deleteMock = jest.fn();
const toggleMock = jest.fn();
const onChangeMock = jest.fn();
const deleteReasons = [ 'Duplicate entry', 'Entered in error', 'Other' ];

function getWrapper() {
  return shallow(<DeleteDialog type={mockType} delete={deleteMock} toggle={toggleMock} onChange={onChangeMock} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('DeleteDialog', () => {
  it('Properly renders all main components of modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual(`Delete ${mockType}`);
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').at(0).text()).toEqual(`Are you sure you want to delete this ${mockType}? This action cannot be undone. For auditing purposes, this deletion will be available in this record's history export.`);
    expect(wrapper.find(Modal.Body).find('p').at(1).text()).toEqual('Please select reason for deletion:');
    expect(wrapper.find(Modal.Body).find(Form.Control).length).toEqual(1);
    expect(wrapper.find(Modal.Body).find('#delete_reason').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('#delete_reason').find('option').length).toEqual(4);
    expect(wrapper.find(Modal.Body).find('#delete_reason').find('option').at(0).text()).toEqual('--');
    expect(wrapper.find(Modal.Body).find('#delete_reason').find('option').at(0).prop('disabled')).toBeTruthy();
    deleteReasons.forEach((reason, index) => {
      expect(wrapper.find(Modal.Body).find('#delete_reason').find('option').at(index+1).text()).toEqual(reason);
      expect(wrapper.find(Modal.Body).find('#delete_reason').find('option').at(index+1).prop('disabled')).toBeFalsy();
    });
    expect(wrapper.find(Modal.Body).find('#delete_reason_text').exists()).toBeFalsy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(0).prop('disabled')).toBeFalsy();
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Delete');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeTruthy();
  });

  it('Changing delete reason dropdown enables delete button', () => {
    const wrapper = getWrapper();
    expect(wrapper.state('disabled')).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeTruthy();
    wrapper.find('#delete_reason').simulate('change', { target: { id: 'delete_reason', value: deleteReasons[0] }, persist: jest.fn() });
    expect(wrapper.state('disabled')).toBeFalsy();
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeFalsy();
    wrapper.find('#delete_reason').simulate('change', { target: { id: 'delete_reason', value: deleteReasons[1] }, persist: jest.fn() });
    expect(wrapper.state('disabled')).toBeFalsy();
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeFalsy();
  });

  it('Changing delete button reason dropdown to "Other" shows text input field', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal.Body).find('#delete_reason_text').exists()).toBeFalsy();
    _.times(5, () => {
      let random = _.random(deleteReasons.length - 1);
      wrapper.find('#delete_reason').simulate('change', { target: { id: 'delete_reason', value: deleteReasons[random] }, persist: jest.fn() });
      expect(wrapper.find(Modal.Body).find('#delete_reason_text').exists()).toEqual(deleteReasons[random] === 'Other');
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
    expect(toggleMock).toHaveBeenCalledTimes(0);
    wrapper.find(Modal.Footer).find(Button).at(0).simulate('click');
    expect(toggleMock).toHaveBeenCalledTimes(1);
  });

  it('Clicking delete button calls props.delete', () => {
    const wrapper = getWrapper();
    expect(deleteMock).toHaveBeenCalledTimes(0);
    wrapper.find('#delete_reason').simulate('change', { target: { id: 'delete_reason', value: deleteReasons[0] }, persist: jest.fn() });
    expect(deleteMock).toHaveBeenCalledTimes(0);
    wrapper.find(Modal.Footer).find(Button).at(1).simulate('click');
    expect(deleteMock).toHaveBeenCalledTimes(1);
  });

  it('Clicking delete button disables button and updates state', () => {
    const wrapper = getWrapper();
    expect(wrapper.state('disabled')).toBeTruthy();
    expect(wrapper.state('loading')).toBeFalsy();
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeTruthy();
    wrapper.find('#delete_reason').simulate('change', { target: { id: 'delete_reason', value: deleteReasons[0] }, persist: jest.fn() });
    expect(wrapper.state('disabled')).toBeFalsy();
    expect(wrapper.state('loading')).toBeFalsy();
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeFalsy();
    wrapper.find(Modal.Footer).find(Button).at(1).simulate('click');
    expect(wrapper.state('disabled')).toBeFalsy();
    expect(wrapper.state('loading')).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeTruthy();
  });
});
