import React from 'react'
import { shallow } from 'enzyme';
import { Button } from 'react-bootstrap';
import EnrollHouseholdMember from '../../../components/subject/household_actions/EnrollHouseholdMember.js'

describe('EnrollHouseholdMember', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<EnrollHouseholdMember responderId={123} />);
    expect(wrapper.find(Button).exists).toBeTruthy();
    expect(wrapper.find(Button).text().includes('Enroll Household Member')).toBeTruthy();
    expect(wrapper.find(Button).prop('href').includes('/patients/123/group')).toBeTruthy();
    expect(wrapper.find('i').hasClass('fa-user-plus')).toBeTruthy();
  });
});
