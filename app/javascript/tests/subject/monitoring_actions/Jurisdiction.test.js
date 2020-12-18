import React from 'react'
import { shallow } from 'enzyme';
import { Button, Form, Modal } from 'react-bootstrap';
import Jurisdiction from '../../../components/subject/monitoring_actions/Jurisdiction';
import InfoTooltip from '../../../components/util/InfoTooltip';
import { mockPatient1 } from '../../mocks/mockPatients';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction'

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';

function getWrapper(patient, hasDependents) {
  return shallow(<Jurisdiction patient={patient} current_user={mockUser1} has_dependents={hasDependents}
    jurisdiction_paths={mockJurisdictionPaths} authenticity_token={authyToken} user_can_transfer={true} />);
}

describe('Jurisdiction', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper(mockPatient1, false);
    expect(wrapper.find(Form.Label).text().includes('ASSIGNED JURISDICTION')).toBeTruthy();
    expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('assignedJurisdictionCanTransfer');
    expect(wrapper.find('#jurisdiction_id').exists()).toBeTruthy();
    expect(wrapper.find('option').length).toEqual(6);
    for (var key of Object.keys(mockJurisdictionPaths)) {
      expect(wrapper.find('option').at(key-2).text()).toEqual(mockJurisdictionPaths[key]);
    }
    expect(wrapper.find('#jurisdiction_id').prop('value')).toEqual(mockJurisdictionPaths[mockPatient1.jurisdiction_id]);
    expect(wrapper.find(Button).exists()).toBeTruthy();
    expect(wrapper.find(Button).text().includes('Change Jurisdiction')).toBeTruthy();
    expect(wrapper.find('i').hasClass('fa-map-marked-alt')).toBeTruthy();
    expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
  });

  it('Changing jurisdiction enables change jurisdiction button and sets state correctly', () => {
    const wrapper = getWrapper(mockPatient1, false);
    expect(wrapper.find(Button).prop('disabled')).toBeTruthy();
    expect(wrapper.state('jurisdiction_path')).toEqual(mockJurisdictionPaths[mockPatient1.jurisdiction_id]);
    expect(wrapper.state('original_jurisdiction_id')).toEqual(mockPatient1.jurisdiction_id);

    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    expect(wrapper.find(Button).prop('disabled')).toBeFalsy();
    expect(wrapper.state('jurisdiction_path')).toEqual('USA, State 2, County 4');
    expect(wrapper.state('original_jurisdiction_id')).toEqual(mockPatient1.jurisdiction_id);
  });

  it('Changing to an invalid jurisdiction disables change jurisdiction button and sets state correctly', () => {
    const wrapper = getWrapper(mockPatient1, false);
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
    const wrapper = getWrapper(mockPatient1, false);
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders modal', () => {
    const wrapper = getWrapper(mockPatient1, false);
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    wrapper.find(Button).simulate('click');
    const modalBody = wrapper.find(Modal.Body);

    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Jurisdiction');
    expect(modalBody.exists()).toBeTruthy();
    expect(modalBody.find('p').text().includes(`Are you sure you want to change jurisdiction from "${mockJurisdictionPaths[mockPatient1.jurisdiction_id]}" to "USA, State 2, County 4"?`)).toBeTruthy();
    expect(modalBody.find('p').find('b').text()).toEqual(' Please also consider removing or updating the assigned user if it is no longer applicable.');
    expect(modalBody.find(Form.Group).length).toEqual(1);
    expect(modalBody.find(Form.Group).text().includes('Please include any additional details:')).toBeTruthy();
    expect(modalBody.find('#reasoning').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(1).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(2).text()).toEqual('Submit');
  });

  it('Properly renders radio buttons for HoH', () => {
    const wrapper = getWrapper(mockPatient1, true);
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    wrapper.find(Button).simulate('click');
    const modalBody = wrapper.find(Modal.Body);

    expect(modalBody.find(Form.Group).exists()).toBeTruthy();
    expect(modalBody.find(Form.Check).length).toEqual(2);
    expect(modalBody.find('#apply_to_household_no').prop('type')).toEqual('radio');
    expect(modalBody.find('#apply_to_household_no').prop('label')).toEqual('This monitoree only');
    expect(modalBody.find('#apply_to_household_yes').prop('type')).toEqual('radio');
    expect(modalBody.find('#apply_to_household_yes').prop('label')).toEqual('This monitoree and all household members');
  });

  it('Clicking HoH radio buttons toggles this.state.apply_to_household', () => {
      const wrapper = getWrapper(mockPatient1, true);
      wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
      wrapper.find(Button).simulate('click');

      // initial radio button state
      expect(wrapper.state('apply_to_household')).toBeFalsy();
      expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeTruthy();
      expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeFalsy();

      // change to apply to all of household
      wrapper.find('#apply_to_household_yes').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
      wrapper.update()
      expect(wrapper.state('apply_to_household')).toBeTruthy();
      expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeFalsy();
      expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeTruthy();

      // change back to just this monitoree
      wrapper.find('#apply_to_household_no').simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
      wrapper.update()
      expect(wrapper.state('apply_to_household')).toBeFalsy();
      expect(wrapper.find('#apply_to_household_no').prop('checked')).toBeTruthy();
      expect(wrapper.find('#apply_to_household_yes').prop('checked')).toBeFalsy();
  });

  it('Adding reasoning updates state', () => {
    const wrapper = getWrapper(mockPatient1, false);
    const handleChangeSpy = jest.spyOn(wrapper.instance(), 'handleReasoningChange');
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    wrapper.find(Button).simulate('click');

    expect(wrapper.find(Modal.Body).find('#reasoning').exists()).toBeTruthy();
    wrapper.find(Modal.Body).find('#reasoning').simulate('change', { target: { id: 'reasoning', value: 'insert reasoning text here' } });
    expect(handleChangeSpy).toHaveBeenCalled();
    expect(wrapper.state('reasoning')).toEqual('insert reasoning text here');
  });

  it('Clicking the cancel button closes modal and resets state', () => {
    const wrapper = getWrapper(mockPatient1, false);
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    wrapper.find(Button).simulate('click');

    // closes modal
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Button).at(1).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();

    // resets state
    expect(wrapper.state('showJurisdictionModal')).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('jurisdiction_path')).toEqual(mockJurisdictionPaths[mockPatient1.jurisdiction_id]);
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getWrapper(mockPatient1, false);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');

    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).simulate('click');
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(2).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });

  it('Pressing the enter key opens modal only when change user button is enabled', () => {
    const wrapper = getWrapper(mockPatient1, false);
    expect(wrapper.find(Modal).exists()).toBeFalsy();

    wrapper.find('#jurisdiction_id').prop('onKeyPress')({ which: 13, preventDefault: jest.fn() });
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#jurisdiction_id').simulate('change', { target: { id: 'jurisdiction_id', value: 'USA, State 2, County 4' } });
    wrapper.find('#jurisdiction_id').prop('onKeyPress')({ which: 13, preventDefault: jest.fn() });
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });
});
