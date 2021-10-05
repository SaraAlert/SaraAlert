import React from 'react';
import { shallow } from 'enzyme';
import { Button, Form, InputGroup, Modal } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import _ from 'lodash';
import MoveToHousehold from '../../../../components/patient/household/actions/MoveToHousehold';
import CustomTable from '../../../../components/layout/CustomTable';
import { mockPatient1 } from '../../../mocks/mockPatients';
import { formatNameAlt } from '../../../helpers';

const mockToken = 'testMockTokenString12345';

function getWrapper() {
  return shallow(<MoveToHousehold patient={mockPatient1} authenticity_token={mockToken} workflow={'global'} />);
}

describe('MoveToHousehold', () => {
  it('Properly renders Move to Household button', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Button).length).toEqual(1);
    expect(wrapper.find(Button).text()).toContain('Move To Household');
    expect(wrapper.find('i').hasClass('fa-house-user')).toBe(true);
    expect(wrapper.find(Button).prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);
  });

  it('Clicking the Move to Household button opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.state('showModal')).toBe(false);
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showModal')).toBe(true);
    expect(wrapper.find(Modal).exists()).toBe(true);
  });

  it('Properly renders Move to Household modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(true);
    expect(wrapper.find(Modal.Header).exists()).toBe(true);
    expect(wrapper.find(Modal.Header).text()).toEqual('Move To Household');
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find(Form.Label).text()).toEqual(`Please select the new monitoree that will respond for ${formatNameAlt(mockPatient1)}.`);
    expect(wrapper.find(Modal.Body).find(Form.Label).find('b').text()).toEqual(formatNameAlt(mockPatient1));

    expect(_.unescape(wrapper.find(Modal.Body).find('p').text())).toEqual(`You may select from the provided existing Head of Households and monitorees who are self reporting. ${formatNameAlt(mockPatient1)} will be immediately moved into the selected monitoree's household.`);
    expect(wrapper.find(Modal.Body).find(InputGroup).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('#search-input').exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('#search-input').prop('value')).toEqual('');
    expect(wrapper.find(Modal.Body).find(CustomTable).exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find('#move-to-household-cancel-button').exists()).toBe(true);
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
    expect(wrapper.state('showModal')).toBe(true);
    expect(wrapper.find(Modal).exists()).toBe(true);
    wrapper.find('#move-to-household-cancel-button').simulate('click');
    expect(wrapper.state('showModal')).toBe(false);
    expect(wrapper.find(Modal).exists()).toBe(false);
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
