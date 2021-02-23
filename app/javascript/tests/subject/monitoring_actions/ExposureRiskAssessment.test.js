import React from 'react';
import { shallow, mount } from 'enzyme';
import { Button, Modal, Form } from 'react-bootstrap';
import ExposureRiskAssessment from '../../../components/subject/monitoring_actions/ExposureRiskAssessment';
import ApplyToHousehold from '../../../components/subject/household_actions/ApplyToHousehold';
import InfoTooltip from '../../../components/util/InfoTooltip';
import CustomTable from '../../../components/layout/CustomTable';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4 } from '../../mocks/mockPatients';

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const exposureRiskAssessmentOptions = [ '', 'High', 'Medium', 'Low', 'No Identified Risk' ];

function getWrapper() {
  return shallow(<ExposureRiskAssessment patient={mockPatient1} household_members={[]} current_user={mockUser1}
    jurisdiction_paths={mockJurisdictionPaths} authenticity_token={authyToken} />);
}

describe('ExposureRiskAssessment', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Form.Label).text().includes('EXPOSURE RISK ASSESSMENT')).toBeTruthy();
    expect(wrapper.find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('exposureRiskAssessment');
    expect(wrapper.find('#exposure_risk_assessment').exists()).toBeTruthy();
    expect(wrapper.find('option').length).toEqual(5);
    exposureRiskAssessmentOptions.forEach(function(value, index) {
        expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#exposure_risk_assessment').prop('value')).toEqual(mockPatient1.exposure_risk_assessment);
  });

  it('Changing Exposure Risk Assessment opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders modal and sets state correctly', () => {
    const wrapper = getWrapper();
    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });
    
    // renders properly
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Exposure Risk Assessment');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').text()).toEqual(`Are you sure you want to change exposure risk assessment to "High"?`);
    expect(wrapper.find(Modal.Body).find(ApplyToHousehold).exists()).toBeFalsy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');

    // sets state correctly
    expect(wrapper.state('showExposureRiskAssessmentModal')).toBeTruthy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('exposure_risk_assessment')).toEqual('High');
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Toggling HoH radio buttons hides/shows household members table and updates state', () => {
    const wrapper = mount(<ExposureRiskAssessment patient={mockPatient1} household_members={[ mockPatient2, mockPatient3, mockPatient4 ]}
      current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={authyToken} />);
    wrapper.find('#exposure_risk_assessment').at(1).simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });

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
    const wrapper = getWrapper();
    const handleChangeSpy = jest.spyOn(wrapper.instance(), 'handleReasoningChange');
    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });

    expect(wrapper.find('#reasoning').exists()).toBeTruthy();
    wrapper.find('#reasoning').simulate('change', { target: { id: 'reasoning', value: 'insert reasoning text here' } });
    expect(handleChangeSpy).toHaveBeenCalled();
    expect(wrapper.state('reasoning')).toEqual('insert reasoning text here');
  });

  it('Clicking the cancel button closes Exposure Risk Assessment modal and resets state', () => {
    const wrapper = getWrapper();
    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });

    // closes modal
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();

    // resets state
    expect(wrapper.state('showExposureRiskAssessmentModal')).toBeFalsy();
    expect(wrapper.state('apply_to_household')).toBeFalsy();
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('exposure_risk_assessment')).toEqual(mockPatient1.exposure_risk_assessment);
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getWrapper();
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');

    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });
    expect(submitSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
