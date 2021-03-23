import React from 'react'
import { shallow } from 'enzyme';
import InfoTooltip from '../../components/util/InfoTooltip';
import CloseContactTable from '../../components/patient/close_contacts/CloseContactTable'
import { mockPatient1 } from '../mocks/mockPatients'

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const ASSIGNED_USERS = [ 123234, 512678, 910132 ]

function getShallowWrapper(mockPatient, canEnroll, assigned_users) {
  return shallow(<CloseContactTable
    patient={mockPatient}
    authenticity_token={authyToken}
    can_enroll_close_contacts={canEnroll}
    assigned_users={assigned_users}/>);
}

describe('CloseContactTable', () => {
  it('Properly renders all main components for empty close contact', () => {
    const wrapper = getShallowWrapper(mockPatient1, true, ASSIGNED_USERS);
    expect(wrapper.find('CardHeader').text()).toContain("Close Contacts")
    expect(wrapper.find('CardHeader').containsMatchingElement(<InfoTooltip />)).toBeTruthy();
    expect(wrapper.find('Button').at(0).text()).toContain('Add New Close Contact');
  });

});
