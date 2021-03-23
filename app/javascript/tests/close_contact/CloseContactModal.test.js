import React from 'react'
import { shallow } from 'enzyme';
import { Button, Modal } from 'react-bootstrap';

import CloseContactModal from '../../components/patient/close_contacts/CloseContactModal'
import { mockCloseContact1, mockCloseContact2, mockCloseContact3 } from '../mocks/mockCloseContact'

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const ASSIGNED_USERS = [ 123234, 512678, 910132 ]
const testInputValues = [
  { field: 'first_name', value: 'Anthony' },
  { field: 'last_name', value: 'Stark' },
  { field: 'primary_telephone', value: '1234567890' },
  { field: 'email', value: 'tinman@example.com' },
  { field: 'last_date_of_exposure', value: '2020-05-16' },
  { field: 'assigned_user', value: ASSIGNED_USERS[0] },
  { field: 'notes', value: 'Inevitable' },
]

const mockHandleAddCCModalSave = jest.fn(() => {})
const mockHandleAddCCModalClose = jest.fn(() => {})

const mockHandleEditCCModalSave = jest.fn(() => {})
const mockHandleEditCCModalClose = jest.fn(() => {})

function getShallowWrapper (showAddCCModal, mockCC, showEditCCModal, assigned_users) {
  return shallow(
    <CloseContactModal
      title={showAddCCModal ? 'Add New Close Contact' : 'Edit Close Contact'}
      currentCloseContact={showAddCCModal ? {} : mockCC}
      onClose={showAddCCModal ? mockHandleAddCCModalClose : mockHandleEditCCModalClose}
      onSave={showAddCCModal ? mockHandleAddCCModalSave : mockHandleEditCCModalSave}
      isEditing={showEditCCModal}
      assigned_users={assigned_users}
  />
  );
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('CloseContactModal', () => {
  it('Properly renders all main components for empty close contact', () => {
    const emptyCCWrapper = getShallowWrapper(true, mockCloseContact1, false, ASSIGNED_USERS);
    expect(emptyCCWrapper.find('Button').length).toEqual(2)
    expect(emptyCCWrapper.find('Button').at(0).text()).toContain('Cancel');
    expect(emptyCCWrapper.find('Button').at(1).text()).toContain('Create');

    expect(emptyCCWrapper.state('first_name')).toBeUndefined()
    expect(emptyCCWrapper.state('last_name')).toBeUndefined()
    expect(emptyCCWrapper.state('primary_telephone')).toBeUndefined()
    expect(emptyCCWrapper.state('email')).toBeUndefined()
    expect(emptyCCWrapper.state('last_date_of_exposure')).toBeUndefined()
    expect(emptyCCWrapper.state('assigned_user')).toBeUndefined()
    expect(emptyCCWrapper.state('notes')).toEqual("")
    expect(emptyCCWrapper.state('enrolled_id')).toBeUndefined()
    expect(emptyCCWrapper.state('contact_attempts')).toBeUndefined()
  });

  it('Properly renders all main components for already existing enrolled close contact', () => {
    const alreadyExistingCCWrapper = getShallowWrapper(false, mockCloseContact2, true, ASSIGNED_USERS);
    expect(alreadyExistingCCWrapper.find('Button').length).toEqual(2)
    expect(alreadyExistingCCWrapper.find('Button').at(0).text()).toContain('Cancel');
    expect(alreadyExistingCCWrapper.find('Button').at(1).text()).toContain('Update');

    expect(alreadyExistingCCWrapper.state('first_name')).toEqual(mockCloseContact2.first_name || '')
    expect(alreadyExistingCCWrapper.state('last_name')).toEqual(mockCloseContact2.last_name || '')
    expect(alreadyExistingCCWrapper.state('primary_telephone')).toEqual(mockCloseContact2.primary_telephone || '')
    expect(alreadyExistingCCWrapper.state('email')).toEqual(mockCloseContact2.email || null)
    expect(alreadyExistingCCWrapper.state('last_date_of_exposure')).toEqual(mockCloseContact2.last_date_of_exposure || null)
    expect(alreadyExistingCCWrapper.state('assigned_user')).toEqual(mockCloseContact2.assigned_user || null)
    expect(alreadyExistingCCWrapper.state('notes')).toEqual(mockCloseContact2.notes || '')
  });

  it('Properly renders all main components for already existing unenrolled close contact', () => {
    const alreadyExistingCCWrapper = getShallowWrapper(false, mockCloseContact3, true, ASSIGNED_USERS);
    expect(alreadyExistingCCWrapper.find('Button').length).toEqual(2)
    expect(alreadyExistingCCWrapper.find('Button').at(0).text()).toContain('Cancel');
    expect(alreadyExistingCCWrapper.find('Button').at(1).text()).toContain('Update');

    expect(alreadyExistingCCWrapper.state('first_name')).toEqual(mockCloseContact3.first_name || null)
    expect(alreadyExistingCCWrapper.state('last_name')).toEqual(mockCloseContact3.last_name || null)
    expect(alreadyExistingCCWrapper.state('primary_telephone')).toEqual(mockCloseContact3.primary_telephone || null)
    expect(alreadyExistingCCWrapper.state('email')).toEqual(mockCloseContact3.email || null)
    expect(alreadyExistingCCWrapper.state('last_date_of_exposure')).toEqual(mockCloseContact3.last_date_of_exposure || null)
    expect(alreadyExistingCCWrapper.state('assigned_user')).toEqual(mockCloseContact3.assigned_user || null)
    expect(alreadyExistingCCWrapper.state('notes')).toEqual(mockCloseContact3.notes || null)
  });

  it('Disables the Create Button when the correct fields are not present when making a new close contact', () => {
    const emptyCCWrapper = getShallowWrapper(true, mockCloseContact1, false, ASSIGNED_USERS);
    const validateAndSubmit = jest.spyOn(emptyCCWrapper.instance(), 'validateAndSubmit');
    expect(emptyCCWrapper.find('Button').at(1).text()).toContain('Create');
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    emptyCCWrapper.find(Button).at(1).simulate('click');
    expect(validateAndSubmit).toHaveBeenCalledTimes(0);
  });

  it('Properly calls the Cancel callback when closing the modal on an empty close contact', () => {
    const emptyCCWrapper = getShallowWrapper(true, mockCloseContact1, false, ASSIGNED_USERS);
    expect(emptyCCWrapper.find('Button').at(0).text()).toContain('Cancel');
    emptyCCWrapper.find(Button).at(0).simulate('click');
    expect(mockHandleAddCCModalClose).toHaveBeenCalled();
  });

  it('Enables the Update Button when the correct fields are present when editing an existing close contact', () => {
    const emptyCCWrapper = getShallowWrapper(false, mockCloseContact2, true, ASSIGNED_USERS);
    const validateAndSubmitSpy = jest.spyOn(emptyCCWrapper.instance(), 'validateAndSubmit');
    emptyCCWrapper.instance().forceUpdate()
    expect(emptyCCWrapper.find('Button').at(1).text()).toContain('Update');
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeFalsy()
    emptyCCWrapper.find(Button).at(1).simulate('click');
    expect(validateAndSubmitSpy).toHaveBeenCalled();
  });

  it('Properly calls the Cancel callback when closing the modal on an empty close contact', () => {
    const emptyCCWrapper = getShallowWrapper(false, mockCloseContact2, true, ASSIGNED_USERS);
    expect(emptyCCWrapper.find('Button').at(0).text()).toContain('Cancel');
    emptyCCWrapper.find(Button).at(0).simulate('click');
    expect(mockHandleEditCCModalClose).toHaveBeenCalled();
  });

  it('Can properly set fields when an empty close contact is used as a prop', () => {
    const emptyCCWrapper = getShallowWrapper(true, mockCloseContact1, false, ASSIGNED_USERS);
    const handleChangeSpy = jest.spyOn(emptyCCWrapper.instance(), 'handleChange');
    const handleDateChangeSpy = jest.spyOn(emptyCCWrapper.instance(), 'handleDateChange');
    emptyCCWrapper.instance().forceUpdate()

    let value;
    value = testInputValues.find(x => x.field === 'first_name').value
    expect(emptyCCWrapper.state('first_name')).toBeFalsy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').at(0).simulate('change', { target: { id: 'first_name', value: value } })
    expect(handleChangeSpy).toHaveBeenCalledTimes(1);
    expect(emptyCCWrapper.state('first_name')).toEqual(value);

    value = testInputValues.find(x => x.field === 'last_name').value
    expect(emptyCCWrapper.state('last_name')).toBeFalsy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').at(1).simulate('change', { target: { id: 'last_name', value: value } })
    expect(handleChangeSpy).toHaveBeenCalledTimes(2);
    expect(emptyCCWrapper.state('last_name')).toEqual(value);

    value = testInputValues.find(x => x.field === 'primary_telephone').value
    expect(emptyCCWrapper.state('primary_telephone')).toBeFalsy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('PhoneInput').simulate('change', { target: { id: 'primary_telephone', value: value } })
    expect(handleChangeSpy).toHaveBeenCalledTimes(3);
    expect(emptyCCWrapper.state('primary_telephone')).toEqual(value);

    value = testInputValues.find(x => x.field === 'email').value
    expect(emptyCCWrapper.state('email')).toBeFalsy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('FormControl').simulate('change', { target: { id: 'email', value: value } })
    expect(handleChangeSpy).toHaveBeenCalledTimes(4);
    expect(emptyCCWrapper.state('email')).toEqual(value);

    value = testInputValues.find(x => x.field === 'last_date_of_exposure').value
    expect(emptyCCWrapper.state('last_date_of_exposure')).toBeFalsy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(2).find('DateInput').simulate('change', value )
    expect(handleDateChangeSpy).toHaveBeenCalled();
    expect(emptyCCWrapper.state('last_date_of_exposure')).toEqual(value);

    value = testInputValues.find(x => x.field === 'assigned_user').value
    expect(emptyCCWrapper.state('assigned_user')).toBeFalsy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(2).find('FormControl').simulate('change', { target: { id: 'assigned_user', value: value } })
    expect(handleChangeSpy).toHaveBeenCalledTimes(5);
    expect(emptyCCWrapper.state('assigned_user')).toEqual(value);

    value = testInputValues.find(x => x.field === 'notes').value
    expect(emptyCCWrapper.state('notes')).toBeFalsy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(3).find('FormControl').simulate('change', { target: { id: 'notes', value: value } })
    expect(handleChangeSpy).toHaveBeenCalledTimes(6);
    expect(emptyCCWrapper.state('notes')).toEqual(value);
  });

  it('Properly creates the correct assigned user dropdown options', () => {
    const emptyCCWrapper = getShallowWrapper(true, mockCloseContact1, false, ASSIGNED_USERS);
    ASSIGNED_USERS.forEach((user, userIndex) => {
      expect(emptyCCWrapper.find(Modal.Body).find('option').at(userIndex).text()).toEqual(`${user}`);
    })
  });

  it('Properly renders accurate count of characters remaining for notes field', () => {
    const emptyCCWrapper = getShallowWrapper(true, mockCloseContact1, false, ASSIGNED_USERS);
    const testNoteString = 'The Strongest Avenger'

    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(3).find('FormLabel').at(0).text()).toContain('Notes');
    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(3).find('FormLabel').at(1).text()).toContain('2000 characters remaining');
    emptyCCWrapper.find(Modal.Body).find('Row').at(3).find('FormControl').simulate('change', { target: { id: 'notes', value: testNoteString } })
    expect(emptyCCWrapper.find(Modal.Body).find('Row').at(3).find('FormLabel').at(1).text()).toContain(`${2000-testNoteString.length} characters remaining`);
  });

  it('Properly enables and disables the submit/create button when First Name and Phone is entered', () => {
    const emptyCCWrapper = getShallowWrapper(true, mockCloseContact1, false, ASSIGNED_USERS);

    let value1, value2;
    value1 = testInputValues.find(x => x.field === 'first_name').value
    value2 = testInputValues.find(x => x.field === 'primary_telephone').value
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').at(0).simulate('change', { target: { id: 'first_name', value: value1 } })
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('PhoneInput').simulate('change', { target: { id: 'primary_telephone', value: value2 } })
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeFalsy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeFalsy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').at(0).simulate('change', { target: { id: 'first_name', value: '' } })
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('PhoneInput').simulate('change', { target: { id: 'primary_telephone', value: '' } })
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
  });

  it('Properly enables and disables the submit/create button when First Name and Email is entered', () => {
    const emptyCCWrapper = getShallowWrapper(true, mockCloseContact1, false, ASSIGNED_USERS);

    let value1, value2;
    value1 = testInputValues.find(x => x.field === 'first_name').value
    value2 = testInputValues.find(x => x.field === 'email').value
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').at(0).simulate('change', { target: { id: 'first_name', value: value1 } })
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('FormControl').simulate('change', { target: { id: 'email', value: value2 } })
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeFalsy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeFalsy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').at(0).simulate('change', { target: { id: 'first_name', value: '' } })
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('FormControl').simulate('change', { target: { id: 'email', value: '' } })
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
  });

  it('Properly enables and disables the submit/create button when Last Name and Phone is entered', () => {
    const emptyCCWrapper = getShallowWrapper(true, mockCloseContact1, false, ASSIGNED_USERS);

    let value1, value2;
    value1 = testInputValues.find(x => x.field === 'last_name').value
    value2 = testInputValues.find(x => x.field === 'primary_telephone').value
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').at(0).simulate('change', { target: { id: 'last_name', value: value1 } })
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('PhoneInput').simulate('change', { target: { id: 'primary_telephone', value: value2 } })
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeFalsy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeFalsy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').at(0).simulate('change', { target: { id: 'last_name', value: '' } })
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('PhoneInput').simulate('change', { target: { id: 'primary_telephone', value: '' } })
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
  });

  it('Properly enables and disables the submit/create button when Last Name and Email is entered', () => {
    const emptyCCWrapper = getShallowWrapper(true, mockCloseContact1, false, ASSIGNED_USERS);

    let value1, value2;
    value1 = testInputValues.find(x => x.field === 'last_name').value
    value2 = testInputValues.find(x => x.field === 'email').value
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').at(0).simulate('change', { target: { id: 'last_name', value: value1 } })
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('FormControl').simulate('change', { target: { id: 'email', value: value2 } })
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeFalsy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeFalsy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').at(0).simulate('change', { target: { id: 'last_name', value: '' } })
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('FormControl').simulate('change', { target: { id: 'email', value: '' } })
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
  });

  it('Properly keeps the buttons disabled when all the required fields are not added', () => {
    const emptyCCWrapper = getShallowWrapper(true, mockCloseContact1, false, ASSIGNED_USERS);

    let value;
    value = testInputValues.find(x => x.field === 'first_name').value
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').at(0).simulate('change', { target: { id: 'first_name', value: value } })
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').at(0).simulate('change', { target: { id: 'first_name', value: '' } })

    value = testInputValues.find(x => x.field === 'last_name').value
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').at(1).simulate('change', { target: { id: 'last_name', value: value } })
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(0).find('FormControl').at(1).simulate('change', { target: { id: 'last_name', value: '' } })

    value = testInputValues.find(x => x.field === 'primary_telephone').value
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('PhoneInput').simulate('change', { target: { id: 'primary_telephone', value: value } })
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('PhoneInput').simulate('change', { target: { id: 'primary_telephone', value: '' } })

    value = testInputValues.find(x => x.field === 'email').value
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('FormControl').simulate('change', { target: { id: 'email', value: value } })
    expect(emptyCCWrapper.find(Button).at(1).props().disabled).toBeTruthy()
    expect(emptyCCWrapper.find('#submit-tooltip').exists()).toBeTruthy();
    emptyCCWrapper.find(Modal.Body).find('Row').at(1).find('FormControl').simulate('change', { target: { id: 'email', value: '' } })
  });
});
