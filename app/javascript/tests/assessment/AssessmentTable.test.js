import React from 'react'
import { shallow } from 'enzyme';
import { Button, Card, Form, InputGroup, OverlayTrigger } from 'react-bootstrap';
import AssessmentTable from '../../components/assessment/AssessmentTable.js';
import ClearAssessments from '../../components/assessment/steps/ClearAssessments';
import ContactAttempt from '../../components/subject/ContactAttempt.js';
import CurrentStatus from '../../components/subject/CurrentStatus.js';
import CustomTable from '../../components/layout/CustomTable.js';
import LastDateExposure from '../../components/subject/LastDateExposure.js';
import PauseNotifications from '../../components/subject/PauseNotifications.js';
import AssessmentModal from '../../components/assessment/AssessmentModal';

import { mockPatient1, mockPatient2 } from '../mocks/mockPatients'
import { mockAssessment1 } from '../mocks/mockAssessments'
import { mockNewSymptoms } from '../mocks/mockSymptoms.js';
import { mockTranslations } from '../mocks/mockTranslations'
import { mockUser1 } from '../mocks/mockUsers'

const reportEligibility = {
  eligible: false,
  household: false,
  reported: false,
  sent: false
}
const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';

function getWrapperIsolation() {
  return shallow(<AssessmentTable current_user={mockUser1} patient={mockPatient1} calculated_age={77} patient_initials={'MM'}
    is_household_member={true} monitoring_period_days={14} symptoms={mockNewSymptoms} patient_status={'isolation_symp_non_test_based'}
    report_eligibility={reportEligibility} translations={mockTranslations} authenticity_token={authyToken}
    threshold_condition_hash={mockAssessment1.threshold_condition_hash} />);
}

function getWrapperExposure() {
  return shallow(<AssessmentTable current_user={mockUser1} patient={mockPatient2} calculated_age={79} patient_initials={'MM'}
    is_household_member={true} monitoring_period_days={14} symptoms={mockNewSymptoms} patient_status={'exposure_symptomatic'}
    report_eligibility={reportEligibility} translations={mockTranslations} authenticity_token={authyToken}
    threshold_condition_hash={mockAssessment1.threshold_condition_hash} />);
}

describe('AssessmentTable', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapperIsolation();
    expect(wrapper.find(Card).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).text()).toEqual('Reports');
    expect(wrapper.find(Card.Body).exists()).toBeTruthy();
    expect(wrapper.find(CurrentStatus).exists()).toBeTruthy();
    expect(wrapper.find(InputGroup).exists()).toBeTruthy();
    expect(wrapper.find(CustomTable).exists()).toBeTruthy();
    expect(wrapper.find(LastDateExposure).exists()).toBeTruthy();
    expect(wrapper.find(AssessmentModal).exists()).toBeFalsy();
  });

  it('Properly renders report action button group when in isolation', () => {
    const wrapper = getWrapperIsolation();
    expect(wrapper.find(Button).exists()).toBeTruthy();
    expect(wrapper.find(Button).find('i').hasClass('fa-plus')).toBeTruthy();
    expect(wrapper.find(Button).find('span').text()).toEqual('Add New Report');
    expect(wrapper.find(ClearAssessments).exists()).toBeFalsy();
    expect(wrapper.find(PauseNotifications).exists()).toBeTruthy();
    expect(wrapper.find(ContactAttempt).exists()).toBeTruthy();
  });

  it('Properly renders report action button group when in exposure', () => {
    const wrapper = getWrapperExposure();
    expect(wrapper.find(Button).exists()).toBeTruthy();
    expect(wrapper.find(Button).find('i').hasClass('fa-plus')).toBeTruthy();
    expect(wrapper.find(Button).find('span').text()).toEqual('Add New Report');
    expect(wrapper.find(ClearAssessments).exists()).toBeTruthy();
    expect(wrapper.find(PauseNotifications).exists()).toBeTruthy();
    expect(wrapper.find(ContactAttempt).exists()).toBeTruthy();
  });

  it('Clicking "Add New Report" button shows new report modal', () => {
    const wrapper = getWrapperIsolation();
    expect(wrapper.find(AssessmentModal).exists()).toBeFalsy();
    expect(wrapper.state('showAddAssessmentModal')).toBeFalsy();
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(AssessmentModal).exists()).toBeTruthy();
    expect(wrapper.state('showAddAssessmentModal')).toBeTruthy();
  });

  it('Properly renders search input', () => {
    const wrapper = getWrapperIsolation();
    expect(wrapper.find(InputGroup.Prepend).exists()).toBeTruthy();
    expect(wrapper.find(OverlayTrigger).exists()).toBeTruthy();
    expect(wrapper.find(InputGroup.Text).exists()).toBeTruthy();
    expect(wrapper.find(InputGroup.Text).find('i').hasClass('fa-search')).toBeTruthy();
    expect(wrapper.find(InputGroup.Text).find('label').text()).toEqual('Search');
    expect(wrapper.find(InputGroup).find(Form.Control).exists()).toBeTruthy();
  });

  it('Inputing a search term updates state and calls updateTable', () => {
    const wrapper = getWrapperIsolation();
    const handleSearchChangeSpy = jest.spyOn(wrapper.instance(), 'updateTable');
    expect(handleSearchChangeSpy).toHaveBeenCalledTimes(0);
    expect(wrapper.state('query').search).toEqual(undefined);
    wrapper.find('#reports-search-input').simulate('change', { target: { id: 'reports-search-input', value: 'search' } });
    expect(wrapper.state('query').search).toEqual('search');
    expect(handleSearchChangeSpy).toHaveBeenCalled();
  });
});
