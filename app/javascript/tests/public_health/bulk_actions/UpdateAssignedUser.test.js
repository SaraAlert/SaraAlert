import React from 'react';
import { shallow } from 'enzyme';
import { Button, Form, Modal } from 'react-bootstrap';
import InfoTooltip from '../../../components/util/InfoTooltip';
import UpdateAssignedUser from '../../../components/public_health/bulk_actions/UpdateAssignedUser';
import { mockPatient1, mockPatient2, mockPatient6 } from '../../mocks/mockPatients';

const onCloseMock = jest.fn();
const mockToken = 'testMockTokenString12345';
const mockAssignedUserDatalist = ['3682', '903874', '73892', '1689'];

function getWrapper(patientsArray) {
  return shallow(<UpdateAssignedUser authenticity_token={mockToken} patients={patientsArray} close={onCloseMock} assigned_users={mockAssignedUserDatalist} />);
}

describe('UpdateAssignedUser', () => {
  it('Sets intial state after mount correctly', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient2]);
    expect(wrapper.state('assigned_user')).toEqual(21);
    expect(wrapper.state('initial_assigned_user')).toEqual(21);
    expect(wrapper.state('apply_to_household')).toBe(false);
    expect(wrapper.state('loading')).toBe(false);
  });

  it('Properly renders all main components', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient2]);
    expect(wrapper.find(Modal.Body).find('div').at(0).text()).toContain('Please input the desired Assigned User to be associated with all selected monitorees:');
    expect(wrapper.find(InfoTooltip).exists()).toBe(true);
    expect(wrapper.find('#assigned_user_input').exists()).toBe(true);
    expect(wrapper.find('#assigned_users').exists()).toBe(true);
    wrapper
      .find('#assigned_users')
      .find('option')
      .forEach((option, index) => {
        expect(option.text()).toEqual(mockAssignedUserDatalist[Number(index)]);
      });
    expect(wrapper.find('#apply_to_household').exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Submit');
    expect(wrapper.find(Form.Control).prop('value')).toEqual(21);
  });

  it('Does not display an assigned user value when the selected monitorees do not share the same value', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient6]);
    expect(wrapper.find(Form.Control).prop('value')).toEqual('');
  });

  it('Only allows the user to input an integer of max length 6 digits', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient2]);

    // Test valid 6 digit input
    wrapper.find(Form.Control).simulate('change', { target: { id: 'assigned_user_input', value: '378492' }, persist: jest.fn() });
    expect(wrapper.state('assigned_user')).toEqual(378492);
    expect(wrapper.find(Form.Control).prop('value')).toEqual(378492);

    // Test invalid 7 digit input
    wrapper.find(Form.Control).simulate('change', { target: { id: 'assigned_user_input', value: '3784929' }, persist: jest.fn() });
    expect(wrapper.state('assigned_user')).not.toEqual(3784929);
    expect(wrapper.find(Form.Control).prop('value')).not.toEqual(3784929);

    // Test invalid non-numerical input
    wrapper.find(Form.Control).simulate('change', { target: { id: 'assigned_user_input', value: 'text' }, persist: jest.fn() });
    expect(wrapper.state('assigned_user')).not.toEqual('text');
    expect(wrapper.find(Form.Control).prop('value')).not.toEqual('text');
  });

  it('Properly toggles the Apply to Household option', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient6]);
    expect(wrapper.state('apply_to_household')).toBe(false);
    wrapper.find(Form.Check).simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: true }, persist: jest.fn() });
    expect(wrapper.state('apply_to_household')).toBe(true);
    wrapper.find(Form.Check).simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: false }, persist: jest.fn() });
    expect(wrapper.state('apply_to_household')).toBe(false);
  });

  it('Properly calls the close method', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient6]);
    expect(wrapper.find(Button).at(0).text()).toContain('Cancel');
    expect(onCloseMock).not.toHaveBeenCalled();
    wrapper.find(Button).at(0).simulate('click');
    expect(onCloseMock).toHaveBeenCalled();
  });

  it('Properly calls the submit method', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient6]);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.instance().forceUpdate(); // must forceUpdate to properly mount the spy

    expect(wrapper.find(Button).at(1).text()).toContain('Submit');
    expect(submitSpy).not.toHaveBeenCalled();
    wrapper.find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
