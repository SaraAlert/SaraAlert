import React from 'react';
import { Button } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import { shallow } from 'enzyme';
import FollowUpFlagPanel from '../../../components/patient/follow_up_flag/FollowUpFlagPanel';
import FollowUpFlagModal from '../../../components/patient/follow_up_flag/FollowUpFlagModal';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockPatient1, mockPatient3, mockPatient5 } from '../../mocks/mockPatients';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';

const mockToken = 'testMockTokenString12345';

function getWrapper(patient, householdMembers) {
  return shallow(<FollowUpFlagPanel bulkAction={false} current_user={mockUser1} patient={patient} other_household_members={householdMembers} jurisdiction_path="USA, State 1, County 2" jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} />);
}

describe('FollowUpFlagPanel', () => {
  it('Properly renders all main components for patient without a follow-up flag set', () => {
    const wrapper = getWrapper(mockPatient1, []);
    expect(wrapper.find('#set-follow-up-flag-link').exists()).toBeTruthy();
    expect(wrapper.find(Button).exists()).toBeTruthy();
    expect(wrapper.find(Button).text()).toContain('Flag for Follow-up');
    expect(wrapper.find(Button).find('i').exists()).toBeTruthy();
    expect(wrapper.find('.follow-up-flag-box').exists()).toBeFalsy();
    expect(wrapper.find('#update-follow-up-flag').exists()).toBeFalsy();
    expect(wrapper.find(FollowUpFlagModal).exists()).toBeFalsy();
  });

  it('Properly renders all main components for patient with a follow-up flag set', () => {
    const wrapper = getWrapper(mockPatient5, []);
    expect(wrapper.find('#set-follow-up-flag-link').exists()).toBeFalsy();
    expect(wrapper.find('.follow-up-flag-box').exists()).toBeTruthy();
    expect(wrapper.find('#update-follow-up-flag').exists()).toBeTruthy();
    const section = wrapper.find('.follow-up-flag-box');
    expect(wrapper.find('i').length).toEqual(3);
    expect(wrapper.find('#update-follow-up-flag-btn').exists()).toBeTruthy();
    expect(wrapper.find('#clear-follow-up-flag-btn').exists()).toBeTruthy();
    expect(section.find(Button).length).toEqual(2);
    expect(wrapper.find(ReactTooltip).length).toEqual(2);
    expect(wrapper.find(ReactTooltip).at(0).find('span').text()).toEqual('Update Follow-up Flag');
    expect(wrapper.find(ReactTooltip).at(1).find('span').text()).toEqual('Clear Follow-up Flag');
    expect(section.find('b').at(1).text()).toEqual(mockPatient5.follow_up_reason);
    expect(section.find('.wrap-words').text()).toEqual(': ' + mockPatient5.follow_up_note);
    expect(wrapper.find(FollowUpFlagModal).exists()).toBeFalsy();
  });

  it('Collapses/expands follow-up flag notes if longer than 150 characters', () => {
    const wrapper = getWrapper(mockPatient3, []);
    expect(wrapper.find('.flag-note').find(Button).exists()).toBeTruthy();
    expect(wrapper.state('expandFollowUpNotes')).toBeFalsy();
    expect(wrapper.find('.flag-note').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('.flag-note').find('.wrap-words').text()).toEqual(': ' + mockPatient3.follow_up_note.slice(0, 150) + ' ...');
    wrapper.find('.flag-note').find(Button).simulate('click');
    expect(wrapper.state('expandFollowUpNotes')).toBeTruthy();
    expect(wrapper.find('.flag-note').find(Button).text()).toEqual('(Collapse)');
    expect(wrapper.find('.flag-note').find('.wrap-words').text()).toEqual(': ' + mockPatient3.follow_up_note);
    wrapper.find('.flag-note').find(Button).simulate('click');
    expect(wrapper.state('expandFollowUpNotes')).toBeFalsy();
    expect(wrapper.find('.flag-note').find(Button).text()).toEqual('(View all)');
    expect(wrapper.find('.flag-note').find('.wrap-words').text()).toEqual(': ' + mockPatient3.follow_up_note.slice(0, 150) + ' ...');
  });
});
