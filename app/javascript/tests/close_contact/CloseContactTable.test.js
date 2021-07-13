import React from 'react';
import { expect } from '@jest/globals';
import { shallow, mount } from 'enzyme';
import { Card, InputGroup } from 'react-bootstrap';
import _ from 'lodash';

import InfoTooltip from '../../components/util/InfoTooltip';
import CloseContactTable from '../../components/patient/close_contacts/CloseContactTable';
import CloseContactModal from '../../components/patient/close_contacts/CloseContactModal';
import { mockPatient1, mockPatient2 } from '../mocks/mockPatients';
import { formatPhoneNumber } from '../../utils/Patient';
import * as mockCloseContacts from '../mocks/mockCloseContact';

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const ASSIGNED_USERS = [123234, 512678, 910132];

function getShallowWrapper(mockPatient, canEnroll, assigned_users) {
  return shallow(<CloseContactTable patient={mockPatient} authenticity_token={authyToken} can_enroll_close_contacts={canEnroll} assigned_users={assigned_users} />);
}

function getMountedWrapper(mockPatient, canEnroll, assigned_users) {
  let wrapper = mount(<CloseContactTable patient={mockPatient} authenticity_token={authyToken} can_enroll_close_contacts={canEnroll} assigned_users={assigned_users} />);
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
    expect(wrapper.find('CardHeader').containsMatchingElement(<InfoTooltip />)).toBeTruthy();
    expect(wrapper.find('Button').at(0).text()).toContain('Add New Close Contact');
    expect(wrapper.find(InputGroup).exists()).toBeTruthy();
    expect(wrapper.find(CloseContactModal).exists()).toBeFalsy();
  });

  it('Properly renders the Close Contact Modal when clicking the `Add New Close Contact` button', () => {
    const wrapper = getShallowWrapper(mockPatient1, true, ASSIGNED_USERS);
    expect(wrapper.find(CloseContactModal).exists()).toBeFalsy();
    expect(wrapper.find('Button').at(0).text()).toContain('Add New Close Contact');
    wrapper.find('Button').at(0).simulate('click');
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

  it('Properly fills the table with mockData when a monitoree has more than zero close contacts', () => {
    const patient = mockPatient2;
    const closeContactsOfPatient = _.values(mockCloseContacts).filter(x => x.id === patient.id);
    const wrapper = getMountedWrapper(patient, true, ASSIGNED_USERS);
    expect(wrapper.find('tbody').find('tr').length).toEqual(closeContactsOfPatient.length);
    closeContactsOfPatient.forEach(cc => {
      expect(wrapper.text()).toContain(cc['first_name']);
      expect(wrapper.text()).toContain(cc['last_name']);
      expect(wrapper.text()).toContain(formatPhoneNumber(cc['primary_telephone']));
      expect(wrapper.text()).toContain(cc['email']);
      expect(wrapper.text()).toContain(Number(cc['contact_attempts']));
      expect(wrapper.text()).toContain(Number(cc['enrolled_id']));
      expect(wrapper.text()).toContain(cc['notes']);
    });
  });
});
