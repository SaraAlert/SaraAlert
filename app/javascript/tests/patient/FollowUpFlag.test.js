import React from 'react';
import { shallow } from 'enzyme';
import ReactTooltip from 'react-tooltip';
import FollowUpFlag from '../../components/patient/FollowUpFlag';
import ApplyToHousehold from '../../components/patient/household/actions/ApplyToHousehold';
import { mockUser1 } from '../mocks/mockUsers';
import { mockPatient1, mockPatient3, mockPatient5} from '../mocks/mockPatients';
import { mockJurisdictionPaths } from '../mocks/mockJurisdiction';

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";
const followUpFlagOptions = [ '', 'Deceased', 'Duplicate', 'High-Risk', 'Hospitalized', 'In Need of Follow-up', 'Lost to Follow-up', 'Needs Interpretation', 'Quality Assurance', 'Other' ];


function getWrapperIndividual(patient, householdMembers) {
  return shallow(<FollowUpFlag bulk_action={false} current_user={mockUser1} patient={patient} patients={[]} other_household_members={householdMembers}
    jurisdiction_path="USA, State 1, County 2" jurisdiction_paths={mockJurisdictionPaths} authenticity_token={authyToken} />);
}

function getWrapperBulkAction(patients) {
  return shallow(<FollowUpFlag bulk_action={true} current_user={mockUser1} patients={patients} other_household_members={[]} jurisdiction_path="USA, State 1, County 2"
    jurisdiction_paths={mockJurisdictionPaths} authenticity_token={authyToken} />);
}


describe('FollowUpFlag', () => {
  it('Properly renders all main components when not a bulk action', () => {
    const wrapper = getWrapperIndividual(mockPatient1, [ ] );
    expect(wrapper.find('.modal-follow-up-flag-body').exists()).toBeTruthy();
    expect(wrapper.find('.flag-radio-buttons').exists()).toBeTruthy();
    expect(wrapper.find('#set_flag_for_follow_up').exists()).toBeTruthy();
    expect(wrapper.find('#set_flag_for_follow_up').prop('checked')).toBeTruthy();
    expect(wrapper.find('#clear_flag_for_follow_up').exists()).toBeTruthy();
    expect(wrapper.find('#clear_flag_for_follow_up').prop('checked')).toBeFalsy();
    expect(wrapper.find('#follow_up_reason').exists()).toBeTruthy();
    expect(wrapper.find('option').length).toEqual(10);
    followUpFlagOptions.forEach(function(value, index) {
      expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#follow_up_note').exists()).toBeTruthy();
    expect(wrapper.find(ApplyToHousehold).exists()).toBeFalsy();
    expect(wrapper.find('#bulk_action_apply_to_household').exists()).toBeFalsy();
    expect(wrapper.find('#clear_flag_reason').exists()).toBeFalsy();
    expect(wrapper.find('#follow_up_flag_cancel_button').exists()).toBeTruthy();
    expect(wrapper.find('#follow_up_flag_submit_button').exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
  });

  it('When a bulk action, properly renders all main components', () => {
    const wrapper = getWrapperBulkAction( [ mockPatient1.linelist ] );
    expect(wrapper.find('.modal-follow-up-flag-body').exists()).toBeTruthy();
    expect(wrapper.find('.flag-radio-buttons').exists()).toBeTruthy();
    expect(wrapper.find('#set_flag_for_follow_up').exists()).toBeTruthy();
    expect(wrapper.find('#set_flag_for_follow_up').prop('checked')).toBeTruthy();
    expect(wrapper.find('#clear_flag_for_follow_up').exists()).toBeTruthy();
    expect(wrapper.find('#clear_flag_for_follow_up').prop('checked')).toBeFalsy();
    expect(wrapper.find('#clear_flag_for_follow_up').prop('disabled')).toBeTruthy();
    expect(wrapper.find('#follow_up_reason').exists()).toBeTruthy();
    expect(wrapper.find('option').length).toEqual(10);
    followUpFlagOptions.forEach(function(value, index) {
      expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#follow_up_note').exists()).toBeTruthy();
    expect(wrapper.find(ApplyToHousehold).exists()).toBeFalsy();
    expect(wrapper.find('#bulk_action_apply_to_household').exists()).toBeTruthy();
    expect(wrapper.find('#clear_flag_reason').exists()).toBeFalsy();
    expect(wrapper.find('#follow_up_flag_cancel_button').exists()).toBeTruthy();
    expect(wrapper.find('#follow_up_flag_submit_button').exists()).toBeTruthy();
    expect(wrapper.find('#follow_up_flag_submit_button').prop('disabled')).toBeTruthy();
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
  });

  it('Sets intial state after mount correctly for monitoree who currently does not have a flag set', () => {
    const wrapper = getWrapperIndividual(mockPatient1, [ ] );

    // componentDidMount is called when mounted and that calls an async method (updateTable),
    // as a result, we added a timeout to give it time to resolve.
    setTimeout (() => {
      expect(wrapper.state('apply_to_household')).toBeFalsy();
      expect(wrapper.state('apply_to_household_ids')).toEqual([]);
      expect(wrapper.state('no_members_selected')).toBeFalsy();
      expect(wrapper.state('bulk_action_apply_to_household')).toBeFalsy();
      expect(wrapper.state('clear_flag_disabled')).toBeTruthy();
      expect(wrapper.state('clear_flag')).toBeFalsy();
      expect(wrapper.state('clear_flag_reason')).toEqual('');
      expect(wrapper.state('follow_up_reason')).toEqual('');
      expect(wrapper.state('follow_up_note')).toEqual('');
      expect(wrapper.state('initial_follow_up_reason')).toEqual('');
      expect(wrapper.state('initial_follow_up_note')).toEqual('');
      expect(wrapper.state('loading')).toBeFalsy();
    }, 500);
  });

  it('Sets intial state after mount correctly for monitoree who currently does have a flag set', () => {
    const wrapper = getWrapperIndividual(mockPatient5, [ ] );

    // componentDidMount is called when mounted and that calls an async method (updateTable),
    // as a result, we added a timeout to give it time to resolve.
    setTimeout (() => {
      expect(wrapper.state('apply_to_household')).toBeFalsy();
      expect(wrapper.state('apply_to_household_ids')).toEqual([]);
      expect(wrapper.state('no_members_selected')).toBeFalsy();
      expect(wrapper.state('bulk_action_apply_to_household')).toBeFalsy();
      expect(wrapper.state('clear_flag_disabled')).toBeFalsy();
      expect(wrapper.state('clear_flag')).toBeFalsy();
      expect(wrapper.state('clear_flag_reason')).toEqual('');
      expect(wrapper.state('follow_up_reason')).toEqual(mockPatient5.follow_up_reason);
      expect(wrapper.state('follow_up_note')).toEqual(mockPatient5.follow_up_note);
      expect(wrapper.state('initial_follow_up_reason')).toEqual(mockPatient5.follow_up_reason);
      expect(wrapper.state('initial_follow_up_note')).toEqual(mockPatient5.follow_up_note);
      expect(wrapper.state('loading')).toBeFalsy();
    }, 500);
  });

  it('Submit button disabled until a reason for follow-up is selected', () => {
    const wrapper = getWrapperIndividual(mockPatient1, [ ] );
    expect(wrapper.find('#follow_up_flag_submit_button').prop('disabled')).toBeTruthy();
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).find('div').text()).toEqual('Please select a reason for follow-up');

    // Select a reason for follow-up
    wrapper.find('#follow_up_reason').simulate('change', { target: { id: 'follow_up_reason', value: 'Quality Assurance' }, persist: jest.fn() });
    expect(wrapper.find('#follow_up_flag_submit_button').prop('disabled')).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();

    // Clear reason for follow-up
    wrapper.find('#follow_up_reason').simulate('change', { target: { id: 'follow_up_reason', value: '' }, persist: jest.fn() });
    expect(wrapper.find('#follow_up_flag_submit_button').prop('disabled')).toBeTruthy();
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).find('div').text()).toEqual('Please select a reason for follow-up');
  });

  it('Clear flag option disabled when monitoree currently does not have a flag set', () => {
    const wrapper = getWrapperIndividual(mockPatient1, [ ] );
    expect(wrapper.find('#clear_flag_for_follow_up').prop('disabled')).toBeTruthy();
  });

  it('Clear flag option enabled and operation when monitoree currently has a flag set', () => {
    const wrapper = getWrapperIndividual(mockPatient5, [ ] );
    expect(wrapper.find('#clear_flag_for_follow_up').prop('disabled')).toBeFalsy();
  });

  it('Selecting and de-selecting the clear flag option hides and shows components as expected', () => {
    const wrapper = getWrapperIndividual(mockPatient5, [ ] );
    wrapper.find('#clear_flag_for_follow_up').simulate('change', { target: { name: 'flag_for_follow_up_option', id: 'clear_flag_for_follow_up' } });
    expect(wrapper.find('#set_flag_for_follow_up').prop('checked')).toBeFalsy();
    expect(wrapper.find('#clear_flag_for_follow_up').prop('checked')).toBeTruthy();
    expect(wrapper.find('#follow_up_reason').exists()).toBeFalsy();
    expect(wrapper.find('#follow_up_note').exists()).toBeFalsy();
    expect(wrapper.find('#clear_flag_reason').exists()).toBeTruthy();

    wrapper.find('#set_flag_for_follow_up').simulate('change', { target: { name: 'flag_for_follow_up_option', id: 'set_flag_for_follow_up' } });
    expect(wrapper.find('#set_flag_for_follow_up').prop('checked')).toBeTruthy();
    expect(wrapper.find('#clear_flag_for_follow_up').prop('checked')).toBeFalsy();
    expect(wrapper.find('#follow_up_reason').exists()).toBeTruthy();
    expect(wrapper.find('#follow_up_note').exists()).toBeTruthy();
    expect(wrapper.find('#clear_flag_reason').exists()).toBeFalsy();
  });

  it('Follow-up flag reason and notes fields are blank when monitoree currently does not have a flag set', () => {
    const wrapper = getWrapperIndividual(mockPatient1, [ ] );
    expect(wrapper.find('#follow_up_reason').prop('value')).toEqual('');
    expect(wrapper.find('#follow_up_note').text()).toEqual('');
  });

  it('Follow-up flag reason and notes fields are pre-populated when monitoree currently has a flag set', () => {
    const wrapper = getWrapperIndividual(mockPatient5, [ ] );
    expect(wrapper.find('#follow_up_reason').prop('value')).toEqual(mockPatient5.follow_up_reason);
    expect(wrapper.find('#follow_up_note').prop('value')).toEqual(mockPatient5.follow_up_note);
  });

  it('ApplyToHousehold component renders when monitoree is in a household', () => {
    const wrapper = getWrapperIndividual(mockPatient1, [ mockPatient3 ] );
    expect(wrapper.find(ApplyToHousehold).exists()).toBeTruthy();
  });

  it('When a bulk action, pre-populates the follow-up reason and note if only one monitoree selected', () => {
    const wrapper = getWrapperBulkAction( [ mockPatient5.linelist ] );
    expect(wrapper.find('#follow_up_reason').prop('value')).toEqual(mockPatient5.follow_up_reason);
    expect(wrapper.find('#follow_up_note').prop('value')).toEqual(mockPatient5.follow_up_note);
  });

  it('When a bulk action, pre-populates the follow-up reason and note if one shared among all monitorees', () => {
    const wrapper = getWrapperBulkAction( [ mockPatient5.linelist, mockPatient5.linelist ] );
    expect(wrapper.find('#follow_up_reason').prop('value')).toEqual(mockPatient5.follow_up_reason);
    expect(wrapper.find('#follow_up_note').prop('value')).toEqual(mockPatient5.follow_up_note);
  });

  it('When a bulk action, does not pre-populate the follow-up reason and note if not shared among all monitorees', () => {
    const wrapper = getWrapperBulkAction( [ mockPatient1.linelist, mockPatient5.linelist ] );
    expect(wrapper.find('#follow_up_reason').prop('value')).toEqual('');
    expect(wrapper.find('#follow_up_note').prop('value')).toEqual('');
  });

  it('When a bulk action, clear flag option disabled when the selected monitorees do not currently have a flag set', () => {
    const wrapper = getWrapperBulkAction( [ mockPatient1.linelist, mockPatient1.linelist ] );
    expect(wrapper.find('#clear_flag_for_follow_up').prop('disabled')).toBeTruthy();
  });

  it('When a bulk action, clear flag option enabled when one of the selected monitorees does currently have a flag set', () => {
    const wrapper = getWrapperBulkAction( [ mockPatient1.linelist, mockPatient3.linelist ] );
    expect(wrapper.find('#clear_flag_for_follow_up').prop('disabled')).toBeFalsy();
  });
});
