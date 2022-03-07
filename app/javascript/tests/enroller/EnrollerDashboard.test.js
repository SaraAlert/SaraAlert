import React from 'react';
import { shallow } from 'enzyme';
import { Button } from 'react-bootstrap';
import EnrollerDashboard from '../../components/enroller/EnrollerDashboard';
import PatientsTable from '../../components/patient/PatientsTable';
import { mockJurisdiction1, mockJurisdictionPaths } from '../mocks/mockJurisdiction';

const MOCK_TOKEN = 'testMockTokenString12345';
const ASSIGNED_USERS = [123234, 512678, 910132];

describe('EnrollerDashboard', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<EnrollerDashboard all_assigned_users={ASSIGNED_USERS} jurisdiction={mockJurisdiction1} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={MOCK_TOKEN} />);
    expect(wrapper.find(Button).exists()).toBe(true);
    expect(wrapper.find(Button).find('i').hasClass('fa-user-plus')).toBe(true);
    expect(wrapper.find(Button).find('span').text()).toContain('Enroll New Monitoree');
    expect(wrapper.find(PatientsTable).exists()).toBe(true);
  });
});
