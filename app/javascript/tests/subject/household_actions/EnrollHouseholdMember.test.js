import React from 'react'
import { shallow } from 'enzyme';
import { Button, Modal } from 'react-bootstrap';
import EnrollHouseholdMember from '../../../components/subject/household_actions/EnrollHouseholdMember.js'

function getWrapper(isHoh) {
  return shallow(<EnrollHouseholdMember responderId={123} isHoh={isHoh} />);
}

describe('EnrollHouseholdMember', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper(true);
    expect(wrapper.find(Button).exists()).toBeTruthy();
    expect(wrapper.find(Button).text().includes('Enroll Household Member')).toBeTruthy();
    expect(wrapper.find('i').hasClass('fa-user-plus')).toBeTruthy();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
  });

  it('Clicking the "Enroll Household Member" button opens modal', () => {
    const wrapper = getWrapper(true);
    expect(wrapper.state('showModal')).toBeFalsy();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showModal')).toBeTruthy();
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders modal for head of household', () => {
    const wrapper = getWrapper(true);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Title).text()).toEqual('Enroll Household Member');
    expect(wrapper.find(Modal.Body).text()).toEqual('Use "Enroll Household Member" if you would like this Head of Household to report on behalf of another monitoree who is not yet enrolled in Sara Alert. This Head of Household will report on behalf of the new household member. If the household member is already enrolled, please navigate to that record and use the "Move to Household" button.');
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Continue');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('href').includes('/patients/123/group')).toBeTruthy();
  });

  it('Properly renders modal for single household member (no depenedents)', () => {
    const wrapper = getWrapper(false);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Title).text()).toEqual('Enroll Household Member');
    expect(wrapper.find(Modal.Body).text()).toEqual('Use "Enroll Household Member" if you would like this monitoree to report on behalf of another monitoree who is not yet enrolled in Sara Alert. This monitoree will become the Head of Household for the new household member. If the household member is already enrolled, please navigate to that record and use the "Move to Household" button.');
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Continue');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('href').includes('/patients/123/group')).toBeTruthy();
  });

  it('Clicking Cancel button closes modal and resets state', () => {
    const wrapper = getWrapper(true);
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showModal')).toBeTruthy();
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Modal.Footer).find(Button).at(0).simulate('click');
    expect(wrapper.state('showModal')).toBeFalsy();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
  });

  it('Clicking Continue button disables the button and triggers loading spinner', () => {
    const wrapper = getWrapper(true);
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('loading')).toBeFalsy();
    expect(wrapper.find('.spinner-border').exists()).toBeFalsy();
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeFalsy();
    wrapper.find(Modal.Footer).find(Button).at(1).simulate('click');
    expect(wrapper.state('loading')).toBeTruthy();
    expect(wrapper.find('.spinner-border').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeTruthy();
  });
});
