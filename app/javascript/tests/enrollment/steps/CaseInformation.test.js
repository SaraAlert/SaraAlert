import React from 'react';
import { shallow, mount } from 'enzyme';
import CaseInformation from '../../../components/enrollment/steps/CaseInformation';
import { blankMockPatient, mockPatient4 } from '../../mocks/mockPatients';
import { mockJurisdiction1, mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockLaboratory1 } from '../../mocks/mockLaboratories';

const newEnrollmentState = {
  isolation: false,
  patient: blankMockPatient,
  propagatedFields: {},
};

const requiredStrings = ['SYMPTOM ONSET DATE', 'POSITIVE LAB RESULT', 'CASE STATUS', 'NOTES'];

describe('CaseInformation', () => {
  it('Properly renders all main components', () => {
    const wrapper = mount(<CaseInformation goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} patient={blankMockPatient} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} selected_jurisdiction={mockJurisdiction1} first_positive_lab={mockLaboratory1} edit_mode={false} authenticity_token={'123'} />);
    requiredStrings.forEach(requiredString => {
      expect(wrapper.text().includes(requiredString)).toBe(true);
    });
  });

  it('Properly shows the `Next` button', () => {
    const wrapper = shallow(<CaseInformation goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} patient={blankMockPatient} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} selected_jurisdiction={mockJurisdiction1} first_positive_lab={mockLaboratory1} edit_mode={false} authenticity_token={'123'} />);
    const button = wrapper.find('.btn-square');
    expect(button.at(0).text()).toEqual('Next');
  });

  it('Properly shows the `Previous` button', () => {
    const wrapper = shallow(<CaseInformation goto={() => {}} next={() => {}} previous={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} patient={blankMockPatient} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} selected_jurisdiction={mockJurisdiction1} first_positive_lab={mockLaboratory1} edit_mode={false} authenticity_token={'123'} />);
    const button = wrapper.find('.btn-square');
    expect(button.at(0).text()).toEqual('Previous');
  });

  it('Properly hides the `Previous` button', () => {
    const wrapper = shallow(<CaseInformation goto={() => {}} next={() => {}} previous={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} patient={blankMockPatient} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} hidePreviousButton={true} assigned_users={[]} selected_jurisdiction={mockJurisdiction1} first_positive_lab={mockLaboratory1} edit_mode={false} authenticity_token={'123'} />);
    const button = wrapper.find('.btn-square');
    expect(button.at(0).text()).toEqual('Next');
  });

  it('Properly allows setting of Case Status', () => {
    const wrapper = mount(<CaseInformation goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} patient={blankMockPatient} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} selected_jurisdiction={mockJurisdiction1} first_positive_lab={mockLaboratory1} edit_mode={false} authenticity_token={'123'} />);
    expect(wrapper.find('#case_status').instance().value).toEqual('');
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient4 } }, () => {
      expect(wrapper.find('#case_status').instance().value).toEqual(mockPatient4.case_status);
    });
  });
});
