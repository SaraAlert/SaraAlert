import React from 'react';
import { shallow } from 'enzyme';
import { Button, Form, InputGroup, Modal } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import MoveToHousehold from '../../../../components/patient/household/actions/MoveToHousehold';
import CustomTable from '../../../../components/layout/CustomTable';
import { mockPatient1 } from '../../../mocks/mockPatients';
import { nameFormatterAlt } from '../../../util.js';

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

function getWrapper() {
  return shallow(<MoveToHousehold patient={mockPatient1} authenticity_token={authyToken} />);
}

describe('MoveToHousehold', () => {
  it('Properly renders Move to Household button', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Button).length).toEqual(1);
    expect(wrapper.find(Button).text().includes('Move To Household')).toBeTruthy();
    expect(wrapper.find('i').hasClass('fa-house-user')).toBeTruthy();
    expect(wrapper.find(Button).prop('disabled')).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Clicking the Move to Household button opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.state('showModal')).toBeFalsy();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showModal')).toBeTruthy();
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders Move to Household modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Header).text()).toEqual('Move To Household');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find(Form.Label).text()).toEqual(
      `Please select the new monitoree that will respond for ${nameFormatterAlt(mockPatient1)}.`
    );
    expect(wrapper.find(Modal.Body).find(Form.Label).find('b').text()).toEqual(nameFormatterAlt(mockPatient1));
    expect(wrapper.find(Modal.Body).find('p').text()).toEqual(
      `You may select from the provided existing Head of Households and monitorees who are self reporting. ${nameFormatterAlt(mockPatient1)} will be immediately moved into the selected monitoree's household.`
    );
    expect(wrapper.find(Modal.Body).find(InputGroup).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('#search-input').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('#search-input').prop('value')).toEqual('');
    expect(wrapper.find(Modal.Body).find(CustomTable).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find('#move-to-household-cancel-button').exists()).toBeTruthy();
  });

  it('Changing search input updates state and calls updateTable', () => {
    const wrapper = getWrapper();
    const updateTableSpy = jest.spyOn(wrapper.instance(), 'updateTable');
    expect(updateTableSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).simulate('click');
    expect(updateTableSpy).toHaveBeenCalledTimes(1);
    expect(wrapper.state('query').search).toEqual('');
    expect(wrapper.find('#search-input').prop('value')).toEqual('');
    wrapper.find('#search-input').simulate('change', { target: { value: 'smith' } });
    expect(updateTableSpy).toHaveBeenCalledTimes(2);
    expect(wrapper.state('query').search).toEqual('smith');
    expect(wrapper.find('#search-input').prop('value')).toEqual('smith');
  });

  it('Clicking the cancel button in Move to Household modal closes modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showModal')).toBeTruthy();
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find('#move-to-household-cancel-button').simulate('click');
    expect(wrapper.state('showModal')).toBeFalsy();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
  });
  
  it('Clicking the cancel button in Move to Household modal resets state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.setState({ query: { ...wrapper.state.query, search: 'smith', entries: 10, page: 32 } }, () => {
      expect(wrapper.state('query').page).toEqual(32);
      expect(wrapper.state('query').search).toEqual('smith');
      expect(wrapper.state('query').entries).toEqual(10);
      wrapper.find('#move-to-household-cancel-button').simulate('click');
      expect(wrapper.state('query').page).toEqual(0);
      expect(wrapper.state('query').search).toEqual('');
      expect(wrapper.state('query').entries).toEqual(5);
    });
  });
});
