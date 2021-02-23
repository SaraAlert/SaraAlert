import React from 'react';
import { shallow, mount } from 'enzyme';
import { Button, Form, Modal } from 'react-bootstrap';
import AssignedUser from '../../../components/subject/monitoring_actions/AssignedUser';
import ApplyToHousehold from '../../../components/subject/household_actions/ApplyToHousehold';
import CustomTable from '../../../components/layout/CustomTable';
import InfoTooltip from '../../../components/util/InfoTooltip';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4 } from '../../mocks/mockPatients';

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const assigned_users = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 21 ];

function getWrapper() {
  return shallow(<AssignedUser patient={mockPatient1} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths}
    assigned_users={assigned_users} household_members={[]} authenticity_token={authyToken} />);
}

describe('AssignedUser', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Form.Label).text().includes('ASSIGNED USER')).toBeTruthy();
    expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('assignedUser');
    expect(wrapper.find('#assigned_user').exists()).toBeTruthy();
    expect(wrapper.find('option').length).toEqual(11);
    assigned_users.forEach(function(value, index) {
      expect(wrapper.find('option').at(index).text()).toEqual(String(value));
    });
    expect(wrapper.find('#assigned_user').prop('value')).toEqual(mockPatient1.assigned_user);
    expect(wrapper.find(Button).exists()).toBeTruthy();
    expect(wrapper.find(Button).text().includes('Change User')).toBeTruthy();
    expect(wrapper.find('i').hasClass('fa-users')).toBeTruthy();
    expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
  });

  it('Changing Assigned User enables change user button and sets state correctly', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
    expect(wrapper.state('assigned_user')).toEqual(mockPatient1.assigned_user);
    expect(wrapper.state('original_assigned_user')).toEqual(mockPatient1.assigned_user);
    wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: '1' } });
    expect(wrapper.find(Button).prop('disabled')).toBeFalsy();
    expect(wrapper.state('assigned_user')).toEqual(1);
    expect(wrapper.state('original_assigned_user')).toEqual(mockPatient1.assigned_user);
  });

  it('Clicking change user button opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: '1' } });
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders modal', () => {
    const wrapper = getWrapper();
    wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: '1' } });
    wrapper.find(Button).simulate('click');
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Assigned User');
    expect(modalBody.exists()).toBeTruthy();
    expect(modalBody.find('p').text()).toEqual(`Are you sure you want to change assigned user from "${mockPatient1.assigned_user}" to "1"?`);
    expect(modalBody.find(Form.Group).length).toEqual(1);
    expect(modalBody.find(ApplyToHousehold).exists()).toBeFalsy();
    expect(modalBody.find(Form.Group).text().includes('Please include any additional details:')).toBeTruthy();
    expect(modalBody.find('#reasoning').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(1).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(2).text()).toEqual('Submit');
  });

  it('Toggling HoH radio buttons hides/shows household members table and updates state', () => {
    const wrapper = mount(<AssignedUser patient={mockPatient1} assigned_users={assigned_users} current_user={mockUser1}
      jurisdiction_paths={mockJurisdictionPaths} authenticity_token={authyToken} household_members={[ mockPatient2, mockPatient3, mockPatient4 ]} />);
    wrapper.find('#assigned_user').at(1).simulate('change', { target: { id: 'assigned_user', value: '1' } });
    wrapper.find(Button).simulate('click');

    // initial radio button state
    expect(wrapper.find(ApplyToHousehold).exists()).toBeTruthy();
    expect(wrapper.find(CustomTable).exists()).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_no').at(1).prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').at(1).prop('checked')).toBeFalsy();

    // change to apply to all of household
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.find(CustomTable).exists()).toBeTruthy();
    expect(wrapper.state('apply_to_household')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_no').at(1).prop('checked')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_yes').at(1).prop('checked')).toBeTruthy();

    // change back to just this monitoree
    wrapper.find('#apply_to_household_no').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    expect(wrapper.find(CustomTable).exists()).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_no').at(1).prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').at(1).prop('checked')).toBeFalsy();
  });

  it('Adding reasoning updates state', () => {
    const wrapper = getWrapper();
    const handleChangeSpy = jest.spyOn(wrapper.instance(), 'handleReasoningChange');
    wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: '1' } });
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('#reasoning').exists()).toBeTruthy();
    wrapper.find('#reasoning').simulate('change', { target: { id: 'reasoning', value: 'insert reasoning text here' } });
    expect(handleChangeSpy).toHaveBeenCalled();
    expect(wrapper.state('reasoning')).toEqual('insert reasoning text here');
  });

  it('Clicking the cancel button closes modal and resets state', () => {
    const wrapper = getWrapper();
    wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: '1' } });
    wrapper.find(Button).simulate('click');

    // closes modal
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Button).at(1).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();

    // resets state
    expect(wrapper.state('showAssignedUserModal')).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('assigned_user')).toEqual(mockPatient1.assigned_user);
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getWrapper();
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: '1' } });
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).simulate('click');
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(2).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });

  it('Pressing the enter key opens modal only when change user button is enabled', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#assigned_user').prop('onKeyPress')({ which: 13, preventDefault: jest.fn() });
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#assigned_user').simulate('change', { target: { id: 'assigned_user', value: '1' } });
    wrapper.find('#assigned_user').prop('onKeyPress')({ which: 13, preventDefault: jest.fn() });
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });
});
