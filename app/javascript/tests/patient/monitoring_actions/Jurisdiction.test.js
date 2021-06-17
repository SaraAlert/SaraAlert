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
    expect(wrapper.find(Form.Label).text().includes('ASSIGNED JURISDICTION')).toBeTruthy();
    expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('assignedJurisdictionCanTransfer');
    expect(wrapper.find('#jurisdiction_id').exists()).toBeTruthy();
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
    expect(wrapper.find(Button).exists()).toBeTruthy();
    expect(wrapper.find(Button).text().includes('Change Jurisdiction')).toBeTruthy();
    expect(wrapper.find('i').hasClass('fa-map-marked-alt')).toBeTruthy();
    expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
  });

  it('Changing jurisdiction enables change jurisdiction button and sets state correctly', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
    expect(wrapper.state('jurisdiction_path')).toEqual(mockJurisdictionPaths[mockPatient1.jurisdiction_id]);
    expect(wrapper.state('original_jurisdiction_id')).toEqual(mockPatient1.jurisdiction_id);
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    expect(wrapper.find(Button).prop('disabled')).toBeFalsy();
    expect(wrapper.state('jurisdiction_path')).toEqual('USA, State 2, County 4');
    expect(wrapper.state('original_jurisdiction_id')).toEqual(mockPatient1.jurisdiction_id);
  });

  it('Changing to an invalid jurisdiction disables change jurisdiction button and sets state correctly', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
    expect(wrapper.state('validJurisdiction')).toEqual(true);
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    expect(wrapper.find(Button).prop('disabled')).toBeFalsy();
    expect(wrapper.state('validJurisdiction')).toEqual(true);
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 3' } });
    expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
    expect(wrapper.state('validJurisdiction')).toEqual(false);
  });

  it('Clicking change jurisdiction button opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders modal', () => {
    const wrapper = getWrapper();
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    wrapper.find(Button).simulate('click');
    const modalBody = wrapper.find(Modal.Body);
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Jurisdiction');
    expect(modalBody.exists()).toBeTruthy();
    expect(modalBody.find('p').text().includes(`Are you sure you want to change jurisdiction from "${mockJurisdictionPaths[mockPatient1.jurisdiction_id]}" to "USA, State 2, County 4"?`)).toBeTruthy();
    expect(modalBody.find('p').find('b').text()).toEqual(' Please also consider removing or updating the assigned user if it is no longer applicable.');
    expect(modalBody.find(ApplyToHousehold).exists()).toBeFalsy();
    expect(modalBody.find(Form.Group).length).toEqual(1);
    expect(modalBody.find(Form.Group).text().includes('Please include any additional details:')).toBeTruthy();
    expect(modalBody.find('#reasoning').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(1).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(2).text()).toEqual('Submit');
  });

  it('Toggling HoH radio buttons hides/shows household members table and updates state', () => {
    const wrapper = mount(<Jurisdiction patient={mockPatient1} current_user={mockUser1} household_members={[mockPatient2, mockPatient3, mockPatient4]} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} user_can_transfer={true} workflow={'global'} />);
    wrapper
      .find('#jurisdiction_id')
      .at(1)
      .simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    wrapper.find(Button).simulate('click');

    // initial radio button state
    expect(wrapper.find(ApplyToHousehold).exists()).toBeTruthy();
    expect(wrapper.find(CustomTable).exists()).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_no').at(1).prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').at(1).prop('checked')).toBeFalsy();

    // change to apply to all of household
    wrapper
      .find('#apply_to_household_yes')
      .at(1)
      .simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.find(CustomTable).exists()).toBeTruthy();
    expect(wrapper.state('apply_to_household')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_no').at(1).prop('checked')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_yes').at(1).prop('checked')).toBeTruthy();

    // change back to just this monitoree
    wrapper
      .find('#apply_to_household_no')
      .at(1)
      .simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    expect(wrapper.find(CustomTable).exists()).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_no').at(1).prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').at(1).prop('checked')).toBeFalsy();
  });

  it('Adding reasoning updates state', () => {
    const wrapper = getWrapper();
    const handleChangeSpy = jest.spyOn(wrapper.instance(), 'handleReasoningChange');
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Body).find('#reasoning').exists()).toBeTruthy();
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
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Button).at(1).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();

    // resets state
    expect(wrapper.state('showJurisdictionModal')).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('jurisdiction_path')).toEqual(mockJurisdictionPaths[mockPatient1.jurisdiction_id]);
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getWrapper();
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).simulate('click');
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(2).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });

  it('Pressing the enter key opens modal only when change user button is enabled', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#jurisdiction_id').prop('onKeyPress')({ which: 13, preventDefault: jest.fn() });
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    wrapper.find('#jurisdiction_id').prop('onKeyPress')({ which: 13, preventDefault: jest.fn() });
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });
});
