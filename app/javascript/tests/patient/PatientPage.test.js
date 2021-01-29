import React from 'react'
import { shallow } from 'enzyme';
import PatientPage from '../../components/patient/PatientPage.js'
import Patient from '../../components/patient/Patient.js'
import { mockUser1 } from '../mocks/mockUsers'
import { mockPatient1, mockPatient2 } from '../mocks/mockPatients'

function getWrapper(mockPatient) {
  const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";
  const dependents = [ mockPatient2 ]
  const wrapper = shallow(<PatientPage patient_id="EX-771721" patient={mockPatient} current_user={mockUser1} dependents={dependents}
    hideBody={true} jurisdiction_path="USA, State 1, County 2" dashboardUrl="/public_health" authenticity_token={authyToken} />);
  return wrapper;
}

describe('PatientPage', () => {
  const wrapper = getWrapper(mockPatient1); // uses mockPatient1 as patient
  const wrapper2 = getWrapper(mockPatient2); // uses mockPatient2 as patient

  it('Properly renders all main components', () => {
    expect(wrapper.find('#patient-info-header').exists()).toBeTruthy();
    expect(wrapper.find('#patient-info-header').text().includes('Monitoree Details  (edit details)')).toBeTruthy();
    expect(wrapper.find('#patient-info-header a').prop('href')).toEqual('undefined/patients/17/edit');
    expect(wrapper.containsMatchingElement(Patient)).toBeTruthy();
    expect(wrapper2.find('#patient-info-header').text().includes('Monitoree Details (ID: 00000-1) (edit details)')).toBeTruthy();
  });
});
