import React from 'react'
import { shallow, mount } from 'enzyme';
import { Button, Form, InputGroup, Modal } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import MoveToHousehold from '../../components/subject/MoveToHousehold.js'
import CustomTable from '../../components/layout/CustomTable';

import { mockPatient1 } from '../mocks/mockPatients'
import { nameFormatterAlt } from '../util.js'

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

function getWrapper(patient) {
  return shallow(<MoveToHousehold patient={patient} authenticity_token={authyToken} />);
}

function getMountedWrapper(patient) {
  return mount(<MoveToHousehold patient={patient} authenticity_token={authyToken} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('MoveToHousehold', () => {
  it('Properly renders Move To Household button', () => {
    const wrapper = getWrapper(mockPatient1);
    expect(wrapper.find(Button).length).toEqual(1);
    expect(wrapper.find(Button).text().includes('Move To Household')).toBeTruthy();
    expect(wrapper.find('i').hasClass('fa-house-user')).toBeTruthy();
    expect(wrapper.find(Button).prop('disabled')).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Clicking the Move to Household button opens modal', () => {
    const wrapper = getWrapper(mockPatient1);
    expect(wrapper.state('showModal')).toBeFalsy();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showModal')).toBeTruthy();
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders Move to Household modal', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find(Modal).find(Form.Label).text()).toEqual(
      `Please select the new monitoree that will respond for ${nameFormatterAlt(mockPatient1)}.`
    );
    expect(wrapper.find(Modal).find(Form.Label).find('b').text()).toEqual(nameFormatterAlt(mockPatient1));
    expect(wrapper.find(Modal).find('p').text())
    .toEqual(
      'You may select from the provided existing Head of Households and monitorees who are self reporting.' + 
      ` ${nameFormatterAlt(mockPatient1)} will be immediately moved into the selected monitoree's household.`
    );
    expect(wrapper.find(InputGroup).exists()).toBeTruthy();
    expect(wrapper.find('#search-input').exists()).toBeTruthy();
    expect(wrapper.find('#search-input').prop('value')).toEqual('');
    expect(wrapper.find(CustomTable).exists()).toBeTruthy();
    expect(wrapper.find('#move-to-household-cancel-button').exists()).toBeTruthy();
  });

  it('Changing search input updates state and calls updateTable', () => {
    const wrapper = getWrapper(mockPatient1);
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

  it('Clicking Cancel in Move to Household modal closes modal', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showModal')).toBeTruthy();
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find('#move-to-household-cancel-button').first().simulate('click');
    expect(wrapper.state('showModal')).toBeFalsy();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
  });
  
  it('Clicking Cancel in Move to Household modal resets state', () => {
    const wrapper = getWrapper(mockPatient1);
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
