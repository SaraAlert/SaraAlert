import React from 'react';
import { mount } from 'enzyme';
import PublicHealthManagement from '../../../components/enrollment/steps/PublicHealthManagement';
import { blankMockPatient, mockPatient1 } from '../../mocks/mockPatients';
import { mockJurisdiction1, mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockLaboratory1 } from '../../mocks/mockLaboratories';

const newEnrollmentState = {
  isolation: false,
  patient: blankMockPatient,
  propagatedFields: {},
};

const requiredStrings = ['ASSIGNED JURISDICTION', 'ASSIGNED USER', 'RISK ASSESSMENT', 'MONITORING PLAN'];

describe('PublicHealthManagement', () => {
  it('Properly renders all main components', () => {
    const wrapper = mount(<PublicHealthManagement goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} patient={blankMockPatient} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} selected_jurisdiction={mockJurisdiction1} first_positive_lab={mockLaboratory1} edit_mode={false} authenticity_token={'123'} />);
    requiredStrings.forEach(requiredString => {
      expect(wrapper.text().includes(requiredString)).toBe(true);
    });
  });

  it('Properly allows setting of Assigned User', () => {
    const wrapper = mount(<PublicHealthManagement goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} patient={blankMockPatient} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} selected_jurisdiction={mockJurisdiction1} first_positive_lab={mockLaboratory1} edit_mode={false} authenticity_token={'123'} />);
    expect(wrapper.find('#assigned_user').instance().value).toEqual('');
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1 } }, () => {
      expect(Number(wrapper.find('#assigned_user').instance().value)).toEqual(mockPatient1.assigned_user);
    });
  });

  it('Properly allows setting of Risk Assessment', () => {
    const wrapper = mount(<PublicHealthManagement goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} patient={blankMockPatient} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} selected_jurisdiction={mockJurisdiction1} first_positive_lab={mockLaboratory1} edit_mode={false} authenticity_token={'123'} />);
    expect(wrapper.find('#exposure_risk_assessment').instance().value).toEqual('');
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1 } }, () => {
      expect(wrapper.find('#exposure_risk_assessment').instance().value).toEqual(mockPatient1.exposure_risk_assessment);
    });
  });

  //   it('Properly allows setting of Monitoring Plan', () => {
  //       // console.log(mockPatient1.monitoring_plan) // = 'Daily active monitoring'
  //     const wrapper = mount(<PublicHealthManagement goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState}
  //     patient={blankMockPatient}  has_dependents={false} jurisdiction_paths={mockJurisdictionPaths}
  //     assigned_users={[]} selected_jurisdiction ={mockJurisdiction1} first_positive_lab = {mockLaboratory1} edit_mode={false} authenticity_token = {'123'} /> );
  //     expect(wrapper.find('#monitoring_plan').instance().value).toEqual("");
  //       wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1 } }, () => {
  //       expect(wrapper.find('#monitoring_plan').instance().value).toEqual(mockPatient1.monitoring_plan); // Expected: "" Recieved: "None"
  //     });
  //   });
});
