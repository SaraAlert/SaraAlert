import React from 'react';
import { shallow } from 'enzyme';
import InfoTooltip from '../../../components/util/InfoTooltip';
import UpdateAssignedUser from '../../../components/public_health/bulk_actions/UpdateAssignedUser';
import { mockPatient1, mockPatient2, mockPatient6 } from '../../mocks/mockPatients';

const onCloseMock = jest.fn();
const mockToken = 'testMockTokenString12345';
const mockAssignedUserDatalist = ['3682', '903874', '73892', '1689'];

function getWrapper(patientsArray) {
  let wrapper = shallow(<UpdateAssignedUser authenticity_token={mockToken} patients={patientsArray} close={onCloseMock} assigned_users={mockAssignedUserDatalist} />);
  return wrapper;
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('UpdateAssignedUser', () => {
  it('Sets intial state after mount correctly', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient2]);
    // componentDidMount is called when mounted so a timeout is needed to give it time to resolve.
    setTimeout(() => {
      expect(wrapper.state('assigned_user')).toEqual('21');
      expect(wrapper.state('initial_assigned_user')).toEqual('21');
      expect(wrapper.state('apply_to_household')).toBeFalsy();
      expect(wrapper.state('loading')).toBeFalsy();
    }, 100);
  });

  it('Properly renders all main components', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient2]);
    expect(wrapper.find('ModalBody').find('div').at(0).text()).toContain('Please input the desired Assigned User to be associated with all selected monitorees:');
    expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find('#assigned_user_input').exists()).toBeTruthy();
    expect(wrapper.find('#assigned_users').exists()).toBeTruthy();
    wrapper
      .find('#assigned_users')
      .find('option')
      .forEach((option, index) => {
        expect(option.text()).toEqual(mockAssignedUserDatalist[Number(index)]);
      });
    expect(wrapper.find('#apply_to_household').exists()).toBeTruthy();
    expect(wrapper.find('ModalFooter').find('Button').at(0).text()).toEqual('Cancel');
    expect(wrapper.find('ModalFooter').find('Button').at(1).text()).toEqual('Submit');
    // componentDidMount is called when mounted so a timeout is needed to give it time to resolve.
    setTimeout(() => {
      expect(wrapper.find('#assigned_user_input').text()).toEqual('21');
    }, 100);
  });

  it('Does not display an assigned user value when the selected monitorees do not share the same value', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient6]);
    setTimeout(() => {
      expect(wrapper.find('#assigned_user_input').text()).toEqual('');
    }, 100);
  });

  it('Only allows the user to input an integer of max length 6 digits', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient2]);

    // Test valid 6 digit input
    wrapper.find('FormControl').simulate('change', { target: { value: '378492' }, persist: jest.fn() });
    setTimeout(() => {
      expect(wrapper.find('#assigned_user_input').text()).toEqual('378492');
    }, 100);

    // Test invalid 7 digit input
    wrapper.find('FormControl').simulate('change', { target: { value: '3784929' }, persist: jest.fn() });
    setTimeout(() => {
      expect(wrapper.find('#assigned_user_input').text()).not.toEqual('3784929');
    }, 100);

    // Test invalid non-numerical input
    wrapper.find('FormControl').simulate('change', { target: { value: 'text' }, persist: jest.fn() });
    setTimeout(() => {
      expect(wrapper.find('#assigned_user_input').text()).not.toEqual('text');
    }, 100);
  });

  it('Properly toggles the Apply to Household option', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient6]);
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    wrapper.find('FormCheck').simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: true }, persist: jest.fn() });
    expect(wrapper.state('apply_to_household')).toBeTruthy();
    wrapper.find('FormCheck').simulate('change', { target: { id: 'apply_to_household', type: 'checkbox', checked: false }, persist: jest.fn() });
    expect(wrapper.state('apply_to_household')).toBeFalsy();
  });

  it('Properly calls the close method', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient6]);
    expect(wrapper.find('Button').at(0).text()).toContain('Cancel');
    expect(onCloseMock).toHaveBeenCalledTimes(0);
    wrapper.find('Button').at(0).simulate('click');
    expect(onCloseMock).toHaveBeenCalled();
  });

  it('Properly calls the submit method', () => {
    const wrapper = getWrapper([mockPatient1, mockPatient6]);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.instance().forceUpdate(); // must forceUpdate to properly mount the spy

    expect(wrapper.find('Button').at(1).text()).toContain('Submit');
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find('Button').at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
