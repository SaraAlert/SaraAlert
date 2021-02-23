import React from 'react';
import { shallow, mount } from 'enzyme';
import { Button, Modal, Form } from 'react-bootstrap';
import PublicHealthAction from '../../../components/subject/monitoring_actions/PublicHealthAction';
import ApplyToHousehold from '../../../components/subject/household_actions/ApplyToHousehold';
import CustomTable from '../../../components/layout/CustomTable';
import InfoTooltip from '../../../components/util/InfoTooltip';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4 } from '../../mocks/mockPatients';

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const publicHealthActionOptions = [ 'None', 'Recommended medical evaluation of symptoms', 'Document results of medical evaluation', 'Recommended laboratory testing' ];

function getWrapper(patient) {
  return shallow(<PublicHealthAction patient={patient} household_members={[]} current_user={mockUser1}
    jurisdiction_paths={mockJurisdictionPaths} authenticity_token={authyToken} />);
}

function getMountedWrapper(patient) {
  return mount(<PublicHealthAction patient={patient} household_members={[ mockPatient3, mockPatient4 ]}
    current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={authyToken} />);
}

describe('PublicHealthAction', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper(mockPatient1);
    expect(wrapper.find(Form.Label).text().includes('LATEST PUBLIC HEALTH ACTION')).toBeTruthy();
    expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('latestPublicHealthActionInIsolation');
    expect(wrapper.find('#public_health_action').exists()).toBeTruthy();
    expect(wrapper.find('option').length).toEqual(4);
    publicHealthActionOptions.forEach(function(value, index) {
        expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#public_health_action').prop('value')).toEqual(mockPatient1.public_health_action);
  });

  it('Changing Public Health Action opens modal', () => {
    const wrapper = getWrapper(mockPatient1);
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#public_health_action').simulate('change', { target: { id: 'public_health_action', value: 'Recommended laboratory testing' } });
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders modal and sets state correctly for monitorees in the closed line list', () => {
    const wrapper = getWrapper(mockPatient3);
    wrapper.find('#public_health_action').simulate('change', { target: { id: 'public_health_action', value: 'Recommended laboratory testing' } });

    // renders properly
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Public Health Action');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').text().includes(`Are you sure you want to change latest public health action to "Recommended laboratory testing"?`)).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').find('b').text()).toEqual(` Since this record is on the "Closed" line list, updating this value will not move this record to another line list. If this individual should be actively monitored, please update the record's Monitoring Status.`);
    expect(wrapper.find(Modal.Body).find(ApplyToHousehold).exists()).toBeFalsy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');

    // sets state correctly
    expect(wrapper.state('showPublicHealthActionModal')).toBeTruthy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('public_health_action')).toEqual('Recommended laboratory testing');
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Properly renders modal and sets state correctly for monitorees in the isolation workflow', () => {
    const wrapper = getMountedWrapper(mockPatient1);
    wrapper.find('#public_health_action').at(1).simulate('change', { target: { id: 'public_health_action', value: 'Recommended laboratory testing' } });
    
    // renders properly
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Public Health Action');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').at(0).text().includes(`Are you sure you want to change latest public health action to "Recommended laboratory testing"?`)).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').at(0).find('b').text()).toEqual(' This will not impact the line list on which this record appears.');
    expect(wrapper.find(Modal.Body).find('i').exists()).toBeFalsy();
    expect(wrapper.find(Modal.Body).find(ApplyToHousehold).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');

    // sets state correctly
    expect(wrapper.state('showPublicHealthActionModal')).toBeTruthy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('public_health_action')).toEqual('Recommended laboratory testing');
    expect(wrapper.state('reasoning')).toEqual('');

    // renders household warning if apply_to_household selected
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.find(Modal.Body).find(Form.Group).at(1).find('i').text()).toEqual(`If any household members are being monitored in the exposure workflow, those records will appear on the PUI line list if any public health action other than "None" is selected above. If any household members are being monitored in the isolation workflow, this update will not impact the line list on which those records appear.`);
  });

  it('Properly renders modal and sets state correctly for monitorees in the exposure workflow', () => {
    const wrapper = getMountedWrapper(mockPatient2);
    wrapper.find('#public_health_action').at(1).simulate('change', { target: { id: 'public_health_action', value: 'Recommended laboratory testing' } });
    
    // renders properly
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Public Health Action');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').at(0).text().includes(`Are you sure you want to change latest public health action to "Recommended laboratory testing"?`)).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').at(0).find('b').text()).toEqual(' The monitoree will be moved into the PUI line list.');
    expect(wrapper.find(Modal.Body).find('i').exists()).toBeFalsy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');

    // sets state correctly
    expect(wrapper.state('showPublicHealthActionModal')).toBeTruthy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('public_health_action')).toEqual('Recommended laboratory testing');
    expect(wrapper.state('reasoning')).toEqual('');

    // renders household warning if apply_to_household selected
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.find(Modal.Body).find(Form.Group).at(1).find('i').text()).toEqual(`If any household members are being monitored in the exposure workflow, those records will appear on the PUI line list if any public health action other than "None" is selected above. If any household members are being monitored in the isolation workflow, this update will not impact the line list on which those records appear.`);
  });

  it('Toggling HoH radio buttons hides/shows household members table and updates state', () => {
    const wrapper = getMountedWrapper(mockPatient1);
    wrapper.find('#public_health_action').at(1).simulate('change', { target: { id: 'public_health_action', value: 'Recommended laboratory testing' } });
    
    // initial radio button state
    expect(wrapper.find(ApplyToHousehold).exists()).toBeTruthy();
    expect(wrapper.find(CustomTable).exists()).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_no').at(1).prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').at(1).prop('checked')).toBeFalsy();

    // change to apply to all of household
    wrapper.find('#apply_to_household_yes').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_yes' } });
    expect(wrapper.find(CustomTable).exists()).toBeTruthy();
    expect(wrapper.state('apply_to_household')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_no').at(1).prop('checked')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_yes').at(1).prop('checked')).toBeTruthy();

    // change back to just this monitoree
    wrapper.find('#apply_to_household_no').at(1).simulate('change', { target: { name: 'apply_to_household', id: 'apply_to_household_no' } });
    expect(wrapper.find(CustomTable).exists()).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.find('#apply_to_household_no').at(1).prop('checked')).toBeTruthy();
    expect(wrapper.find('#apply_to_household_yes').at(1).prop('checked')).toBeFalsy();
  });


  it('Adding reasoning updates state', () => {
    const wrapper = getWrapper(mockPatient1);
    const handleChangeSpy = jest.spyOn(wrapper.instance(), 'handleReasoningChange');
    wrapper.find('#public_health_action').simulate('change', { target: { id: 'public_health_action', value: 'Recommended laboratory testing' } });
    expect(wrapper.find('#reasoning').exists()).toBeTruthy();
    wrapper.find('#reasoning').simulate('change', { target: { id: 'reasoning', value: 'insert reasoning text here' } });
    expect(handleChangeSpy).toHaveBeenCalled();
    expect(wrapper.state('reasoning')).toEqual('insert reasoning text here');
  });

  it('Clicking the cancel button closes modal and resets state', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find('#public_health_action').simulate('change', { target: { id: 'public_health_action', value: 'Recommended laboratory testing' } });

    // closes modal
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();

    // resets state
    expect(wrapper.state('showPublicHealthActionModal')).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('public_health_action')).toEqual(mockPatient1.public_health_action);
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getWrapper(mockPatient1);
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');
    wrapper.find('#public_health_action').simulate('change', { target: { id: 'public_health_action', value: 'Recommended laboratory testing' } });
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
