import React from 'react'
import { shallow } from 'enzyme';
import { Button, Modal } from 'react-bootstrap';
import ClearAssessments from '../../../components/assessment/steps/ClearAssessments.js'
import { mockPatient1, mockPatient2 } from '../../mocks/mockPatients'

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

function getWrapper(patient) {
    return shallow(<ClearAssessments patient={patient} authenticity_token={authyToken} />);
}

describe('ClearAssessments', () => {
  it('Properly renders "Mark All As Reviewed" button', () => {
    const wrapper = getWrapper(mockPatient1);
    expect(wrapper.find(Button).length).toEqual(1);
    expect(wrapper.find(Button).text().includes('Mark All As Reviewed')).toBeTruthy();
    expect(wrapper.find('i').hasClass('fa-check')).toBeTruthy();
  });

  it('Clicking the "Mark All As Reviewed" button opens modal', () => {
    const wrapper = getWrapper(mockPatient1);
    expect(wrapper.find(Modal).exists()).toBeFalsy();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
  });

  it('Properly renders modal', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Mark All As Reviewed');
    expect(wrapper.find(Modal.Body).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('p').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Body).find('#reasoning').exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Footer).find(Button).length).toEqual(2);
    expect(wrapper.find(Modal.Footer).find(Button).at(0).text()).toEqual('Cancel');
    expect(wrapper.find(Modal.Footer).find(Button).at(1).text()).toEqual('Submit');
  });

  it('Properly renders modal text if monitoree is in exposure', () => {
    const wrapper = getWrapper(mockPatient2);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('p').text()).toEqual(`You are about to clear all symptomatic report flags (red highlight) on this record. This indicates that the disease of interest is not suspected after review of all of the monitoree's symptomatic reports. The \"Needs Review\" status will be changed to \"No\" for all reports. The record will move from the symptomatic line list to the asymptomatic or non-reporting line list as appropriate unless a symptom onset date has been entered by a user.`);
    expect(wrapper.find('b').text()).toEqual(' unless a symptom onset date has been entered by a user.');
  });

  it('Properly renders modal text if monitoree is in isolation', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find('p').text()).toEqual(`This will change any reports where the \"Needs Review\" column is \"Yes\" to \"No\". If this case is currently under the \"Records Requiring Review\" line list, they will be moved to the \"Reporting\" or \"Non-Reporting\" line list as appropriate until a recovery definition is met.`);
  });

  it('Adding reasoning updates state', () => {
    const wrapper = getWrapper(mockPatient1);
    const handleChangeSpy = jest.spyOn(wrapper.instance(), 'handleChange');
    wrapper.find(Button).simulate('click');

    expect(wrapper.find('#reasoning').exists()).toBeTruthy();
    wrapper.find('#reasoning').simulate('change', { target: { id: 'reasoning', value: 'insert reasoning text here' } });
    expect(handleChangeSpy).toHaveBeenCalled();
    expect(wrapper.state('reasoning')).toEqual('insert reasoning text here');
  });

  it('Clicking the modal submit button calls the ClearAssessments function', () => {
    const wrapper = getWrapper(mockPatient1);
    const handleClearAssessmentsSpy = jest.spyOn(wrapper.instance(), 'ClearAssessments');
    wrapper.find(Button).simulate('click');
    expect(handleClearAssessmentsSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).at(2).simulate('click');
    expect(handleClearAssessmentsSpy).toHaveBeenCalledTimes(1);
  });

  it('Clicking the modal cancel button closes the modal', () => {
    const wrapper = getWrapper(mockPatient1);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    wrapper.find(Button).at(1).simulate('click');
    expect(wrapper.find(Modal).exists()).toBeFalsy();
  });
});