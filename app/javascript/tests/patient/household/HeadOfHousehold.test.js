import React from 'react';
import { shallow } from 'enzyme';
import { Row } from 'react-bootstrap';
import HeadOfHousehold from '../../../components/patient/household/HeadOfHousehold';
import ChangeHoH from '../../../components/patient/household/actions/ChangeHoH';
import EnrollHouseholdMember from '../../../components/patient/household/actions/EnrollHouseholdMember';
import HouseholdMemberTable from '../../../components/patient/household/HouseholdMemberTable';
import { mockPatient1, mockPatient2 } from '../../mocks/mockPatients';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';

const mockToken = 'testMockTokenString12345';

describe('HeadOfHousehold', () => {
  it('Properly renders all main components', () => {
    const wrapper1 = shallow(<HeadOfHousehold patient={mockPatient1} other_household_members={[mockPatient2]} can_add_group={true} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} workflow={'global'} />);
    const wrapper2 = shallow(<HeadOfHousehold patient={mockPatient1} other_household_members={[mockPatient2]} can_add_group={false} current_user={mockUser1} jurisdiction_paths={mockJurisdictionPaths} authenticity_token={mockToken} workflow={'global'} />);

    // if user can add group
    expect(wrapper1.find(Row).length).toEqual(2);
    expect(wrapper1.find(Row).at(0).find('div').text()).toEqual('This monitoree is responsible for handling the reporting of the following other monitorees:');
    expect(wrapper1.find(HouseholdMemberTable).exists()).toBe(true);
    expect(wrapper1.find(ChangeHoH).exists()).toBe(true);
    expect(wrapper1.find(EnrollHouseholdMember).exists()).toBe(true);
    expect(wrapper1.find(EnrollHouseholdMember).prop('isHoh')).toBe(true);

    // if user can't add group
    expect(wrapper2.find(Row).length).toEqual(2);
    expect(wrapper2.find(Row).at(0).find('div').text()).toEqual('This monitoree is responsible for handling the reporting of the following other monitorees:');
    expect(wrapper2.find(HouseholdMemberTable).exists()).toBe(true);
    expect(wrapper2.find(ChangeHoH).exists()).toBe(true);
    expect(wrapper2.find(EnrollHouseholdMember).exists()).toBe(false);
  });
});
