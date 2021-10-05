import React from 'react';
import { shallow } from 'enzyme';
import { Button, Modal } from 'react-bootstrap';
import EnrollHouseholdMember from '../../../../components/patient/household/actions/EnrollHouseholdMember';

function getWrapper(isHoh) {
  return shallow(<EnrollHouseholdMember responderId={123} isHoh={isHoh} workflow={'global'} />);
}

describe('EnrollHouseholdMember', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper(true);
    expect(wrapper.find(Button).exists()).toBe(true);
    expect(wrapper.find(Button).text()).toContain('Enroll Household Member');
    expect(wrapper.find('i').hasClass('fa-user-plus')).toBe(true);
    expect(wrapper.find(Modal).exists()).toBe(false);
  });

  it('Clicking the "Enroll Household Member" button opens modal', () => {
    const wrapper = getWrapper(true);
    expect(wrapper.state('showModal')).toBe(false);
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showModal')).toBe(true);
    expect(wrapper.find(Modal).exists()).toBe(true);
  });

  it('Properly renders modal for head of household', () => {
    const wrapper = getWrapper(true);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Title).text()).toEqual('Enroll Household Member');
    expect(wrapper.find(Modal.Body).text()).toEqual('Use "Enroll Household Member" if you would like this Head of Household to report on behalf of another monitoree who is not yet enrolled in Sara Alert. This Head of Household will report on behalf of the new household member. If the household member is already enrolled, please navigate to that record and use the "Move to Household" button.');
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Continue');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('href')).toContain('/patients/123/group?nav=global');
  });

  it('Properly renders modal for single household member (no depenedents)', () => {
    const wrapper = getWrapper(false);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Title).text()).toEqual('Enroll Household Member');
    expect(wrapper.find(Modal.Body).text()).toEqual('Use "Enroll Household Member" if you would like this monitoree to report on behalf of another monitoree who is not yet enrolled in Sara Alert. This monitoree will become the Head of Household for the new household member. If the household member is already enrolled, please navigate to that record and use the "Move to Household" button.');
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Continue');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('href')).toContain('/patients/123/group?nav=global');
  });

  it('Clicking Cancel button closes modal and resets state', () => {
    const wrapper = getWrapper(true);
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showModal')).toBe(true);
    expect(wrapper.find(Modal).exists()).toBe(true);
    wrapper.find(Modal.Footer).find(Button).at(0).simulate('click');
    expect(wrapper.state('showModal')).toBe(false);
    expect(wrapper.find(Modal).exists()).toBe(false);
  });

  it('Clicking Continue button disables the button and triggers loading spinner', () => {
    const wrapper = getWrapper(true);
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('loading')).toBe(false);
    expect(wrapper.find('.spinner-border').exists()).toBe(false);
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(false);
    wrapper.find(Modal.Footer).find(Button).at(1).simulate('click');
    expect(wrapper.state('loading')).toBe(true);
    expect(wrapper.find('.spinner-border').exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBe(true);
  });
});
