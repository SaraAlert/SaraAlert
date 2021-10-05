import React from 'react';
import { Modal } from 'react-bootstrap';
import { shallow } from 'enzyme';
import FollowUpFlag from '../../../components/patient/follow_up_flag/FollowUpFlag';
import FollowUpFlagModal from '../../../components/patient/follow_up_flag/FollowUpFlagModal';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockPatient1, mockPatient3 } from '../../mocks/mockPatients';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';

const mockToken = 'testMockTokenString12345';

function getWrapperIndividual(patient, clear_flag) {
  return shallow(<FollowUpFlagModal show={true} current_user={mockUser1} patient={patient} other_household_members={[]} jurisdiction_path="USA, State 1, County 2" jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} clear_flag={clear_flag} />);
}

describe('FollowUpFlagModal', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapperIndividual(mockPatient1, false);
    expect(wrapper.find('#follow-up-flag-modal').exists()).toBe(true);
    expect(wrapper.find(Modal).exists()).toBe(true);
    expect(wrapper.find(Modal.Title).exists()).toBe(true);
    expect(wrapper.find(Modal.Title).text()).toEqual('Flag for Follow-Up');
    expect(wrapper.find(FollowUpFlag).exists()).toBe(true);
  });

  it('Properly sets modal title for a patient with a flag set when clearing the flag', () => {
    const wrapper = getWrapperIndividual(mockPatient3, true);
    expect(wrapper.find(Modal.Title).text()).toEqual('Clear Flag');
  });
});
