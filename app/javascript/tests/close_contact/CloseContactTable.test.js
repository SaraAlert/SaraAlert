import React from 'react';
import { expect } from '@jest/globals';
import { shallow, mount } from 'enzyme';
import { Button, Card, InputGroup } from 'react-bootstrap';
import _ from 'lodash';

import InfoTooltip from '../../components/util/InfoTooltip';
import CloseContactTable from '../../components/patient/close_contacts/CloseContactTable';
import CloseContactModal from '../../components/patient/close_contacts/CloseContactModal';
import DeleteDialog from '../../components/util/DeleteDialog';
import { mockPatient1, mockPatient2 } from '../mocks/mockPatients';
import { formatPhoneNumberVisually } from '../../utils/Patient';
import * as mockCloseContacts from '../mocks/mockCloseContact';
import CustomTable from '../../components/layout/CustomTable';

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const ASSIGNED_USERS = [123234, 512678, 910132];

function getShallowWrapper(mockPatient, canEnroll, assigned_users) {
  // the workflow prop is only for navigating to the patient page. It doesn't impact component functionality
  return shallow(<CloseContactTable patient={mockPatient} authenticity_token={authyToken} can_enroll_close_contacts={canEnroll} assigned_users={assigned_users} workflow={'exposure'} />);
}

function getMountedWrapper(mockPatient, canEnroll, assigned_users) {
  // the workflow prop is only for navigating to the patient page. It doesn't impact component functionality
  let wrapper = mount(<CloseContactTable patient={mockPatient} authenticity_token={authyToken} can_enroll_close_contacts={canEnroll} assigned_users={assigned_users} workflow={'exposure'} />);
  // The Table Data is loaded asynchronously, so we have to mock it
  const closeContactsOfPatient = _.values(mockCloseContacts).filter(x => x.id === mockPatient.id);
  const tableData = wrapper.state('table');
  tableData.rowData = closeContactsOfPatient;
  wrapper.setState({ table: tableData });
  return wrapper;
}

describe('CloseContactTable', () => {
  it('Properly renders all main components for empty close contact', () => {
    const wrapper = getShallowWrapper(mockPatient1, true, ASSIGNED_USERS);
    expect(wrapper.find(Card).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).text()).toContain('Close Contacts');
    expect(wrapper.find(Card.Header).containsMatchingElement(<InfoTooltip />)).toBeTruthy();
    expect(wrapper.find(Button).at(0).text()).toContain('Add New Close Contact');
    expect(wrapper.find(InputGroup).exists()).toBeTruthy();
    expect(wrapper.find(CustomTable).exists()).toBeTruthy();
    expect(wrapper.find(CloseContactModal).exists()).toBeFalsy();
    expect(wrapper.find(DeleteDialog).exists()).toBeFalsy();
  });

  it('Properly opens the Close Contact Modal when clicking the "Add New Close Contact" button', () => {
    const wrapper = getShallowWrapper(mockPatient1, true, ASSIGNED_USERS);
    expect(wrapper.find(CloseContactModal).exists()).toBeFalsy();
    expect(wrapper.find(Button).at(0).text()).toContain('Add New Close Contact');
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(CloseContactModal).exists()).toBeTruthy();
  });

  it('Properly calls the handleSearch function when attempting to search', () => {
    const wrapper = getShallowWrapper(mockPatient1, true, ASSIGNED_USERS);
    const handleSearchChange = jest.spyOn(wrapper.instance(), 'handleSearchChange');
    wrapper.instance().forceUpdate();
    expect(handleSearchChange).toHaveBeenCalledTimes(0);
    expect(wrapper.find(InputGroup).exists()).toBeTruthy();
    wrapper
      .find(InputGroup)
      .find('FormControl')
      .at(0)
      .simulate('change', { target: { id: 'close-contact-search-input', value: 'FakeName43' } });
    expect(handleSearchChange).toHaveBeenCalledTimes(1);
    expect(handleSearchChange).toHaveBeenCalledWith({ target: { id: 'close-contact-search-input', value: 'FakeName43' } });
  });

  it('Properly displays an empty table when a monitoree has zero close contacts', () => {
    const wrapper = getMountedWrapper(mockPatient1, true, ASSIGNED_USERS);
    expect(wrapper.text()).toContain('No data available in table');
  });

  it('Properly fills the table with data when a monitoree has more than zero close contacts', () => {
    const patient = mockPatient2;
    const closeContactsOfPatient = _.values(mockCloseContacts).filter(x => x.id === patient.id);
    const wrapper = getMountedWrapper(patient, true, ASSIGNED_USERS);
    expect(wrapper.find('tbody').find('tr').length).toEqual(closeContactsOfPatient.length);
    closeContactsOfPatient.forEach(cc => {
      expect(wrapper.text()).toContain(cc['first_name']);
      expect(wrapper.text()).toContain(cc['last_name']);
      expect(wrapper.text()).toContain(formatPhoneNumberVisually(cc['primary_telephone']));
      expect(wrapper.text()).toContain(cc['email']);
      expect(wrapper.text()).toContain(Number(cc['contact_attempts']));
      expect(wrapper.text()).toContain(Number(cc['enrolled_id']));
      expect(wrapper.text()).toContain(cc['notes']);
    });
  });

  // The following tests will throw warning errors. However, they appear to be bugs in the renderer,
  // and do not impact test functionality
  it('Properly shows the CloseContact Modal when editing a Close Contact', async () => {
    const patient = mockPatient2;
    const wrapper = getMountedWrapper(patient, true, ASSIGNED_USERS);
    const toggleEditModal = jest.spyOn(wrapper.instance(), 'toggleEditModal');
    wrapper.instance().forceUpdate();
    // If the close_contact has a patient_id, the `View Record` option should be present
    expect(wrapper.find(CloseContactModal).exists()).toBeFalsy();
    wrapper.find('DropdownToggle').at(0).simulate('click');
    expect(wrapper.find('DropdownItem').at(0).text()).toContain('Edit');
    expect(toggleEditModal).toHaveBeenCalledTimes(0);
    expect(wrapper.state('showEditModal')).toBeFalsy();
    wrapper.find('DropdownItem').at(0).simulate('click');
    expect(toggleEditModal).toHaveBeenCalledTimes(1);
    expect(wrapper.state('showEditModal')).toBeTruthy();
    expect(wrapper.find(CloseContactModal).exists()).toBeTruthy();
  });

  it('Properly renders the "View Record" enrollment dropdown if the Close Contact is already enrolled', async () => {
    const patient = mockPatient2;
    const closeContactsOfPatient = _.values(mockCloseContacts).filter(x => x.id === patient.id);
    const wrapper = getMountedWrapper(patient, true, ASSIGNED_USERS);
    // If the close_contact has a patient_id, the `View Record` option should be present
    expect(closeContactsOfPatient[0].patient_id).not.toBeNull();
    wrapper.find('DropdownToggle').at(0).simulate('click');
    expect(wrapper.find('DropdownItem').length).toBe(4);
    expect(wrapper.find('DropdownItem').at(0).text()).toContain('Edit');
    expect(wrapper.find('DropdownItem').at(1).text()).toContain('Contact Attempt');
    expect(wrapper.find('DropdownItem').at(2).text()).toContain('View Record');
    expect(wrapper.find('DropdownItem').at(3).text()).toContain('Delete');
  });

  it('Properly renders the "Enroll" enrollment dropdown if the Close Contact is not enrolled and the user can enroll', () => {
    const patient = mockPatient2;
    const closeContactsOfPatient = _.values(mockCloseContacts).filter(x => x.id === patient.id);
    const canEnroll = true;
    const wrapper = getMountedWrapper(patient, canEnroll, ASSIGNED_USERS);
    // If the close_contact has a patient_id, the `Enroll` option should be present
    expect(closeContactsOfPatient[1].patient_id).toBeNull();
    wrapper.find('DropdownToggle').at(1).simulate('click');
    expect(wrapper.find('DropdownItem').length).toBe(4);
    expect(wrapper.find('DropdownItem').at(0).text()).toContain('Edit');
    expect(wrapper.find('DropdownItem').at(1).text()).toContain('Contact Attempt');
    expect(wrapper.find('DropdownItem').at(2).text()).toContain('Enroll');
    expect(wrapper.find('DropdownItem').at(3).text()).toContain('Delete');
  });

  it('Properly does not render the "Enroll" enrollment dropdown if the Close Contact is not enrolled and the user can not enroll', () => {
    const patient = mockPatient2;
    const canEnroll = false;
    const wrapper = getMountedWrapper(patient, canEnroll, ASSIGNED_USERS);
    wrapper.find('DropdownToggle').at(1).simulate('click');
    expect(wrapper.find('DropdownItem').length).toBe(3);
    expect(wrapper.find('DropdownItem').at(0).text()).toContain('Edit');
    expect(wrapper.find('DropdownItem').at(1).text()).toContain('Contact Attempt');
    expect(wrapper.find('DropdownItem').at(2).text()).toContain('Delete');
  });

  it('Properly calls the contact attempt function when logging a Manual Contact Attempt', () => {
    const patient = mockPatient2;
    const closeContactsOfPatient = _.values(mockCloseContacts).filter(x => x.id === patient.id);
    const wrapper = getMountedWrapper(patient, true, ASSIGNED_USERS);
    const handleContactAttempt = jest.spyOn(wrapper.instance(), 'handleContactAttempt');
    wrapper.instance().forceUpdate();
    expect(closeContactsOfPatient[0].contact_attempts).toBeNull();
    expect(wrapper.find('tr').at(1).find('td').at(7).text()).toContain('0');
    wrapper.find('DropdownToggle').at(1).simulate('click');
    expect(wrapper.find('DropdownItem').at(1).text()).toContain('Contact Attempt');
    expect(handleContactAttempt).toHaveBeenCalledTimes(0);
    wrapper.find('DropdownItem').at(1).simulate('click');
    expect(handleContactAttempt).toHaveBeenCalledTimes(1);
  });

  it('Properly calls the delete function when the button is clicked', () => {
    const patient = mockPatient2;
    const wrapper = getMountedWrapper(patient, true, ASSIGNED_USERS);
    const toggleDeleteModal = jest.spyOn(wrapper.instance(), 'toggleDeleteModal');
    wrapper.instance().forceUpdate();
    expect(wrapper.find(DeleteDialog).exists()).toBeFalsy();
    wrapper.find('DropdownToggle').at(1).simulate('click');
    expect(wrapper.find('DropdownItem').at(3).text()).toContain('Delete');
    expect(toggleDeleteModal).toHaveBeenCalledTimes(0);
    wrapper.find('DropdownItem').at(3).simulate('click');
    expect(toggleDeleteModal).toHaveBeenCalledTimes(1);
    expect(wrapper.find(DeleteDialog).exists()).toBeTruthy();
  });
});
