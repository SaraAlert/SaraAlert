import React from 'react'
import { shallow } from 'enzyme';
import VaccineTable from '../../../components/patient/vaccines/VaccineTable';
import { mockPatient1 } from '../../mocks/mockPatients';

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';

function getShallowWrapper() {
  return shallow(
    // TODO
    <VaccineTable 
      authenticity_token={authyToken} 
      patient={mockPatient1} 
    />
  );
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('VaccineTable', () => {
  it('TODO', () => {
    const wrapper = getShallowWrapper()
    expect(wrapper);
  });
});
