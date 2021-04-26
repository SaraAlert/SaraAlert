import React from 'react';
import { shallow } from 'enzyme';
import { Button, Form, Modal } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import RemoveFromHousehold from '../../../../components/patient/household/actions/RemoveFromHousehold';
import { mockPatient1 } from '../../../mocks/mockPatients';

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

function getWrapper() {
  return shallow(<RemoveFromHousehold patient={mockPatient1} authenticity_token={authyToken} />);
}

describe('RemoveFromHousehold', () => {
  it('Properly renders Remove from Household button', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Button).length).toEqual(1);
    expect(wrapper.find(Button).text().includes('Remove From Household')).toBeTruthy();
    expect(wrapper.find('i').hasClass('fa-house-user')).toBeTruthy();
    expect(wrapper.find(Button).prop('disabled')).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Clicking the Remove to Household button opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.state('showModal')).toBeFalsy();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showModal')).toBeTruthy();
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders Remove from Household modal if removeEligible', () => {
    const wrapper = getWrapper();
    wrapper.setState({ removeEligible: true }, () => {
      wrapper.find(Button).simulate('click');
      expect(wrapper.find(Modal).exists()).toBeTruthy();
      expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
      expect(wrapper.find(Modal.Title).text()).toEqual('Remove Monitoree From Household');
      expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
      expect(wrapper.find(Modal.Body).find(Form.Label).text()).toEqual('This monitoree will be removed from their household and will be responsible for their own responses.');
      expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
      expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
      expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
      expect(wrapper.find(Modal.Footer).find(Button).at(0).prop('disabled')).toBeFalsy();
      expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Remove');
      expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeFalsy();
    });
  });

  it('Properly renders Remove from Household modal if not removeEligible', () => {
    const wrapper = getWrapper();
    wrapper.setState({ removeEligible: false }, () => {
      wrapper.find(Button).simulate('click');
      expect(wrapper.find(Modal).exists()).toBeTruthy();
      expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
      expect(wrapper.find(Modal.Title).text()).toEqual('Cannot Remove Monitoree From Household');
      expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
      expect(wrapper.find(Modal.Body).find(Form.Label).text()).toEqual('This monitoree cannot be removed from their household until their email and primary telephone number differ from those of the current head of household.');
      expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
      expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
      expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
      expect(wrapper.find(Modal.Footer).find(Button).at(0).prop('disabled')).toBeFalsy();
      expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Remove');
      expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeTruthy();
    });
  });

  it('Clicking the remove button calls the submit method', () => {
    const wrapper = getWrapper();
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.setState({ removeEligible: true }, () => {
      wrapper.find(Button).simulate('click');
      expect(submitSpy).toHaveBeenCalledTimes(0);
      wrapper.find(Modal.Footer).find(Button).at(1).simulate('click');
      expect(submitSpy).toHaveBeenCalled();
    });
  });

  it('Clicking the remove button disables the button and updates state', () => {
    const wrapper = getWrapper();
    wrapper.setState({ removeEligible: true }, () => {
      wrapper.find(Button).simulate('click');
      expect(wrapper.state('loading')).toBeFalsy();
      expect(wrapper.state('showModal')).toBeTruthy();
      expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeFalsy();
      wrapper.find(Modal.Footer).find(Button).at(1).simulate('click');
      expect(wrapper.state('loading')).toBeTruthy();
      expect(wrapper.state('showModal')).toBeTruthy();
      expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeTruthy();
    });
  });

  it('Clicking the cancel button closes modal and resets state', () => {
    const wrapper = getWrapper();
    wrapper.setState({ removeEligible: true }, () => {
      wrapper.find(Button).simulate('click');
      expect(wrapper.state('showModal')).toBeTruthy();
      expect(wrapper.find(Modal).exists()).toBeTruthy();
      wrapper.find(Modal.Footer).find(Button).at(0).simulate('click');
      expect(wrapper.state('showModal')).toBeFalsy();
      expect(wrapper.find(Modal).exists()).toBeFalsy();
    });
  });
});
