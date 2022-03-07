import React from 'react';
import { shallow } from 'enzyme';
import PublicHealthDashboard from '../../components/public_health/PublicHealthDashboard';
import PublicHealthHeader from '../../components/public_health/PublicHealthHeader';
import PatientsTable from '../../components/patient/PatientsTable';
import { mockJurisdiction1, mockJurisdictionPaths } from '../mocks/mockJurisdiction';
import { mockExposureTabs } from '../mocks/mockTabs';

const MOCK_TOKEN = 'testMockTokenString12345';
const ASSIGNED_USERS = [123234, 512678, 910132];

describe('PublicHealthDashboard', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<PublicHealthDashboard workflow="exposure" tabs={mockExposureTabs} default_tab={Object.keys(mockExposureTabs)[0]} all_assigned_users={ASSIGNED_USERS} jurisdiction={mockJurisdiction1} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={MOCK_TOKEN} />);
    expect(wrapper.find(PublicHealthHeader).exists()).toBe(true);
    expect(wrapper.find(PatientsTable).exists()).toBe(true);
  });
});
