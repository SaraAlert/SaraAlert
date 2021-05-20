import React from 'react';
import { Modal } from 'react-bootstrap';
import { shallow } from 'enzyme';
import FollowUpFlag from '../../../components/patient/follow_up_flag/FollowUpFlag';
import FollowUpFlagModal from '../../../components/patient/follow_up_flag/FollowUpFlagModal';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockPatient1 } from '../../mocks/mockPatients';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

function getWrapper() {
  return shallow(<FollowUpFlagModal show={true} bulk_action={false} current_user={mockUser1} patient={mockPatient1} other_household_members={[]}
    jurisdiction_path="USA, State 1, County 2" jurisdiction_paths={mockJurisdictionPaths} authenticity_token={authyToken} />);
}

describe('FollowUpFlag', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find('#follow-up-flag-modal').exists()).toBeTruthy();
    expect(wrapper.find(Modal).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).exists()).toBeTruthy();
    expect(wrapper.find(Modal.Title).text()).toEqual('Flag for Follow-Up');
    expect(wrapper.find(FollowUpFlag).exists()).toBeTruthy();
  });
});
