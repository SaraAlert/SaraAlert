import React from 'react';
import { shallow } from 'enzyme';
import { Row } from 'react-bootstrap';
import Dependent from '../../../components/patient/household/Dependent';
import HouseholdMemberTable from '../../../components/patient/household/utils/HouseholdMemberTable';
import RemoveFromHousehold from '../../../components/patient/household/actions/RemoveFromHousehold';
import { mockPatient1, mockPatient2 } from '../../mocks/mockPatients';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';

const mockToken = 'testMockTokenString12345';

describe('Dependent', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<Dependent patient={mockPatient2} other_household_members={[mockPatient1]} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} />);
    expect(wrapper.find(Row).length).toEqual(3);
    expect(wrapper.find(Row).at(0).text()).toEqual('This monitoree is a member of the following household:');
    expect(wrapper.find(HouseholdMemberTable).exists()).toBeTruthy();
    expect(wrapper.find(RemoveFromHousehold).exists()).toBeTruthy();
  });
});
