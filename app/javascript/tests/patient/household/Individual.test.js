import React from 'react';
import { shallow } from 'enzyme';
import { Row } from 'react-bootstrap';
import Individual from '../../../components/patient/household/Individual';
import MoveToHousehold from '../../../components/patient/household/actions/MoveToHousehold';
import EnrollHouseholdMember from '../../../components/patient/household/actions/EnrollHouseholdMember';
import { mockPatient3 } from '../../mocks/mockPatients';

const mockToken = 'testMockTokenString12345';

describe('Individual', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<Individual patient={mockPatient3} can_add_group={true} authenticity_token={mockToken} />);
    const wrapper2 = shallow(<Individual patient={mockPatient3} can_add_group={false} authenticity_token={mockToken} />);

    // if user can add group
    expect(wrapper.find(Row).length).toEqual(2);
    expect(wrapper.find(Row).at(0).text()).toEqual('This monitoree is not a member of a household.');
    expect(wrapper.find(MoveToHousehold).exists()).toBeTruthy();
    expect(wrapper.find(EnrollHouseholdMember).exists()).toBeTruthy();
    expect(wrapper.find(EnrollHouseholdMember).prop('isHoh')).toBeFalsy();

    // if user can't add group
    expect(wrapper2.find(Row).length).toEqual(2);
    expect(wrapper2.find(Row).at(0).text()).toEqual('This monitoree is not a member of a household.');
    expect(wrapper2.find(MoveToHousehold).exists()).toBeTruthy();
    expect(wrapper2.find(EnrollHouseholdMember).exists()).toBeFalsy();
  });
});
