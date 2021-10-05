import React from 'react';
import { shallow } from 'enzyme';
import { Button, Form, Modal } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import RemoveFromHousehold from '../../../../components/patient/household/actions/RemoveFromHousehold';
import { mockPatient1 } from '../../../mocks/mockPatients';

const mockToken = 'testMockTokenString12345';

function getWrapper() {
  return shallow(<RemoveFromHousehold patient={mockPatient1} authenticity_token={mockToken} />);
}

describe('RemoveFromHousehold', () => {
  it('Properly renders Remove from Household button', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Button).length).toEqual(1);
    expect(wrapper.find(Button).text()).toContain('Remove From Household');
    expect(wrapper.find('i').hasClass('fa-house-user')).toBe(true);
    expect(wrapper.find(Button).prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);
  });

  it('Clicking the Remove to Household button opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.state('showModal')).toBe(false);
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showModal')).toBe(true);
    expect(wrapper.find(Modal).exists()).toBe(true);
  });

  it('Properly renders Remove from Household modal if removeEligible', () => {
    const wrapper = getWrapper();
    wrapper.setState({ removeEligible: true }, () => {
      wrapper.find(Button).simulate('click');
      expect(wrapper.find(Modal).exists()).toBe(true);
      expect(wrapper.find(Modal.Header).exists()).toBe(true);
      expect(wrapper.find(Modal.Title).text()).toEqual('Remove Monitoree From Household');
      expect(wrapper.find(Modal.Body).exists()).toBe(true);
      expect(wrapper.find(Modal.Body).find(Form.Label).text()).toEqual('This monitoree will be removed from their household and will be responsible for their own responses.');
      expect(wrapper.find(Modal.Footer).exists()).toBe(true);
      expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
      expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
      expect(wrapper.find(Modal.Footer).find(Button).at(0).prop('disabled')).toBe(false);
      expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Remove');
      expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(false);
    });
  });

  it('Properly renders Remove from Household modal if not removeEligible', () => {
    const wrapper = getWrapper();
    wrapper.setState({ removeEligible: false }, () => {
      wrapper.find(Button).simulate('click');
      expect(wrapper.find(Modal).exists()).toBe(true);
      expect(wrapper.find(Modal.Header).exists()).toBe(true);
      expect(wrapper.find(Modal.Title).text()).toEqual('Cannot Remove Monitoree From Household');
      expect(wrapper.find(Modal.Body).exists()).toBe(true);
      expect(wrapper.find(Modal.Body).find(Form.Label).text()).toEqual('This monitoree cannot be removed from their household until their email and primary telephone number differ from those of the current head of household.');
      expect(wrapper.find(Modal.Footer).exists()).toBe(true);
      expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
      expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
      expect(wrapper.find(Modal.Footer).find(Button).at(0).prop('disabled')).toBe(false);
      expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Remove');
      expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(true);
    });
  });

  it('Clicking the remove button calls the submit method', () => {
    const wrapper = getWrapper();
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.setState({ removeEligible: true }, () => {
      wrapper.find(Button).simulate('click');
      expect(submitSpy).not.toHaveBeenCalled();
      wrapper.find(Modal.Footer).find(Button).at(1).simulate('click');
      expect(submitSpy).toHaveBeenCalled();
    });
  });

  it('Clicking the remove button disables the button and updates state', () => {
    const wrapper = getWrapper();
    wrapper.setState({ removeEligible: true }, () => {
      wrapper.find(Button).simulate('click');
      expect(wrapper.state('loading')).toBe(false);
      expect(wrapper.state('showModal')).toBe(true);
      expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(false);
      wrapper.find(Modal.Footer).find(Button).at(1).simulate('click');
      expect(wrapper.state('loading')).toBe(true);
      expect(wrapper.state('showModal')).toBe(true);
      expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(true);
    });
  });

  it('Clicking the cancel button closes modal and resets state', () => {
    const wrapper = getWrapper();
    wrapper.setState({ removeEligible: true }, () => {
      wrapper.find(Button).simulate('click');
      expect(wrapper.state('showModal')).toBe(true);
      expect(wrapper.find(Modal).exists()).toBe(true);
      wrapper.find(Modal.Footer).find(Button).at(0).simulate('click');
      expect(wrapper.state('showModal')).toBe(false);
      expect(wrapper.find(Modal).exists()).toBe(false);
    });
  });
});
