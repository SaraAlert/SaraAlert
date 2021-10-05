import React from 'react';
import { shallow, mount } from 'enzyme';
import { Button, Modal, Form } from 'react-bootstrap';
import ExposureRiskAssessment from '../../../components/patient/monitoring_actions/ExposureRiskAssessment';
import ApplyToHousehold from '../../../components/patient/household/actions/ApplyToHousehold';
import InfoTooltip from '../../../components/util/InfoTooltip';
import CustomTable from '../../../components/layout/CustomTable';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockPatient1, mockPatient2, mockPatient3, mockPatient4 } from '../../mocks/mockPatients';

const mockToken = 'testMockTokenString12345';
const exposureRiskAssessmentOptions = ['', 'High', 'Medium', 'Low', 'No Identified Risk'];

function getWrapper() {
  return shallow(<ExposureRiskAssessment patient={mockPatient1} household_members={[]} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} workflow={'global'} />);
}

describe('ExposureRiskAssessment', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Form.Label).text()).toContain('EXPOSURE RISK ASSESSMENT');
    expect(wrapper.find(InfoTooltip).exists()).toBe(true);
    expect(wrapper.find(InfoTooltip).prop('tooltipTextKey')).toEqual('exposureRiskAssessment');
    expect(wrapper.find('#exposure_risk_assessment').exists()).toBe(true);
    expect(wrapper.find('option').length).toEqual(5);
    exposureRiskAssessmentOptions.forEach((value, index) => {
      expect(wrapper.find('option').at(index).text()).toEqual(value);
    });
    expect(wrapper.find('#exposure_risk_assessment').prop('value')).toEqual(mockPatient1.exposure_risk_assessment);
  });

  it('Changing Exposure Risk Assessment opens modal', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Modal).exists()).toBe(false);
    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });
    expect(wrapper.find(Modal).exists()).toBe(true);
  });

  it('Properly renders modal and sets state correctly', () => {
    const wrapper = getWrapper();
    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });

    // renders properly
    expect(wrapper.find(Modal.Title).exists()).toBe(true);
    expect(wrapper.find(Modal.Title).text()).toEqual('Exposure Risk Assessment');
    expect(wrapper.find(Modal.Body).exists()).toBe(true);
    expect(wrapper.find(Modal.Body).find('p').text()).toEqual(`Are you sure you want to change exposure risk assessment to "High"?`);
    expect(wrapper.find(Modal.Body).find(ApplyToHousehold).exists()).toBe(false);
    expect(wrapper.find(Modal.Footer).exists()).toBe(true);
    expect(wrapper.find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Button).at(1).text()).toEqual('Submit');

    // sets state correctly
    expect(wrapper.state('showExposureRiskAssessmentModal')).toBe(true);
    expect(wrapper.state('apply_to_household')).toBe(false);
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('exposure_risk_assessment')).toEqual('High');
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Toggling HoH radio buttons hides/shows household members table and updates state', () => {
    const wrapper = mount(<ExposureRiskAssessment patient={mockPatient1} household_members={[mockPatient2, mockPatient3, mockPatient4]} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} workflow={'global'} />);
    wrapper
      .find('#exposure_risk_assessment')
      .hostNodes()
      .simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });

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
    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });

    expect(wrapper.find('#reasoning').exists()).toBe(true);
    wrapper.find('#reasoning').simulate('change', { target: { id: 'reasoning', value: 'insert reasoning text here' } });
    expect(handleChangeSpy).toHaveBeenCalled();
    expect(wrapper.state('reasoning')).toEqual('insert reasoning text here');
  });

  it('Clicking the cancel button closes Exposure Risk Assessment modal and resets state', () => {
    const wrapper = getWrapper();
    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });

    // closes modal
    expect(wrapper.find(Modal).exists()).toBe(true);
    wrapper.find(Button).at(0).simulate('click');
    expect(wrapper.find(Modal).exists()).toBe(false);

    // resets state
    expect(wrapper.state('showExposureRiskAssessmentModal')).toBe(false);
    expect(wrapper.state('apply_to_household')).toBe(false);
    expect(wrapper.state('apply_to_household_ids')).toEqual([]);
    expect(wrapper.state('exposure_risk_assessment')).toEqual(mockPatient1.exposure_risk_assessment);
    expect(wrapper.state('reasoning')).toEqual('');
  });

  it('Clicking the submit button calls the submit method', () => {
    const wrapper = getWrapper();
    const submitSpy = jest.spyOn(wrapper.instance(), 'submit');

    wrapper.find('#exposure_risk_assessment').simulate('change', { target: { id: 'exposure_risk_assessment', value: 'High' } });
    expect(submitSpy).not.toHaveBeenCalled();
    wrapper.find(Button).at(1).simulate('click');
    expect(submitSpy).toHaveBeenCalled();
  });
});
