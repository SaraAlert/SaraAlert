import React from 'react';
import { shallow } from 'enzyme';
import PatientPage from '../../components/patient/PatientPage';
import Patient from '../../components/patient/Patient';
import Dependent from '../../components/patient/household/Dependent';
import HeadOfHousehold from '../../components/patient/household/HeadOfHousehold';
import Individual from '../../components/patient/household/Individual';
import { mockUser1 } from '../mocks/mockUsers';
import { mockPatient1, mockPatient2, mockPatient3 } from '../mocks/mockPatients';
import { mockJurisdictionPaths } from '../mocks/mockJurisdiction';

const mockToken = 'testMockTokenString12345';

function getWrapper(patient, householdMembers) {
  return shallow(<PatientPage patient={patient} other_household_members={householdMembers} blocked_sms={false} current_user={mockUser1} can_add_group={true} can_modify_subject_status={true} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} workflow={'global'} />);
}

describe('PatientPage', () => {
  const wrapper = getWrapper(mockPatient1, [mockPatient2]); // uses mockPatient1 as patient
  const wrapper2 = getWrapper(mockPatient2, [mockPatient1]); // uses mockPatient2 as patient
  const wrapper3 = getWrapper(mockPatient3, []); // uses mockPatient3 as patient

  it('Properly renders all main components', () => {
    expect(wrapper.find('#patient-info-header').exists()).toBe(true);
    expect(wrapper.find('#patient-info-header').text()).toContain('Monitoree Details');
    expect(wrapper.find('#patient-info-header').text()).not.toContain(`(ID: ${mockPatient1.user_defined_id})`);
    expect(wrapper2.find('#patient-info-header').text()).toContain(`Monitoree Details (ID: ${mockPatient2.user_defined_id})`);
    expect(wrapper.find(Patient).exists()).toBe(true);
    expect(wrapper.find('.household-info').exists()).toBe(true);
  });

  it('Properly renders household section for a HoH', () => {
    expect(wrapper.find('.household-info').exists()).toBe(true);
    expect(wrapper.find(HeadOfHousehold).exists()).toBe(true);
    expect(wrapper.find(Dependent).exists()).toBe(false);
    expect(wrapper.find(Individual).exists()).toBe(false);
  });

  it('Properly renders all main components for a dependent', () => {
    expect(wrapper2.find('.household-info').exists()).toBe(true);
    expect(wrapper2.find(Dependent).exists()).toBe(true);
    expect(wrapper2.find(HeadOfHousehold).exists()).toBe(false);
    expect(wrapper2.find(Individual).exists()).toBe(false);
  });

  it('Properly renders all main components for an individual monitoree (not in a household)', () => {
    expect(wrapper3.find('.household-info').exists()).toBe(true);
    expect(wrapper3.find(Individual).exists()).toBe(true);
    expect(wrapper3.find(Dependent).exists()).toBe(false);
    expect(wrapper3.find(HeadOfHousehold).exists()).toBe(false);
  });
});
