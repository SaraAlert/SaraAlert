import React from 'react';
import { shallow } from 'enzyme';
import { Button, Card, Form, InputGroup, OverlayTrigger } from 'react-bootstrap';

import AssessmentModal from '../../../components/patient/assessment/AssessmentModal';
import AssessmentTable from '../../../components/patient/assessment/AssessmentTable';
import ClearAssessments from '../../../components/patient/assessment/actions/ClearAssessments';
import ContactAttempt from '../../../components/patient/assessment/actions/ContactAttempt';
import CurrentStatus from '../../../components/patient/assessment/actions/CurrentStatus';
import CustomTable from '../../../components/layout/CustomTable';
import MonitoringPeriod from '../../../components/patient/assessment/actions/MonitoringPeriod';
import PauseNotifications from '../../../components/patient/assessment/actions/PauseNotifications';

import { mockPatient1, mockPatient2 } from '../../mocks/mockPatients';
import { mockAssessment1 } from '../../mocks/mockAssessments';
import { mockNewSymptoms } from '../../mocks/mockSymptoms';
import { mockTranslations } from '../../mocks/mockTranslations';
import { mockUser1 } from '../../mocks/mockUsers';

const reportEligibility = {
  eligible: false,
  household: false,
  reported: false,
  sent: false,
};
const mockToken = 'testMockTokenString12345';

function getWrapperIsolation() {
  return shallow(<AssessmentTable current_user={mockUser1} patient={mockPatient1} calculated_age={77} patient_initials={'MM'} household_members={[mockPatient2]} monitoring_period_days={14} symptoms={mockNewSymptoms} patient_status={'isolation_symp_non_test_based'} report_eligibility={reportEligibility} translations={mockTranslations} authenticity_token={mockToken} threshold_condition_hash={mockAssessment1.threshold_condition_hash} />);
}

function getWrapperExposure() {
  return shallow(<AssessmentTable current_user={mockUser1} patient={mockPatient2} calculated_age={79} patient_initials={'MM'} household_members={[mockPatient1]} monitoring_period_days={14} symptoms={mockNewSymptoms} patient_status={'exposure_symptomatic'} report_eligibility={reportEligibility} translations={mockTranslations} authenticity_token={mockToken} threshold_condition_hash={mockAssessment1.threshold_condition_hash} />);
}

describe('AssessmentTable', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapperIsolation();
    expect(wrapper.find(Card).exists()).toBe(true);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual('Reports');
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(CurrentStatus).exists()).toBe(true);
    expect(wrapper.find(InputGroup).exists()).toBe(true);
    expect(wrapper.find(CustomTable).exists()).toBe(true);
    expect(wrapper.find(MonitoringPeriod).exists()).toBe(true);
    expect(wrapper.find(AssessmentModal).exists()).toBe(false);
  });

  it('Properly renders report action button group when in isolation', () => {
    const wrapper = getWrapperIsolation();
    expect(wrapper.find(Button).exists()).toBe(true);
    expect(wrapper.find(Button).find('i').hasClass('fa-plus')).toBe(true);
    expect(wrapper.find(Button).find('span').text()).toEqual('Add New Report');
    expect(wrapper.find(ClearAssessments).exists()).toBe(true);
    expect(wrapper.find(PauseNotifications).exists()).toBe(true);
    expect(wrapper.find(ContactAttempt).exists()).toBe(true);
  });

  it('Properly renders report action button group when in exposure', () => {
    const wrapper = getWrapperExposure();
    expect(wrapper.find(Button).exists()).toBe(true);
    expect(wrapper.find(Button).find('i').hasClass('fa-plus')).toBe(true);
    expect(wrapper.find(Button).find('span').text()).toEqual('Add New Report');
    expect(wrapper.find(ClearAssessments).exists()).toBe(true);
    expect(wrapper.find(PauseNotifications).exists()).toBe(true);
    expect(wrapper.find(ContactAttempt).exists()).toBe(true);
  });

  it('Clicking "Add New Report" button shows new report modal', () => {
    const wrapper = getWrapperIsolation();
    expect(wrapper.find(AssessmentModal).exists()).toBe(false);
    expect(wrapper.state('showAddAssessmentModal')).toBe(false);
    wrapper.find(Button).simulate('click');
    expect(wrapper.find(AssessmentModal).exists()).toBe(true);
    expect(wrapper.state('showAddAssessmentModal')).toBe(true);
  });

  it('Properly renders search input', () => {
    const wrapper = getWrapperIsolation();
    expect(wrapper.find(InputGroup.Prepend).exists()).toBe(true);
    expect(wrapper.find(OverlayTrigger).exists()).toBe(true);
    expect(wrapper.find(InputGroup.Text).exists()).toBe(true);
    expect(wrapper.find(InputGroup.Text).find('i').hasClass('fa-search')).toBe(true);
    expect(wrapper.find(InputGroup.Text).find('label').text()).toEqual('Search');
    expect(wrapper.find(InputGroup).find(Form.Control).exists()).toBe(true);
  });

  it('Inputing a search term updates state and calls updateTable', () => {
    const wrapper = getWrapperIsolation();
    const handleSearchChangeSpy = jest.spyOn(wrapper.instance(), 'updateTable');
    expect(handleSearchChangeSpy).not.toHaveBeenCalled();
    expect(wrapper.state('query').search).toBeUndefined();
    wrapper.find('#reports-search-input').simulate('change', { target: { id: 'reports-search-input', value: 'search' } });
    expect(wrapper.state('query').search).toEqual('search');
    expect(handleSearchChangeSpy).toHaveBeenCalled();
  });
});
