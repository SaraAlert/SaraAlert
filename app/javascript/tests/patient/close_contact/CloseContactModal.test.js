import React from 'react';
import { shallow } from 'enzyme';
import { Button, Modal } from 'react-bootstrap';
import CloseContactModal from '../../../components/patient/close_contacts/CloseContactModal';
import { mockCloseContactBlank, mockCloseContact1, mockCloseContact2 } from '../../mocks/mockCloseContacts';

const mockHandleAddCCModalSave = jest.fn();
const mockHandleAddCCModalClose = jest.fn();
const mockHandleEditCCModalSave = jest.fn();
const mockHandleEditCCModalClose = jest.fn();
const ASSIGNED_USERS = [123234, 512678, 910132];
const testInputValues = [
  { field: 'first_name', value: 'Anthony' },
  { field: 'last_name', value: 'Stark' },
  { field: 'primary_telephone', value: '1234567890' },
  { field: 'email', value: 'tinman@example.com' },
  { field: 'last_date_of_exposure', value: '2020-05-16' },
  { field: 'assigned_user', value: ASSIGNED_USERS[0] },
  { field: 'notes', value: 'Inevitable' },
];

function getWrapper(showAddCCModal, mockCC, showEditCCModal, assigned_users) {
  return shallow(<CloseContactModal currentCloseContact={showAddCCModal ? {} : mockCC} onClose={showAddCCModal ? mockHandleAddCCModalClose : mockHandleEditCCModalClose} onSave={showAddCCModal ? mockHandleAddCCModalSave : mockHandleEditCCModalSave} editMode={showEditCCModal} assigned_users={assigned_users} />);
}

describe('CloseContactModal', () => {
  it('Properly renders all main components for empty close contact', () => {
    const wrapper = getWrapper(true, mockCloseContactBlank, false, ASSIGNED_USERS);
    expect(wrapper.find('Button').length).toEqual(2);
    expect(wrapper.find('Button').at(0).text()).toContain('Cancel');
    expect(wrapper.find('Button').at(1).text()).toContain('Create');
    expect(wrapper.state('first_name')).toBeUndefined();
    expect(wrapper.state('last_name')).toBeUndefined();
    expect(wrapper.state('primary_telephone')).toBeUndefined();
    expect(wrapper.state('email')).toBeUndefined();
    expect(wrapper.state('last_date_of_exposure')).toBeUndefined();
    expect(wrapper.state('assigned_user')).toBeUndefined();
    expect(wrapper.state('notes')).toEqual('');
    expect(wrapper.state('enrolled_id')).toBeUndefined();
    expect(wrapper.state('contact_attempts')).toBeUndefined();
  });

  it('Properly renders all main components for already existing enrolled close contact', () => {
    const wrapper = getWrapper(false, mockCloseContact1, true, ASSIGNED_USERS);
    expect(wrapper.find('Button').length).toEqual(2);
    expect(wrapper.find('Button').at(0).text()).toContain('Cancel');
    expect(wrapper.find('Button').at(1).text()).toContain('Update');
    expect(wrapper.state('first_name')).toEqual(mockCloseContact1.first_name || '');
    expect(wrapper.state('last_name')).toEqual(mockCloseContact1.last_name || '');
    expect(wrapper.state('primary_telephone')).toEqual(mockCloseContact1.primary_telephone || '');
    expect(wrapper.state('email')).toEqual(mockCloseContact1.email || null);
    expect(wrapper.state('last_date_of_exposure')).toEqual(mockCloseContact1.last_date_of_exposure || null);
    expect(wrapper.state('assigned_user')).toEqual(mockCloseContact1.assigned_user || null);
    expect(wrapper.state('notes')).toEqual(mockCloseContact1.notes || '');
  });

  it('Properly renders all main components for already existing unenrolled close contact', () => {
    const wrapper = getWrapper(false, mockCloseContact2, true, ASSIGNED_USERS);
    expect(wrapper.find('Button').length).toEqual(2);
    expect(wrapper.find('Button').at(0).text()).toContain('Cancel');
    expect(wrapper.find('Button').at(1).text()).toContain('Update');
    expect(wrapper.state('first_name')).toEqual(mockCloseContact2.first_name || null);
    expect(wrapper.state('last_name')).toEqual(mockCloseContact2.last_name || null);
    expect(wrapper.state('primary_telephone')).toEqual(mockCloseContact2.primary_telephone || null);
    expect(wrapper.state('email')).toEqual(mockCloseContact2.email || null);
    expect(wrapper.state('last_date_of_exposure')).toEqual(mockCloseContact2.last_date_of_exposure || null);
    expect(wrapper.state('assigned_user')).toEqual(mockCloseContact2.assigned_user || null);
    expect(wrapper.state('notes')).toEqual(mockCloseContact2.notes || null);
  });

  it('Disables the Create Button when the correct fields are not present when making a new close contact', () => {
    const wrapper = getWrapper(true, mockCloseContactBlank, false, ASSIGNED_USERS);
    const validateAndSubmit = jest.spyOn(wrapper.instance(), 'validateAndSubmit');
    expect(wrapper.find('Button').at(1).text()).toContain('Create');
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    wrapper.find(Button).at(1).simulate('click');
    expect(validateAndSubmit).not.toHaveBeenCalled();
  });

  it('Properly calls the Cancel callback when closing the modal on an empty close contact', () => {
    const wrapper = getWrapper(true, mockCloseContactBlank, false, ASSIGNED_USERS);
    expect(wrapper.find('Button').at(0).text()).toContain('Cancel');
    wrapper.find(Button).at(0).simulate('click');
    expect(mockHandleAddCCModalClose).toHaveBeenCalled();
  });

  it('Enables the Update Button when the correct fields are present when editing an existing close contact', () => {
    const wrapper = getWrapper(false, mockCloseContact1, true, ASSIGNED_USERS);
    const validateAndSubmitSpy = jest.spyOn(wrapper.instance(), 'validateAndSubmit');
    wrapper.instance().forceUpdate();
    expect(wrapper.find('Button').at(1).text()).toContain('Update');
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(false);
    wrapper.find(Button).at(1).simulate('click');
    expect(validateAndSubmitSpy).toHaveBeenCalled();
  });

  it('Properly calls the Cancel callback when closing the modal on an empty close contact', () => {
    const wrapper = getWrapper(false, mockCloseContact1, true, ASSIGNED_USERS);
    expect(wrapper.find('Button').at(0).text()).toContain('Cancel');
    wrapper.find(Button).at(0).simulate('click');
    expect(mockHandleEditCCModalClose).toHaveBeenCalled();
  });

  it('Can properly set fields when an empty close contact is used as a prop', () => {
    const wrapper = getWrapper(true, mockCloseContactBlank, false, ASSIGNED_USERS);
    const handleNameChangeSpy = jest.spyOn(wrapper.instance(), 'handleNameChange');
    const handlePhoneNumberChangeSpy = jest.spyOn(wrapper.instance(), 'handlePhoneNumberChange');
    const handleEmailChangeSpy = jest.spyOn(wrapper.instance(), 'handleEmailChange');
    const handleDateChangeSpy = jest.spyOn(wrapper.instance(), 'handleDateChange');
    const handleNotesChangeSpy = jest.spyOn(wrapper.instance(), 'handleNotesChange');
    const handleAssignedUserChangeSpy = jest.spyOn(wrapper.instance(), 'handleAssignedUserChange');
    wrapper.instance().forceUpdate();

    let value;
    value = testInputValues.find(x => x.field === 'first_name').value;
    expect(wrapper.state('first_name')).toBeUndefined();
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(0)
      .find('FormControl')
      .at(0)
      .simulate('change', { target: { id: 'first_name', value: value } });
    expect(handleNameChangeSpy).toHaveBeenCalledTimes(1);
    expect(wrapper.state('first_name')).toEqual(value);

    value = testInputValues.find(x => x.field === 'last_name').value;
    expect(wrapper.state('last_name')).toBeUndefined();
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(0)
      .find('FormControl')
      .at(1)
      .simulate('change', { target: { id: 'last_name', value: value } });
    expect(handleNameChangeSpy).toHaveBeenCalledTimes(2);
    expect(wrapper.state('last_name')).toEqual(value);

    value = testInputValues.find(x => x.field === 'primary_telephone').value;
    expect(wrapper.state('primary_telephone')).toBeUndefined();
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(1)
      .find('PhoneInput')
      .simulate('change', { target: { id: 'primary_telephone', value: value } });
    expect(handlePhoneNumberChangeSpy).toHaveBeenCalledTimes(1);
    expect(wrapper.state('primary_telephone')).toEqual(value);

    value = testInputValues.find(x => x.field === 'email').value;
    expect(wrapper.state('email')).toBeUndefined();
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(1)
      .find('FormControl')
      .simulate('change', { target: { id: 'email', value: value } });
    expect(handleEmailChangeSpy).toHaveBeenCalledTimes(1);
    expect(wrapper.state('email')).toEqual(value);

    value = testInputValues.find(x => x.field === 'last_date_of_exposure').value;
    expect(wrapper.state('last_date_of_exposure')).toBeUndefined();
    wrapper.find(Modal.Body).find('Row').at(2).find('DateInput').simulate('change', value);
    expect(handleDateChangeSpy).toHaveBeenCalledTimes(1);
    expect(wrapper.state('last_date_of_exposure')).toEqual(value);

    value = testInputValues.find(x => x.field === 'assigned_user').value;
    expect(wrapper.state('assigned_user')).toBeUndefined();
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(2)
      .find('FormControl')
      .simulate('change', { target: { id: 'assigned_user', value: value } });
    expect(handleAssignedUserChangeSpy).toHaveBeenCalledTimes(1);
    expect(wrapper.state('assigned_user')).toEqual(value);

    value = testInputValues.find(x => x.field === 'notes').value;
    expect(wrapper.state('notes')).toEqual('');
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(3)
      .find('FormControl')
      .simulate('change', { target: { id: 'notes', value: value } });
    expect(handleNotesChangeSpy).toHaveBeenCalledTimes(1);
    expect(wrapper.state('notes')).toEqual(value);
  });

  it('Properly creates the correct assigned user dropdown options', () => {
    const wrapper = getWrapper(true, mockCloseContactBlank, false, ASSIGNED_USERS);
    ASSIGNED_USERS.forEach((user, userIndex) => {
      expect(wrapper.find(Modal.Body).find('option').at(userIndex).text()).toEqual(`${user}`);
    });
  });

  it('Properly renders accurate count of characters remaining for notes field', () => {
    const wrapper = getWrapper(true, mockCloseContactBlank, false, ASSIGNED_USERS);
    const testNoteString = 'The Strongest Avenger';

    expect(wrapper.find(Modal.Body).find('Row').at(3).find('FormLabel').at(0).text()).toContain('Notes');
    expect(wrapper.find('.character-limit-text').at(0).text()).toContain('2000 characters remaining');
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(3)
      .find('FormControl')
      .simulate('change', { target: { id: 'notes', value: testNoteString } });
    expect(wrapper.find('.character-limit-text').at(0).text()).toContain(`${2000 - testNoteString.length} characters remaining`);
  });

  it('Properly enables and disables the submit/create button when First Name and Phone is entered', () => {
    const wrapper = getWrapper(true, mockCloseContactBlank, false, ASSIGNED_USERS);

    let value1, value2;
    value1 = testInputValues.find(x => x.field === 'first_name').value;
    value2 = testInputValues.find(x => x.field === 'primary_telephone').value;
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(0)
      .find('FormControl')
      .at(0)
      .simulate('change', { target: { id: 'first_name', value: value1 } });
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(1)
      .find('PhoneInput')
      .simulate('change', { target: { id: 'primary_telephone', value: value2 } });
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(false);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(false);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(0)
      .find('FormControl')
      .at(0)
      .simulate('change', { target: { id: 'first_name', value: '' } });
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(1)
      .find('PhoneInput')
      .simulate('change', { target: { id: 'primary_telephone', value: '' } });
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
  });

  it('Properly enables and disables the submit/create button when First Name and Email is entered', () => {
    const wrapper = getWrapper(true, mockCloseContactBlank, false, ASSIGNED_USERS);

    let value1, value2;
    value1 = testInputValues.find(x => x.field === 'first_name').value;
    value2 = testInputValues.find(x => x.field === 'email').value;
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(0)
      .find('FormControl')
      .at(0)
      .simulate('change', { target: { id: 'first_name', value: value1 } });
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(1)
      .find('FormControl')
      .simulate('change', { target: { id: 'email', value: value2 } });
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(false);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(false);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(0)
      .find('FormControl')
      .at(0)
      .simulate('change', { target: { id: 'first_name', value: '' } });
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(1)
      .find('FormControl')
      .simulate('change', { target: { id: 'email', value: '' } });
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
  });

  it('Properly enables and disables the submit/create button when Last Name and Phone is entered', () => {
    const wrapper = getWrapper(true, mockCloseContactBlank, false, ASSIGNED_USERS);

    let value1, value2;
    value1 = testInputValues.find(x => x.field === 'last_name').value;
    value2 = testInputValues.find(x => x.field === 'primary_telephone').value;
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(0)
      .find('FormControl')
      .at(0)
      .simulate('change', { target: { id: 'last_name', value: value1 } });
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(1)
      .find('PhoneInput')
      .simulate('change', { target: { id: 'primary_telephone', value: value2 } });
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(false);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(false);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(0)
      .find('FormControl')
      .at(0)
      .simulate('change', { target: { id: 'last_name', value: '' } });
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(1)
      .find('PhoneInput')
      .simulate('change', { target: { id: 'primary_telephone', value: '' } });
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
  });

  it('Properly enables and disables the submit/create button when Last Name and Email is entered', () => {
    const wrapper = getWrapper(true, mockCloseContactBlank, false, ASSIGNED_USERS);

    let value1, value2;
    value1 = testInputValues.find(x => x.field === 'last_name').value;
    value2 = testInputValues.find(x => x.field === 'email').value;
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(0)
      .find('FormControl')
      .at(0)
      .simulate('change', { target: { id: 'last_name', value: value1 } });
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(1)
      .find('FormControl')
      .simulate('change', { target: { id: 'email', value: value2 } });
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(false);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(false);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(0)
      .find('FormControl')
      .at(0)
      .simulate('change', { target: { id: 'last_name', value: '' } });
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(1)
      .find('FormControl')
      .simulate('change', { target: { id: 'email', value: '' } });
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
  });

  it('Properly keeps the buttons disabled when all the required fields are not added', () => {
    const wrapper = getWrapper(true, mockCloseContactBlank, false, ASSIGNED_USERS);

    let value;
    value = testInputValues.find(x => x.field === 'first_name').value;
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(0)
      .find('FormControl')
      .at(0)
      .simulate('change', { target: { id: 'first_name', value: value } });
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(0)
      .find('FormControl')
      .at(0)
      .simulate('change', { target: { id: 'first_name', value: '' } });

    value = testInputValues.find(x => x.field === 'last_name').value;
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(0)
      .find('FormControl')
      .at(1)
      .simulate('change', { target: { id: 'last_name', value: value } });
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(0)
      .find('FormControl')
      .at(1)
      .simulate('change', { target: { id: 'last_name', value: '' } });

    value = testInputValues.find(x => x.field === 'primary_telephone').value;
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(1)
      .find('PhoneInput')
      .simulate('change', { target: { id: 'primary_telephone', value: value } });
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(1)
      .find('PhoneInput')
      .simulate('change', { target: { id: 'primary_telephone', value: '' } });

    value = testInputValues.find(x => x.field === 'email').value;
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(1)
      .find('FormControl')
      .simulate('change', { target: { id: 'email', value: value } });
    expect(wrapper.find(Button).at(1).prop('disabled')).toBe(true);
    expect(wrapper.find('#submit-tooltip').exists()).toBe(true);
    wrapper
      .find(Modal.Body)
      .find('Row')
      .at(1)
      .find('FormControl')
      .simulate('change', { target: { id: 'email', value: '' } });
  });
});
