import React from 'react';
import { Button } from 'react-bootstrap';
import { shallow } from 'enzyme';
import FollowUpFlagPanel from '../../../components/patient/follow_up_flag/FollowUpFlagPanel';
import FollowUpFlagModal from '../../../components/patient/follow_up_flag/FollowUpFlagModal';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockPatient1, mockPatient3, mockPatient5 } from '../../mocks/mockPatients';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

function getWrapper(patient, householdMembers) {
  return shallow(<FollowUpFlagPanel bulk_action={false} current_user={mockUser1} patient={patient} other_household_members={householdMembers}
    jurisdiction_path="USA, State 1, County 2" jurisdiction_paths={mockJurisdictionPaths} authenticity_token={authyToken} />);
}

describe('FollowUpFlagPanel', () => {
  it('Properly renders all main components for patient without a follow-up flag set', () => {
    const wrapper = getWrapper(mockPatient1, [ ] );
    expect(wrapper.find('#set-follow-up-flag-link').exists()).toBeTruthy();
    expect(wrapper.find(Button).exists()).toBeTruthy();
    expect(wrapper.find(Button).text()).toContain('Flag for Follow-up');
    expect(wrapper.find(Button).find('i').exists()).toBeTruthy();
    expect(wrapper.find('.follow-up-flag-box').exists()).toBeFalsy();
    expect(wrapper.find('#edit-follow-up-flag-link').exists()).toBeFalsy();
    expect(wrapper.find(FollowUpFlagModal).exists()).toBeFalsy();
  });

  it('Properly renders all main components for patient with a follow-up flag set', () => {
    const wrapper = getWrapper(mockPatient5, [ ] );
    expect(wrapper.find('#set-follow-up-flag-link').exists()).toBeFalsy();
    expect(wrapper.find('.follow-up-flag-box').exists()).toBeTruthy();
    expect(wrapper.find('#edit-follow-up-flag-link').exists()).toBeTruthy();
    const section = wrapper.find('.follow-up-flag-box');
    expect(section.find('i').exists()).toBeTruthy();
    expect(section.find(Button).exists()).toBeTruthy();
    expect(section.find(Button).text()).toEqual('Edit Flag');
    expect(section.find('b').at(1).text()).toEqual(mockPatient5.follow_up_reason);
    expect(section.find('.wrap-words').text()).toEqual(' - ' + mockPatient5.follow_up_note);
    expect(wrapper.find(FollowUpFlagModal).exists()).toBeFalsy();
  });

  it('Collapses/expands follow-up flag notes if longer than 150 characters', () => {
    const wrapper = getWrapper(mockPatient3, [ ] );
    expect(wrapper.find('.flag-note').find(Button).exists()).toBeTruthy();
    expect(wrapper.state('expandFollowUpNotes')).toBeFalsy();
    expect(wrapper.find('.flag-note').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('.flag-note').find('.wrap-words').text())
      .toEqual(' - ' + mockPatient3.follow_up_note.slice(0, 150) + ' ...');
    wrapper.find('.flag-note').find(Button).simulate('click');
    expect(wrapper.state('expandFollowUpNotes')).toBeTruthy();
    expect(wrapper.find('.flag-note').find(Button).text()).toEqual('(Collapse)');
    expect(wrapper.find('.flag-note').find('.wrap-words').text())
      .toEqual(' - ' + mockPatient3.follow_up_note);
    wrapper.find('.flag-note').find(Button).simulate('click');
    expect(wrapper.state('expandFollowUpNotes')).toBeFalsy();
    expect(wrapper.find('.flag-note').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('.flag-note').find('.wrap-words').text())
      .toEqual(' - ' + mockPatient3.follow_up_note.slice(0, 150) + ' ...');
  });
});
