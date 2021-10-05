import React from 'react';
import { shallow, mount } from 'enzyme';
import { Button, Form, Modal } from 'react-bootstrap';
import Jurisdiction from '../../../components/patient/monitoring_actions/Jurisdiction';
import ApplyToHousehold from '../../../components/patient/household/actions/ApplyToHousehold';
import CustomTable from '../../../components/layout/CustomTable';
import InfoTooltip from '../../../components/util/InfoTooltip';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4 } from '../../mocks/mockPatients';

const mockToken = 'testMockTokenString12345';

function getWrapper() {
  return shallow(<Jurisdiction patient={mockPatient1} current_user={mockUser1} household_members={[]} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} user_can_transfer={true} workflow={'global'} />);
}

describe('Jurisdiction', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Form.Label).text()).toContain('ASSIGNED JURISDICTION');
    expect(wrapper.find(InfoTooltip).exists()).toBe(true);
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('assignedJurisdictionCanTransfer');
    expect(wrapper.find('#jurisdiction_id').exists()).toBe(true);
    expect(wrapper.find('option').length).toEqual(6);
    for (var key of Object.keys(mockJurisdictionPaths)) {
      expect(
        wrapper
          .find('option')
          .at(key - 2)
          .text()
      ).toEqual(mockJurisdictionPaths[`${key}`]);
    }
    expect(wrapper.find('#jurisdiction_id').prop('value')).toEqual(mockJurisdictionPaths[mockPatient1.jurisdiction_id]);
    expect(wrapper.find(Button).exists()).toBe(true);
    expect(wrapper.find(Button).text()).toContain('Change Jurisdiction');
    expect(wrapper.find('i').hasClass('fa-map-marked-alt')).toBe(true);
    expect(wrapper.find(Button).prop('disabled')).toBe(true);
  });

  it('Changing jurisdiction enables change jurisdiction button and sets state correctly', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Button).prop('disabled')).toBe(true);
    expect(wrapper.state('jurisdiction_path')).toEqual(mockJurisdictionPaths[mockPatient1.jurisdiction_id]);
    expect(wrapper.state('original_jurisdiction_id')).toEqual(mockPatient1.jurisdiction_id);
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    expect(wrapper.find(Button).prop('disabled')).toBe(false);
    expect(wrapper.state('jurisdiction_path')).toEqual('USA, State 2, County 4');
    expect(wrapper.state('original_jurisdiction_id')).toEqual(mockPatient1.jurisdiction_id);
  });

  it('Changing to an invalid jurisdiction disables change jurisdiction button and sets state correctly', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Button).prop('disabled')).toBe(true);
    expect(wrapper.state('validJurisdiction')).toBe(true);
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    expect(wrapper.find(Button).prop('disabled')).toBe(false);
    expect(wrapper.state('validJurisdiction')).toBe(true);
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 3' } });
    expect(wrapper.find(Button).prop('disabled')).toBe(true);
    expect(wrapper.state('validJurisdiction')).toBe(false);
  });

  it('Clicking change jurisdiction button opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(true);
  });

  it('Properly renders modal', () => {
    const wrapper = getWrapper();
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    wrapper.find(Button).simulate('click');
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.find(Modal.Title).exists()).toBe(true);
    expect(wrapper.find(Modal.Title).text()).toEqual('Jurisdiction');
    expect(modalBody.exists()).toBe(true);
    expect(modalBody.find('p').text()).toContain(`Are you sure you want to change jurisdiction from "${mockJurisdictionPaths[mockPatient1.jurisdiction_id]}" to "USA, State 2, County 4"?`);
    expect(modalBody.find('p').find('b').text()).toEqual(' Please also consider removing or updating the assigned user if it is no longer applicable.');
    expect(modalBody.find(ApplyToHousehold).exists()).toBe(false);
    expect(modalBody.find(Form.Group).length).toEqual(1);
    expect(modalBody.find(Form.Group).text()).toContain('Please include any additional details:');
    expect(modalBody.find('#reasoning').exists()).toBe(true);
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Button).at(1).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(2).text()).toEqual('Submit');
  });

  it('Toggling HoH radio buttons hides/shows household members table and updates state', () => {
    const wrapper = mount(<Jurisdiction patient={mockPatient1} current_user={mockUser1} household_members={[mockPatient2, mockPatient3, mockPatient4]} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} user_can_transfer={true} workflow={'global'} />);
    wrapper
      .find('#jurisdiction_id')
      .hostNodes()
      .simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    wrapper.find(Button).simulate('click');

    // initial radio button state
    expect(wrapper.find(ApplyToHousehold).exists()).toBe(true);
    expect(wrapper.find(CustomTable).exists()).toBe(false);
    expect(wrapper.state('apply_to_household')).toBe(false);
    expect(wrapper.find('#apply_to_household_no').hostNodes().prop('checked')).toBe(true);
    expect(wrapper.find('#apply_to_household_yes').hostNodes().prop('checked')).toBe(false);

    // change to apply to all of household
    wrapper
      .find('#apply_to_household_yes')
      .hostNodes()
      .simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.find(CustomTable).exists()).toBe(true);
    expect(wrapper.state('apply_to_household')).toBe(true);
    expect(wrapper.find('#apply_to_household_no').hostNodes().prop('checked')).toBe(false);
    expect(wrapper.find('#apply_to_household_yes').hostNodes().prop('checked')).toBe(true);

    // change back to just this monitoree
    wrapper
      .find('#apply_to_household_no')
      .hostNodes()
      .simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    expect(wrapper.find(CustomTable).exists()).toBe(false);
    expect(wrapper.state('apply_to_household')).toBe(false);
    expect(wrapper.find('#apply_to_household_no').hostNodes().prop('checked')).toBe(true);
    expect(wrapper.find('#apply_to_household_yes').hostNodes().prop('checked')).toBe(false);
  });

  it('Adding reasoning updates state', () => {
    const wrapper = getWrapper();
    const handleChangeSpy = jest.spyOn(wrapper.instance(), 'handleReasoningChange');
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Body).find('#reasoning').exists()).toBe(true);
    wrapper
      .find(Modal.Body)
      .find('#reasoning')
      .simulate('change', { target: { id: 'reasoning', value: 'insert reasoning text here' } });
    expect(handleChangeSpy).toHaveBeenCalled();
    expect(wrapper.state('reasoning')).toEqual('insert reasoning text here');
  });

  it('Clicking the cancel button closes modal and resets state', () => {
    const wrapper = getWrapper();
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    wrapper.find(Button).simulate('click');

    // closes modal
    expect(wrapper.find(Modal).exists()).toBe(true);
    wrapper.find(Button).at(1).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(false);

    // resets state
    expect(wrapper.state('showJurisdictionModal')).toBe(false);
    expect(wrapper.state('apply_to_household')).toBe(false);
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('jurisdiction_path')).toEqual(mockJurisdictionPaths[mockPatient1.jurisdiction_id]);
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getWrapper();
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    expect(submitSpy).not.toHaveBeenCalled();
    wrapper.find(Button).simulate('click');
    expect(submitSpy).not.toHaveBeenCalled();
    wrapper.find(Button).at(2).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });

  it('Pressing the enter key opens modal only when change user button is enabled', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find('#jurisdiction_id').prop('onKeyPress')({ which: 13, preventDefault: jest.fn() });
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    wrapper.find('#jurisdiction_id').prop('onKeyPress')({ which: 13, preventDefault: jest.fn() });
    expect(wrapper.find(Modal).exists()).toBe(true);
  });
});
