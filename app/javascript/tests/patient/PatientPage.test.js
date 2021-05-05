import React from 'react';
import { shallow } from 'enzyme';
import PatientPage from '../../components/patient/PatientPage';
import Patient from '../../components/patient/Patient';
import Dependent from '../../components/patient/household/Dependent';
import HeadOfHousehold from '../../components/patient/household/HeadOfHousehold';
import Individual from '../../components/patient/household/Individual';
import { mockPatient1, mockPatient2, mockPatient3 } from '../mocks/mockPatients';

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

function getWrapper(patient, householdMembers) {
  return shallow(<PatientPage patient={patient} other_household_members={householdMembers} blocked_sms={false} can_add_group={true}
    can_modify_subject_status={true} jurisdiction_path="USA, State 1, County 2" authenticity_token={authyToken} />);
}

describe('PatientPage', () => {
  const wrapper = getWrapper(mockPatient1, [ mockPatient2 ]); // uses mockPatient1 as patient
  const wrapper2 = getWrapper(mockPatient2, [ mockPatient1 ]); // uses mockPatient2 as patient
  const wrapper3 = getWrapper(mockPatient3, [ ]); // uses mockPatient3 as patient

  it('Properly renders all main components', () => {
    expect(wrapper.find('#patient-info-header').exists()).toBeTruthy();
    expect(wrapper.find('#patient-info-header').text().includes('Monitoree Details')).toBeTruthy();
    expect(wrapper.find('#patient-info-header').text().includes(`(ID: ${mockPatient1.user_defined_id})`)).toBeFalsy();
    expect(wrapper2.find('#patient-info-header').text().includes(`Monitoree Details (ID: ${mockPatient2.user_defined_id})`)).toBeTruthy();
    expect(wrapper.find(Patient).exists()).toBeTruthy();
    expect(wrapper.find('.household-info').exists()).toBeTruthy();
  });

  it('Properly renders household section for a HoH', () => {
    expect(wrapper.find('.household-info').exists()).toBeTruthy();
    expect(wrapper.find(HeadOfHousehold).exists()).toBeTruthy();
    expect(wrapper.find(Dependent).exists()).toBeFalsy();
    expect(wrapper.find(Individual).exists()).toBeFalsy();
  });

  it('Properly renders all main components for a dependent', () => {
    expect(wrapper2.find('.household-info').exists()).toBeTruthy();
    expect(wrapper2.find(Dependent).exists()).toBeTruthy();
    expect(wrapper2.find(HeadOfHousehold).exists()).toBeFalsy();
    expect(wrapper2.find(Individual).exists()).toBeFalsy();
  });

  it('Properly renders all main components for an individual monitoree (not in a household)', () => {
    expect(wrapper3.find('.household-info').exists()).toBeTruthy();
    expect(wrapper3.find(Individual).exists()).toBeTruthy();
    expect(wrapper3.find(Dependent).exists()).toBeFalsy();
    expect(wrapper3.find(HeadOfHousehold).exists()).toBeFalsy();
  });
});
