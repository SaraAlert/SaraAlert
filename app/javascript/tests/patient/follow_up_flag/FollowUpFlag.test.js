import React from 'react';
import { shallow } from 'enzyme';
import ReactTooltip from 'react-tooltip';
import { Form, Modal } from 'react-bootstrap';
import FollowUpFlag from '../../../components/patient/follow_up_flag/FollowUpFlag';
import ApplyToHousehold from '../../../components/patient/household/actions/ApplyToHousehold';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockPatient1, mockPatient3, mockPatient5 } from '../../mocks/mockPatients';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';

const mockToken = 'testMockTokenString12345';
const followUpFlagOptions = ['', 'Deceased', 'Duplicate', 'High-Risk', 'Hospitalized', 'In Need of Follow-up', 'Lost to Follow-up', 'Needs Interpretation', 'Quality Assurance', 'Refused Active Monitoring', 'Other'];

function getWrapperIndividual(patient, householdMembers, clear_flag) {
  return shallow(<FollowUpFlag bulkAction={false} current_user={mockUser1} patients={[patient]} other_household_members={householdMembers} jurisdiction_path="USA, State 1, County 2" jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} clear_flag={clear_flag} />);
}

function getWrapperBulkAction(patients) {
  return shallow(<FollowUpFlag bulkAction={true} current_user={mockUser1} patients={patients} other_household_members={[]} jurisdiction_path="USA, State 1, County 2" jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} />);
}

describe('FollowUpFlag', () => {
  it('Properly renders all main components when not a bulk action', () => {
    const wrapper = getWrapperIndividual(mockPatient1, [], false);
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find('#set_flag_for_follow_up').exists()).toBe(false);
    expect(wrapper.find('#clear_flag_for_follow_up').exists()).toBe(false);
    expect(wrapper.find(Form.Control).length).toEqual(2);
    expect(wrapper.find('option').length).toEqual(11);
    followUpFlagOptions.forEach((value, index) => {
      expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find(Form.Label).at(0).text()).toContain('Please select a reason for being flagged for follow-up.');
    expect(wrapper.find(Form.Label).at(1).text()).toEqual('Please include any additional details:');
    expect(wrapper.find(ApplyToHousehold).exists()).toBe(false);
    expect(wrapper.find('#bulk_action_apply_to_household').exists()).toBe(false);
    expect(wrapper.find('#follow_up_flag_cancel_button').exists()).toBe(true);
    expect(wrapper.find('#follow_up_flag_submit_button').exists()).toBe(true);
    expect(wrapper.find('#follow_up_flag_submit_button').prop('disabled')).toBe(true);
    expect(wrapper.find('#follow_up_flag_submit_button').find('span').text()).toEqual('Submit');
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
  });

  it('Properly renders all main components for patient with a flag already set when not a bulk action', () => {
    const wrapper = getWrapperIndividual(mockPatient5, [], false);
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find('#set_flag_for_follow_up').exists()).toBe(false);
    expect(wrapper.find('#clear_flag_for_follow_up').exists()).toBe(false);
    expect(wrapper.find(Form.Control).length).toEqual(2);
    expect(wrapper.find('option').length).toEqual(11);
    followUpFlagOptions.forEach((value, index) => {
      expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find(Form.Label).at(0).text()).toContain('Please select a reason for being flagged for follow-up.');
    expect(wrapper.find(Form.Label).at(1).text()).toEqual('Please include any additional details:');
    expect(wrapper.find(ApplyToHousehold).exists()).toBe(false);
    expect(wrapper.find('#bulk_action_apply_to_household').exists()).toBe(false);
    expect(wrapper.find('#follow_up_flag_cancel_button').exists()).toBe(true);
    expect(wrapper.find('#follow_up_flag_submit_button').exists()).toBe(true);
    expect(wrapper.find('#follow_up_flag_submit_button').prop('disabled')).toBe(false);
    expect(wrapper.find('#follow_up_flag_submit_button').find('span').text()).toEqual('Update');
  });

  it('Properly renders all main components when clearing the flag and not a bulk action', () => {
    const wrapper = getWrapperIndividual(mockPatient5, [], true);
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find('#set_flag_for_follow_up').exists()).toBe(false);
    expect(wrapper.find('#clear_flag_for_follow_up').exists()).toBe(false);
    expect(wrapper.find(Form.Control).length).toEqual(1);
    expect(wrapper.find('option').exists()).toBe(false);
    expect(wrapper.find(Form.Label).at(0).text()).toContain('Please include any additional details for clearing the follow-up flag:');
    expect(wrapper.find(ApplyToHousehold).exists()).toBe(false);
    expect(wrapper.find('#bulk_action_apply_to_household').exists()).toBe(false);
    expect(wrapper.find('#follow_up_flag_cancel_button').exists()).toBe(true);
    expect(wrapper.find('#follow_up_flag_submit_button').exists()).toBe(true);
    expect(wrapper.find('#follow_up_flag_submit_button').prop('disabled')).toBe(false);
    expect(wrapper.find('#follow_up_flag_submit_button').find('span').text()).toEqual('Clear');
  });

  it('When a bulk action, properly renders all main components', () => {
    const wrapper = getWrapperBulkAction([mockPatient1.linelist]);
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find('#set_flag_for_follow_up').exists()).toBe(true);
    expect(wrapper.find('#set_flag_for_follow_up').prop('checked')).toBe(true);
    expect(wrapper.find('#clear_flag_for_follow_up').exists()).toBe(true);
    expect(wrapper.find('#clear_flag_for_follow_up').prop('checked')).toBe(false);
    expect(wrapper.find('#clear_flag_for_follow_up').prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).length).toEqual(2);
    expect(wrapper.find(ReactTooltip).at(0).find('div').text()).toEqual('None of the selected monitorees have a flag set');
    expect(wrapper.find(ReactTooltip).at(1).find('div').text()).toEqual('Please select a reason for follow-up');
    expect(wrapper.find(Form.Control).length).toEqual(2);
    expect(wrapper.find('option').length).toEqual(11);
    followUpFlagOptions.forEach((value, index) => {
      expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find(Form.Label).at(0).text()).toContain('Please select a reason for being flagged for follow-up.');
    expect(wrapper.find(Form.Label).at(1).text()).toEqual('Please include any additional details:');
    expect(wrapper.find(ApplyToHousehold).exists()).toBe(false);
    expect(wrapper.find('#bulk_action_apply_to_household').exists()).toBe(true);
    expect(wrapper.find('#follow_up_flag_cancel_button').exists()).toBe(true);
    expect(wrapper.find('#follow_up_flag_submit_button').exists()).toBe(true);
    expect(wrapper.find('#follow_up_flag_submit_button').prop('disabled')).toBe(true);
    expect(wrapper.find('#follow_up_flag_submit_button').find('span').text()).toEqual('Submit');
  });

  it('Sets intial state after mount correctly for monitoree who currently does not have a flag set', () => {
    const wrapper = getWrapperIndividual(mockPatient1, [], false);

    // componentDidMount is called when mounted and that calls an async method (updateTable),
    // as a result, we added a timeout to give it time to resolve.
    setTimeout(() => {
      expect(wrapper.state('apply_to_household')).toBe(false);
      expect(wrapper.state('apply_to_household_ids')).toEqual([]);
      expect(wrapper.state('no_members_selected')).toBe(false);
      expect(wrapper.state('bulk_action_apply_to_household')).toBe(false);
      expect(wrapper.state('clear_flag_disabled')).toBe(true);
      expect(wrapper.state('clear_flag')).toBe(false);
      expect(wrapper.state('clear_flag_reason')).toEqual('');
      expect(wrapper.state('follow_up_reason')).toEqual('');
      expect(wrapper.state('follow_up_note')).toEqual('');
      expect(wrapper.state('initial_follow_up_reason')).toEqual('');
      expect(wrapper.state('initial_follow_up_note')).toEqual('');
      expect(wrapper.state('loading')).toBe(false);
    }, 500);
  });

  it('Sets intial state after mount correctly for monitoree who currently does have a flag set', () => {
    const wrapper = getWrapperIndividual(mockPatient5, [], false);

    // componentDidMount is called when mounted and that calls an async method (updateTable),
    // as a result, we added a timeout to give it time to resolve.
    setTimeout(() => {
      expect(wrapper.state('apply_to_household')).toBe(false);
      expect(wrapper.state('apply_to_household_ids')).toEqual([]);
      expect(wrapper.state('no_members_selected')).toBe(false);
      expect(wrapper.state('bulk_action_apply_to_household')).toBe(false);
      expect(wrapper.state('clear_flag_disabled')).toBe(false);
      expect(wrapper.state('clear_flag')).toBe(false);
      expect(wrapper.state('clear_flag_reason')).toEqual('');
      expect(wrapper.state('follow_up_reason')).toEqual(mockPatient5.follow_up_reason);
      expect(wrapper.state('follow_up_note')).toEqual(mockPatient5.follow_up_note);
      expect(wrapper.state('initial_follow_up_reason')).toEqual(mockPatient5.follow_up_reason);
      expect(wrapper.state('initial_follow_up_note')).toEqual(mockPatient5.follow_up_note);
      expect(wrapper.state('loading')).toBe(false);
    }, 500);
  });

  it('Submit button disabled until a reason for follow-up is selected', () => {
    const wrapper = getWrapperIndividual(mockPatient1, [], false);
    expect(wrapper.find('#follow_up_flag_submit_button').prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
    expect(wrapper.find(ReactTooltip).find('div').text()).toEqual('Please select a reason for follow-up');

    // Select a reason for follow-up
    wrapper
      .find(Form.Control)
      .at(0)
      .simulate('change', { target: { id: 'follow_up_reason', value: 'Quality Assurance' }, persist: jest.fn() });
    expect(wrapper.find('#follow_up_flag_submit_button').prop('disabled')).toBe(false);
    expect(wrapper.find(ReactTooltip).exists()).toBe(false);

    // Clear reason for follow-up
    wrapper
      .find(Form.Control)
      .at(0)
      .simulate('change', { target: { id: 'follow_up_reason', value: '' }, persist: jest.fn() });
    expect(wrapper.find('#follow_up_flag_submit_button').prop('disabled')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
    expect(wrapper.find(ReactTooltip).find('div').text()).toEqual('Please select a reason for follow-up');
  });

  it('Follow-up flag reason and notes fields are blank when monitoree currently does not have a flag set', () => {
    const wrapper = getWrapperIndividual(mockPatient1, [], false);
    expect(wrapper.find(Form.Control).at(0).prop('value')).toEqual('');
    expect(wrapper.find(Form.Control).at(1).prop('value')).toEqual('');
  });

  it('Follow-up flag reason and notes fields are pre-populated when monitoree currently has a flag set', () => {
    const wrapper = getWrapperIndividual(mockPatient5, [], false);
    expect(wrapper.find(Form.Control).at(0).prop('value')).toEqual(mockPatient5.follow_up_reason);
    expect(wrapper.find(Form.Control).at(1).prop('value')).toEqual(mockPatient5.follow_up_note);
  });

  it('ApplyToHousehold component renders when monitoree is in a household', () => {
    const wrapper = getWrapperIndividual(mockPatient1, [mockPatient3], false);
    expect(wrapper.find(ApplyToHousehold).exists()).toBe(true);
  });

  it('When a bulk action, pre-populates the follow-up reason and note if only one monitoree selected', () => {
    const wrapper = getWrapperBulkAction([mockPatient5.linelist]);
    expect(wrapper.find(Form.Control).at(0).prop('value')).toEqual(mockPatient5.follow_up_reason);
    expect(wrapper.find(Form.Control).at(1).prop('value')).toEqual(mockPatient5.follow_up_note);
  });

  it('When a bulk action, pre-populates the follow-up reason and note if one shared among all monitorees', () => {
    const wrapper = getWrapperBulkAction([mockPatient5.linelist, mockPatient5.linelist]);
    expect(wrapper.find(Form.Control).at(0).prop('value')).toEqual(mockPatient5.follow_up_reason);
    expect(wrapper.find(Form.Control).at(1).prop('value')).toEqual(mockPatient5.follow_up_note);
  });

  it('When a bulk action, does not pre-populate the follow-up reason and note if not shared among all monitorees', () => {
    const wrapper = getWrapperBulkAction([mockPatient1.linelist, mockPatient5.linelist]);
    expect(wrapper.find(Form.Control).at(0).prop('value')).toEqual('');
    expect(wrapper.find(Form.Control).at(1).prop('value')).toEqual('');
  });

  it('When a bulk action, clear flag option disabled when the selected monitorees do not currently have a flag set', () => {
    const wrapper = getWrapperBulkAction([mockPatient1.linelist, mockPatient1.linelist]);
    expect(wrapper.find('#clear_flag_for_follow_up').prop('disabled')).toBe(true);
  });

  it('When a bulk action, clear flag option enabled when one of the selected monitorees does currently have a flag set', () => {
    const wrapper = getWrapperBulkAction([mockPatient1.linelist, mockPatient3.linelist]);
    expect(wrapper.find('#clear_flag_for_follow_up').prop('disabled')).toBe(false);
  });
});
