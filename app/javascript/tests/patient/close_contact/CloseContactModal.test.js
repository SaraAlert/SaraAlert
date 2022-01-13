import React from 'react';
import { shallow } from 'enzyme';
import { Button, Form, Modal } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import _ from 'lodash';

import CloseContactModal from '../../../components/patient/close_contacts/CloseContactModal';
import DateInput from '../../../components/util/DateInput';
import PhoneInput from '../../../components/util/PhoneInput';
import { mockCloseContactBlank, mockCloseContact2 } from '../../mocks/mockCloseContacts';

const onSaveMock = jest.fn();
const onCloseMock = jest.fn();
const ASSIGNED_USERS = [123234, 512678, 910132];
const INPUT_FIELDS = [
  { name: 'first_name', label: 'First Name', type: 'text' },
  { name: 'last_name', label: 'Last Name', type: 'text' },
  { name: 'primary_telephone', label: 'Phone Number', type: 'phone' },
  { name: 'email', label: 'Email', type: 'text' },
  { name: 'last_date_of_exposure', label: 'Last Date of Exposure', type: 'date' },
  { name: 'assigned_user', label: 'Assigned User', type: 'datalist', options: ASSIGNED_USERS },
  { name: 'notes', label: 'Notes', type: 'text' },
];
let activeCC;

function getWrapper(editMode) {
  activeCC = editMode ? mockCloseContact2 : mockCloseContactBlank;
  return shallow(<CloseContactModal currentCloseContact={activeCC} editMode={editMode} onClose={onCloseMock} onSave={onSaveMock} assigned_users={ASSIGNED_USERS} />);
}

describe('CloseContactModal', () => {
  it('Properly renders main components when adding new close contact', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.find(Modal).exists()).toBe(true);
    expect(wrapper.find(Modal).find('h1').text()).toEqual('Add New Close Contact');
    expect(wrapper.find(Modal.Header).exists()).toBe(true);
    expect(wrapper.find(Modal.Title).text()).toEqual('Add New Close Contact');
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find(Form.Group).length).toEqual(INPUT_FIELDS.length);
    INPUT_FIELDS.forEach((field, fieldIndex) => {
      const input = wrapper.find(Modal.Body).find(Form.Group).at(fieldIndex);
      expect(input.find(Form.Label).exists()).toBe(true);
      expect(input.find(Form.Label).text()).toContain(field.label);
      if (field.type === 'text') {
        expect(input.find(Form.Control).exists()).toBe(true);
        expect(input.find(Form.Control).prop('value')).toEqual('');
        expect(wrapper.state(field.name)).toBeNull();
      } else if (field.type === 'date') {
        expect(input.find(DateInput).exists()).toBe(true);
        expect(input.find(DateInput).prop('date')).toBeNull();
        expect(wrapper.state(field.name)).toBeNull();
      } else if (field.type === 'phone') {
        expect(input.find(PhoneInput).exists()).toBe(true);
        expect(input.find(PhoneInput).prop('value')).toBeNull();
        expect(wrapper.state(field.name)).toBeNull();
      } else if (field.type === 'datalist') {
        expect(input.find(Form.Control).exists()).toBe(true);
        expect(input.find('datalist').exists()).toBe(true);
        field.options.forEach((option, optionIndex) => {
          expect(input.find('datalist').find('option').at(optionIndex).text()).toEqual(String(option));
        });
        expect(input.find(Form.Control).prop('value')).toEqual('');
        expect(wrapper.state(field.name)).toBeNull();
      }
    });
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Button).length).toEqual(2);
    expect(wrapper.find(Button).first().text()).toContain('Cancel');
    expect(wrapper.find(Button).last().text()).toContain('Create');
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual('Please enter at least one name (First Name or Last Name) and at least one contact method (Phone Number or Email).');
  });

  it('Properly renders main components when editing an existing close contact', () => {
    const wrapper = getWrapper(true);
    expect(wrapper.find(Modal).exists()).toBe(true);
    expect(wrapper.find(Modal).find('h1').text()).toEqual('Edit Close Contact');
    expect(wrapper.find(Modal.Header).exists()).toBe(true);
    expect(wrapper.find(Modal.Title).text()).toEqual('Edit Close Contact');
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find(Form.Group).length).toEqual(INPUT_FIELDS.length);
    INPUT_FIELDS.forEach((field, fieldIndex) => {
      const input = wrapper.find(Modal.Body).find(Form.Group).at(fieldIndex);
      expect(input.find(Form.Label).exists()).toBe(true);
      expect(input.find(Form.Label).text()).toContain(field.label);
      if (field.type === 'text') {
        expect(input.find(Form.Control).exists()).toBe(true);
        expect(input.find(Form.Control).prop('value')).toEqual(activeCC[field.name]);
        expect(wrapper.state(field.name)).toEqual(activeCC[field.name]);
      } else if (field.type === 'date') {
        expect(input.find(DateInput).exists()).toBe(true);
        expect(input.find(DateInput).prop('date')).toEqual(activeCC[field.name]);
        expect(wrapper.state(field.name)).toEqual(activeCC[field.name]);
      } else if (field.type === 'phone') {
        expect(input.find(PhoneInput).exists()).toBe(true);
        expect(input.find(PhoneInput).prop('value')).toEqual(activeCC[field.name]);
        expect(wrapper.state(field.name)).toEqual(activeCC[field.name]);
      } else if (field.type === 'datalist') {
        expect(input.find(Form.Control).exists()).toBe(true);
        expect(input.find('datalist').exists()).toBe(true);
        field.options.forEach((option, optionIndex) => {
          expect(input.find('datalist').find('option').at(optionIndex).text()).toEqual(String(option));
        });
        expect(input.find(Form.Control).prop('value')).toEqual(activeCC[field.name]);
        expect(wrapper.state(field.name)).toEqual(activeCC[field.name]);
      }
    });
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Button).length).toEqual(2);
    expect(wrapper.find(Button).first().text()).toContain('Cancel');
    expect(wrapper.find(Button).last().text()).toContain('Update');
    expect(wrapper.find(Button).last().prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);
  });

  it('Changing "First Name" properly updates state', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.state('first_name')).toBeNull();
    expect(wrapper.find({ controlId: 'cc_first_name' }).find(Form.Control).prop('value')).toEqual('');

    wrapper
      .find({ controlId: 'cc_first_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_first_name', value: mockCloseContact2.first_name } });
    expect(wrapper.state('first_name')).toEqual(mockCloseContact2.first_name);
    expect(wrapper.find({ controlId: 'cc_first_name' }).find(Form.Control).prop('value')).toEqual(mockCloseContact2.first_name);

    wrapper
      .find({ controlId: 'cc_first_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_first_name', value: '' } });
    expect(wrapper.state('first_name')).toEqual('');
    expect(wrapper.find({ controlId: 'cc_first_name' }).find(Form.Control).prop('value')).toEqual('');
  });

  it('Changing "Last Name" properly updates state', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.state('last_name')).toBeNull();
    expect(wrapper.find({ controlId: 'cc_last_name' }).find(Form.Control).prop('value')).toEqual('');

    wrapper
      .find({ controlId: 'cc_last_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_last_name', value: mockCloseContact2.last_name } });
    expect(wrapper.state('last_name')).toEqual(mockCloseContact2.last_name);
    expect(wrapper.find({ controlId: 'cc_last_name' }).find(Form.Control).prop('value')).toEqual(mockCloseContact2.last_name);

    wrapper
      .find({ controlId: 'cc_last_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_last_name', value: '' } });
    expect(wrapper.state('last_name')).toEqual('');
    expect(wrapper.find({ controlId: 'cc_last_name' }).find(Form.Control).prop('value')).toEqual('');
  });

  it('Changing "Phone Number" properly updates state', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.state('primary_telephone')).toBeNull();
    expect(wrapper.find('#cc_primary_telephone').prop('value')).toBeNull();

    wrapper.find('#cc_primary_telephone').simulate('change', { target: { id: 'cc_primary_telephone', value: mockCloseContact2.primary_telephone } });
    expect(wrapper.state('primary_telephone')).toEqual(mockCloseContact2.primary_telephone);
    expect(wrapper.find('#cc_primary_telephone').prop('value')).toEqual(mockCloseContact2.primary_telephone);

    wrapper.find('#cc_primary_telephone').simulate('change', { target: { id: 'cc_primary_telephone', value: null } });
    expect(wrapper.state('primary_telephone')).toBeNull();
    expect(wrapper.find('#cc_primary_telephone').prop('value')).toBeNull();
  });

  it('Changing "Email" properly updates state', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.state('email')).toBeNull();
    expect(wrapper.find({ controlId: 'cc_email' }).find(Form.Control).prop('value')).toEqual('');

    wrapper
      .find({ controlId: 'cc_email' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_email', value: mockCloseContact2.email } });
    expect(wrapper.state('email')).toEqual(mockCloseContact2.email);
    expect(wrapper.find({ controlId: 'cc_email' }).find(Form.Control).prop('value')).toEqual(mockCloseContact2.email);

    wrapper
      .find({ controlId: 'cc_email' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_email', value: '' } });
    expect(wrapper.state('email')).toEqual('');
    expect(wrapper.find({ controlId: 'cc_email' }).find(Form.Control).prop('value')).toEqual('');
  });

  it('Changing "Last Date of Exposure" properly updates state', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.state('last_date_of_exposure')).toBeNull();
    expect(wrapper.find('#cc_last_date_of_exposure').prop('date')).toBeNull();

    wrapper.find('#cc_last_date_of_exposure').simulate('change', mockCloseContact2.last_date_of_exposure);
    expect(wrapper.state('last_date_of_exposure')).toEqual(mockCloseContact2.last_date_of_exposure);
    expect(wrapper.find('#cc_last_date_of_exposure').prop('date')).toEqual(mockCloseContact2.last_date_of_exposure);

    wrapper.find('#cc_last_date_of_exposure').simulate('change', null);
    expect(wrapper.state('last_date_of_exposure')).toBeNull();
    expect(wrapper.find('#cc_last_date_of_exposure').prop('date')).toBeNull();
  });

  it('Changing "Assigned User" properly updates state and character count', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.state('assigned_user')).toBeNull();
    expect(wrapper.find({ controlId: 'cc_assigned_user' }).find(Form.Control).prop('value')).toEqual('');

    // change to an assigned user NOT in the assigned user list
    wrapper
      .find({ controlId: 'cc_assigned_user' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_assigned_user', value: 999 } });
    expect(wrapper.state('assigned_user')).toEqual(999);
    expect(wrapper.find({ controlId: 'cc_assigned_user' }).find(Form.Control).prop('value')).toEqual(999);

    // change to each possible assigned user
    _.shuffle(ASSIGNED_USERS).forEach(user => {
      wrapper
        .find({ controlId: 'cc_assigned_user' })
        .find(Form.Control)
        .simulate('change', { target: { id: 'cc_assigned_user', value: user } });
      expect(wrapper.state('assigned_user')).toEqual(user);
      expect(wrapper.find({ controlId: 'cc_assigned_user' }).find(Form.Control).prop('value')).toEqual(user);
    });

    // change back to blank assigned user
    wrapper
      .find({ controlId: 'cc_assigned_user' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_assigned_user', value: '' } });
    expect(wrapper.state('assigned_user')).toBeNull();
    expect(wrapper.find({ controlId: 'cc_assigned_user' }).find(Form.Control).prop('value')).toEqual('');
  });

  it('Changing "Notes" properly updates state and character count', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.state('notes')).toBeNull();
    expect(wrapper.find({ controlId: 'cc_notes' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.find('.character-limit-text').first().text()).toContain('2000 characters remaining');

    wrapper
      .find({ controlId: 'cc_notes' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_notes', value: mockCloseContact2.notes } });
    expect(wrapper.state('notes')).toEqual(mockCloseContact2.notes);
    expect(wrapper.find({ controlId: 'cc_notes' }).find(Form.Control).prop('value')).toEqual(mockCloseContact2.notes);
    expect(wrapper.find('.character-limit-text').first().text()).toContain(`${2000 - mockCloseContact2.notes.length} characters remaining`);

    wrapper
      .find({ controlId: 'cc_notes' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_notes', value: '' } });
    expect(wrapper.state('notes')).toEqual('');
    expect(wrapper.find({ controlId: 'cc_notes' }).find(Form.Control).prop('value')).toEqual('');
    expect(wrapper.find('.character-limit-text').first().text()).toContain('2000 characters remaining');
  });

  it('Entering "First Name" and "Phone" fields enable/disable the submit button', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'cc_first_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_first_name', value: mockCloseContact2.first_name } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper.find('#cc_primary_telephone').simulate('change', { target: { id: 'cc_primary_telephone', value: mockCloseContact2.primary_telephone } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);

    wrapper.find('#cc_primary_telephone').simulate('change', { target: { id: 'cc_primary_telephone', value: null } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'cc_first_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_first_name', value: '' } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper.find('#cc_primary_telephone').simulate('change', { target: { id: 'cc_primary_telephone', value: mockCloseContact2.primary_telephone } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper.find('#cc_primary_telephone').simulate('change', { target: { id: 'cc_primary_telephone', value: null } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
  });

  it('Entering "First Name" and "Email" fields enable/disable the submit button', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'cc_first_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_first_name', value: mockCloseContact2.first_name } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'cc_email' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_email', value: mockCloseContact2.email } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);

    wrapper
      .find({ controlId: 'cc_email' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_email', value: '' } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'cc_first_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_first_name', value: '' } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'cc_email' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_email', value: mockCloseContact2.email } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'cc_email' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_email', value: '' } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
  });

  it('Entering "Last Name" and "Phone" fields enable/disable the submit button', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'cc_last_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_last_name', value: mockCloseContact2.last_name } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper.find('#cc_primary_telephone').simulate('change', { target: { id: 'cc_primary_telephone', value: mockCloseContact2.primary_telephone } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);

    wrapper.find('#cc_primary_telephone').simulate('change', { target: { id: 'cc_primary_telephone', value: null } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'cc_last_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_last_name', value: '' } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper.find('#cc_primary_telephone').simulate('change', { target: { id: 'cc_primary_telephone', value: mockCloseContact2.primary_telephone } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper.find('#cc_primary_telephone').simulate('change', { target: { id: 'cc_primary_telephone', value: null } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
  });

  it('Entering "Last Name" and "Email" fields enable/disable the submit button', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'cc_last_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_last_name', value: mockCloseContact2.last_name } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'cc_email' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_email', value: mockCloseContact2.email } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);

    wrapper
      .find({ controlId: 'cc_email' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_email', value: '' } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'cc_last_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_last_name', value: '' } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'cc_email' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_email', value: mockCloseContact2.email } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    wrapper
      .find({ controlId: 'cc_email' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_email', value: '' } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
  });

  it('Disables submit button when all the required fields are not entered', () => {
    const wrapper = getWrapper(false);
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);

    _.shuffle(INPUT_FIELDS).forEach(field => {
      if (field.type === 'text' || field.type === 'datalist') {
        wrapper
          .find({ controlId: `cc_${field.name}` })
          .find(Form.Control)
          .simulate('change', { target: { id: `cc_${field.name}`, value: mockCloseContact2[field.name] } });
        expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
        expect(wrapper.find(ReactTooltip).exists()).toBe(true);
        wrapper
          .find({ controlId: `cc_${field.name}` })
          .find(Form.Control)
          .simulate('change', { target: { id: `cc_${field.name}`, value: '' } });
        expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
        expect(wrapper.find(ReactTooltip).exists()).toBe(true);
      } else if (field.type === 'date') {
        wrapper.find(`#cc_${field.name}`).simulate('change', mockCloseContact2[field.name]);
        expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
        expect(wrapper.find(ReactTooltip).exists()).toBe(true);
        wrapper.find(`#cc_${field.name}`).simulate('change', null);
        expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
        expect(wrapper.find(ReactTooltip).exists()).toBe(true);
      } else if (field.type === 'phone') {
        wrapper.find(`#cc_${field.name}`).simulate('change', { target: { id: `cc_${field.name}`, value: mockCloseContact2[field.name] } });
        expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
        expect(wrapper.find(ReactTooltip).exists()).toBe(true);
        wrapper.find(`#cc_${field.name}`).simulate('change', { target: { id: `cc_${field.name}`, value: null } });
        expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
        expect(wrapper.find(ReactTooltip).exists()).toBe(true);
      }
    });
  });

  it('Clicking the cancel button calls props.onClose', () => {
    const wrapper = getWrapper(false);
    expect(onCloseMock).not.toHaveBeenCalled();
    wrapper.find(Button).first().simulate('click');
    expect(onCloseMock).toHaveBeenCalled();
  });

  it('Clicking the submit button calls props.onSave and disables the button', done => {
    const wrapper = getWrapper(false);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.instance().forceUpdate();
    expect(submitSpy).not.toHaveBeenCalled();
    expect(onSaveMock).not.toHaveBeenCalled();
    expect(wrapper.state('loading')).toBe(false);
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);

    wrapper
      .find({ controlId: 'cc_first_name' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_first_name', value: mockCloseContact2.first_name } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
    wrapper
      .find({ controlId: 'cc_email' })
      .find(Form.Control)
      .simulate('change', { target: { id: 'cc_email', value: mockCloseContact2.email } });
    expect(wrapper.find(Button).last().prop('disabled')).toBe(false);

    wrapper.find(Button).last().simulate('click');
    expect(submitSpy).toHaveBeenCalled();
    setTimeout(() => {
      // the submit method calls the schema.validate which is an async method
      // as a result, a timeout is necessary for validate to finish and the callback to be hit
      let cc = { assigned_user: null, contact_attempts: null, email: mockCloseContact2.email, first_name: mockCloseContact2.first_name, last_date_of_exposure: null, last_name: null, notes: null, primary_telephone: null };
      expect(onSaveMock).toHaveBeenCalledWith(cc);
      expect(wrapper.state('loading')).toBe(true);
      expect(wrapper.find(Button).last().prop('disabled')).toBe(true);
      done();
    }, 500);
  });
});
