import React from 'react';
import { expect } from '@jest/globals';
import { shallow, mount } from 'enzyme';
import { Button, Card, Dropdown, InputGroup } from 'react-bootstrap';
import _ from 'lodash';

import CloseContactTable from '../../../components/patient/close_contacts/CloseContactTable';
import CloseContactModal from '../../../components/patient/close_contacts/CloseContactModal';
import CustomTable from '../../../components/layout/CustomTable';
import DeleteDialog from '../../../components/util/DeleteDialog';
import InfoTooltip from '../../../components/util/InfoTooltip';
import { mockCloseContact1, mockCloseContact2 } from '../../mocks/mockCloseContacts';
import { mockPatient1, mockPatient2 } from '../../mocks/mockPatients';
import { formatDate, formatPhoneNumberVisually } from '../../helpers';

const AUTHY_TOKEN = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const ASSIGNED_USERS = [123234, 512678, 910132];
const MOCK_CLOSE_CONTACTS = [mockCloseContact1, mockCloseContact2];

function getShallowWrapper(additionalProps) {
  // the workflow prop is only for navigating to the patient page. It doesn't impact component functionality
  return shallow(<CloseContactTable patient={mockPatient1} authenticity_token={AUTHY_TOKEN} can_enroll_close_contacts={true} assigned_users={ASSIGNED_USERS} workflow={'exposure'} {...additionalProps} />);
}

function getMountedWrapper(closeContacts, additionalProps) {
  // the workflow prop is only for navigating to the patient page. It doesn't impact component functionality
  let wrapper = mount(<CloseContactTable patient={mockPatient2} authenticity_token={AUTHY_TOKEN} can_enroll_close_contacts={true} assigned_users={ASSIGNED_USERS} workflow={'exposure'} {...additionalProps} />);

  // The Table Data is loaded asynchronously, so we have to mock it
  wrapper.setState({ table: { ...wrapper.state().table, rowData: closeContacts } });
  return wrapper;
}

describe('CloseContactTable', () => {
  it('Properly renders all main components', () => {
    const wrapper = getShallowWrapper();
    expect(wrapper.find(Card).exists()).toBe(true);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toContain('Close Contacts');
    expect(wrapper.find(Card.Header).find(InfoTooltip).exists()).toBe(true);
    expect(wrapper.find(Card.Header).find(InfoTooltip).prop('tooltipTextKey')).toEqual('closeContacts');
    expect(wrapper.find(Button).at(0).text()).toContain('Add New Close Contact');
    expect(wrapper.find(InputGroup).exists()).toBe(true);
    expect(wrapper.find(CustomTable).exists()).toBe(true);
    expect(wrapper.find(CloseContactModal).exists()).toBe(false);
    expect(wrapper.find(DeleteDialog).exists()).toBe(false);
  });

  it('Clicking the "Add New Close Contact" button opens the Close Contact Modal', () => {
    const wrapper = getShallowWrapper();
    expect(wrapper.find(CloseContactModal).exists()).toBe(false);
    expect(wrapper.find(Button).at(0).text()).toContain('Add New Close Contact');
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(CloseContactModal).exists()).toBe(true);
  });

  it('Inputting search texts calls the handleSearchChange function', () => {
    const wrapper = getShallowWrapper();
    const handleSearchChangeSpy = jest.spyOn(wrapper.instance(), 'handleSearchChange');
    const updateTableSpy = jest.spyOn(wrapper.instance(), 'updateTable');
    wrapper.instance().forceUpdate();
    expect(handleSearchChangeSpy).not.toHaveBeenCalled();
    expect(updateTableSpy).not.toHaveBeenCalled();

    let query = wrapper.state('query');
    let searchText = 'some text';
    query.search = searchText;
    wrapper.find('#close-contact-search-input').simulate('change', { target: { id: 'close-contact-search-input', value: searchText } });
    expect(handleSearchChangeSpy).toHaveBeenCalledWith({ target: { id: 'close-contact-search-input', value: searchText } });
    expect(updateTableSpy).toHaveBeenCalledWith(query);
    expect(wrapper.state('query')).toEqual(query);
  });

  it('Properly renders an empty table when a monitoree has zero close contacts', () => {
    const wrapper = getMountedWrapper([]);
    expect(wrapper.find('table').find('tbody').find('tr').length).toEqual(1);
    expect(wrapper.find('table').find('tbody').text()).toEqual('No data available in table.');
  });

  it('Properly renders the table with data when a monitoree has at least one close contact', () => {
    const wrapper = getMountedWrapper(MOCK_CLOSE_CONTACTS);
    expect(wrapper.find('table').find('tbody').find('tr').length).toEqual(MOCK_CLOSE_CONTACTS.length);
    MOCK_CLOSE_CONTACTS.forEach((cc, index) => {
      let row = wrapper.find('table').find('tbody').find('tr').at(index);
      expect(row.find('td').at(1).text()).toEqual(cc.first_name);
      expect(row.find('td').at(2).text()).toEqual(cc.last_name);
      expect(row.find('td').at(3).text()).toEqual(formatPhoneNumberVisually(cc.primary_telephone));
      expect(row.find('td').at(4).text()).toEqual(cc.email);
      expect(row.find('td').at(5).text()).toEqual(formatDate(cc.last_date_of_exposure));
      expect(row.find('td').at(6).text()).toEqual(String(cc.assigned_user || ''));
      expect(row.find('td').at(7).text()).toEqual(String(cc.contact_attempts || 0));
      expect(row.find('td').at(8).text()).toEqual(cc.enrolled_id ? 'Yes' : 'No');
      expect(row.find('td').at(9).text()).toEqual(cc.notes);
    });
  });

  it('Properly renders row action dropdown if user can enroll monitorees', () => {
    const wrapper = getMountedWrapper(MOCK_CLOSE_CONTACTS);
    MOCK_CLOSE_CONTACTS.forEach((cc, ccIndex) => {
      wrapper.find(Dropdown).at(ccIndex).find(Dropdown.Toggle).simulate('click');
      expect(wrapper.find(Dropdown).at(ccIndex).find(Dropdown.Item).length).toEqual(4);
      expect(wrapper.find(Dropdown).at(ccIndex).find(Dropdown.Item).at(0).text()).toEqual('Edit');
      expect(wrapper.find(Dropdown).at(ccIndex).find(Dropdown.Item).at(1).text()).toEqual('Contact Attempt');
      expect(wrapper.find(Dropdown).at(ccIndex).find(Dropdown.Item).at(2).text()).toEqual(cc.enrolled_id ? 'View Record' : 'Enroll');
      expect(wrapper.find(Dropdown).at(ccIndex).find(Dropdown.Item).at(3).text()).toEqual('Delete');
    });
  });

  it('Properly renders row action dropdown if user cannot enroll monitorees', () => {
    const wrapper = getMountedWrapper(MOCK_CLOSE_CONTACTS, { can_enroll_close_contacts: false });
    MOCK_CLOSE_CONTACTS.forEach((cc, ccIndex) => {
      wrapper.find(Dropdown).at(ccIndex).find(Dropdown.Toggle).simulate('click');
      expect(wrapper.find(Dropdown).at(ccIndex).find(Dropdown.Item).length).toEqual(cc.enrolled_id ? 4 : 3);
      expect(wrapper.find(Dropdown).at(ccIndex).find(Dropdown.Item).at(0).text()).toEqual('Edit');
      expect(wrapper.find(Dropdown).at(ccIndex).find(Dropdown.Item).at(1).text()).toEqual('Contact Attempt');
      expect(wrapper.find(Dropdown).at(ccIndex).find(Dropdown.Item).at(2).text()).toEqual(cc.enrolled_id ? 'View Record' : 'Delete');
      if (cc.enrolled_id) {
        expect(wrapper.find(Dropdown).at(ccIndex).find(Dropdown.Item).at(3).text()).toEqual('Delete');
      }
    });
  });

  it('Clicking the edit dropdown option opens the Close Contact Modal', () => {
    const wrapper = getMountedWrapper(MOCK_CLOSE_CONTACTS);
    const toggleEditModalSpy = jest.spyOn(wrapper.instance(), 'toggleEditModal');
    wrapper.instance().forceUpdate();
    expect(toggleEditModalSpy).not.toHaveBeenCalled();
    expect(wrapper.find(CloseContactModal).exists()).toBe(false);
    expect(wrapper.state('showEditModal')).toBe(false);

    _.times(MOCK_CLOSE_CONTACTS.length, index => {
      // open modal
      wrapper.find(Dropdown).at(index).find(Dropdown.Toggle).simulate('click');
      wrapper.find(Dropdown).at(index).find(Dropdown.Item).first().simulate('click');
      expect(toggleEditModalSpy).toHaveBeenCalledTimes(2 * index + 1);
      expect(toggleEditModalSpy).toHaveBeenCalledWith(index);
      expect(wrapper.find(CloseContactModal).exists()).toBe(true);
      expect(wrapper.state('showEditModal')).toBe(true);

      // close modal
      wrapper.find(CloseContactModal).find(Button).first().simulate('click');
      expect(toggleEditModalSpy).toHaveBeenCalledTimes(2 * (index + 1));
      expect(toggleEditModalSpy).toHaveBeenCalledWith(index);
      expect(wrapper.find(CloseContactModal).exists()).toBe(false);
      expect(wrapper.state('showEditModal')).toBe(false);
    });
  });

  it('Clicking the delete dropdown option toggles the Delete Dialog', () => {
    const wrapper = getMountedWrapper(MOCK_CLOSE_CONTACTS);
    const toggleDeleteModalSpy = jest.spyOn(wrapper.instance(), 'toggleDeleteModal');
    wrapper.instance().forceUpdate();
    expect(toggleDeleteModalSpy).not.toHaveBeenCalled();
    expect(wrapper.find(DeleteDialog).exists()).toBe(false);
    expect(wrapper.state('showDeleteModal')).toBe(false);

    _.times(MOCK_CLOSE_CONTACTS.length, index => {
      // open modal
      wrapper.find(Dropdown).at(index).find(Dropdown.Toggle).simulate('click');
      wrapper.find(Dropdown).at(index).find(Dropdown.Item).last().simulate('click');
      expect(toggleDeleteModalSpy).toHaveBeenCalledTimes(2 * index + 1);
      expect(toggleDeleteModalSpy).toHaveBeenCalledWith(index);
      expect(wrapper.find(DeleteDialog).exists()).toBe(true);
      expect(wrapper.state('showDeleteModal')).toBe(true);

      // close modal
      wrapper.find(DeleteDialog).find(Button).first().simulate('click');
      expect(toggleDeleteModalSpy).toHaveBeenCalledTimes(2 * (index + 1));
      expect(toggleDeleteModalSpy).toHaveBeenCalledWith(index);
      expect(wrapper.find(DeleteDialog).exists()).toBe(false);
      expect(wrapper.state('showDeleteModal')).toBe(false);
    });
  });

  it('Clicking the contact attempt dropdown option calls handleContactAttempt', () => {
    const wrapper = getMountedWrapper(MOCK_CLOSE_CONTACTS);
    const handleContactAttemptSpy = jest.spyOn(wrapper.instance(), 'handleContactAttempt');
    wrapper.instance().forceUpdate();
    expect(handleContactAttemptSpy).not.toHaveBeenCalled();

    _.times(MOCK_CLOSE_CONTACTS.length, index => {
      wrapper.find(Dropdown).at(index).find(Dropdown.Toggle).simulate('click');
      wrapper.find(Dropdown).at(index).find(Dropdown.Item).at(1).simulate('click');
      expect(handleContactAttemptSpy).toHaveBeenCalledTimes(index + 1);
      expect(handleContactAttemptSpy).toHaveBeenCalledWith(index);
    });
  });
});
