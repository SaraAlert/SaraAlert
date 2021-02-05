import React from 'react'
import { shallow } from 'enzyme';
import VaccineModal from '../../../components/patient/vaccines/VaccineModal';

function getShallowWrapper() {
  return shallow(
    // TODO
    <VaccineModal 
    />
  );
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('VaccineModal', () => {
  it('TODO', () => {
    const wrapper = getShallowWrapper()
    expect(wrapper);
  });
});
