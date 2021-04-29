import React from 'react';
import { shallow } from 'enzyme';
import { Button, Form, InputGroup, Modal } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import _ from 'lodash';
import ChangeHoH from '../../../../components/patient/household/actions/ChangeHoH';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4 } from '../../../mocks/mockPatients';
import { nameFormatterAlt } from '../../../util.js';

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";
const dependents = [ mockPatient2, mockPatient3, mockPatient4 ];

function getWrapper() {
  return shallow(<ChangeHoH patient={mockPatient1} dependents={dependents} authenticity_token={authyToken} />);
}

describe('ChangeHoH', () => {
  it('Properly renders Change HoH button', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Button).length).toEqual(1);
    expect(wrapper.find(Button).text().includes('Change Head of Household')).toBeTruthy();
    expect(wrapper.find('i').hasClass('fa-house-user')).toBeTruthy();
    expect(wrapper.find(Button).prop('disabled')).toBeFalsy();
    expect(wrapper.find(ReactTooltip).exists()).toBeFalsy();
  });

  it('Clicking the Change HoH button opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.state('showModal')).toBeFalsy();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('showModal')).toBeTruthy();
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders Change HoH modal', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Header).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Edit Head of Household');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find(Form.Label).at(0).text()).toEqual('Select The New Head Of Household');
    expect(wrapper.find(Modal.Body).find(Form.Label).at(1).text()).toEqual('Note: The selected monitoree will become the responder for the current monitoree and all others within the list');
    expect(wrapper.find('#hoh_selection').exists()).toBeTruthy();
    expect(wrapper.find('#hoh_selection').prop('defaultValue')).toEqual(-1);
    expect(wrapper.find('#hoh_selection').find('option').length).toEqual(dependents.length+1);
    expect(wrapper.find('#hoh_selection').find('option').at(0).prop('value')).toEqual(-1);
    expect(wrapper.find('#hoh_selection').find('option').at(0).prop('disabled')).toBeTruthy();  
    expect(wrapper.find('#hoh_selection').find('option').at(0).text()).toEqual('--');
    dependents.forEach((dependent, index) => {
      expect(wrapper.find('#hoh_selection').find('option').at(index+1).prop('value')).toEqual(dependent.id);
      expect(wrapper.find('#hoh_selection').find('option').at(index+1).prop('disabled')).toBeFalsy();
      expect(wrapper.find('#hoh_selection').find('option').at(index+1).text()).toEqual(nameFormatterAlt(dependent));
    });
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(0).prop('disabled')).toBeFalsy();
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Update');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeTruthy();
  });

  it('Changing HoH dropdown selection properly updates state', () => {
    const wrapper = getWrapper();
    let random = _.random(0, dependents.length - 1);
    wrapper.find(Button).simulate('click');
    expect(wrapper.state('hoh_selection')).toEqual(null);
    wrapper.find('#hoh_selection').simulate('change', { target: { id: 'hoh_selection', value: dependents[random].id } });
    expect(wrapper.state('hoh_selection')).toEqual(dependents[random].id);
    random = _.random(0, dependents.length - 1);
    wrapper.find('#hoh_selection').simulate('change', { target: { id: 'hoh_selection', value: dependents[random].id } });
    expect(wrapper.state('hoh_selection')).toEqual(dependents[random].id);
    random = _.random(0, dependents.length - 1);
    wrapper.find('#hoh_selection').simulate('change', { target: { id: 'hoh_selection', value: dependents[random].id } });
    expect(wrapper.state('hoh_selection')).toEqual(dependents[random].id);
  });

  it('Selecting a dependent enables the update button', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeTruthy();
    wrapper.find('#hoh_selection').simulate('change', { target: { id: 'hoh_selection', value: dependents[0].id } });
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeFalsy();
  });

  it('Clicking the update button calls the submit method', () => {
    const wrapper = getWrapper();
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.find(Button).simulate('click');
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find('#hoh_selection').simulate('change', { target: { id: 'hoh_selection', value: dependents[0].id } });
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Modal.Footer).find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });

  it('Clicking the update button disables the button and updates state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#hoh_selection').simulate('change', { target: { id: 'hoh_selection', value: dependents[0].id } });
    expect(wrapper.state('loading')).toBeFalsy();
    expect(wrapper.state('showModal')).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeFalsy();
    wrapper.find(Modal.Footer).find(Button).at(1).simulate('click');
    expect(wrapper.state('loading')).toBeTruthy();
    expect(wrapper.state('showModal')).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find(Button).at(1).prop('disabled')).toBeTruthy();
  });

  it('Clicking the cancel button closes modal and resets state', () => {
    const wrapper = getWrapper();
    wrapper.find(Button).simulate('click');
    wrapper.find('#hoh_selection').simulate('change', { target: { id: 'hoh_selection', value: dependents[0].id } });
    expect(wrapper.state('hoh_selection')).toEqual(dependents[0].id);
    expect(wrapper.state('showModal')).toBeTruthy();
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Modal.Footer).find(Button).at(0).simulate('click');
    expect(wrapper.state('hoh_selection')).toEqual(null);
    expect(wrapper.state('showModal')).toBeFalsy();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
  });
});
