import React from 'react'
import { shallow } from 'enzyme';
import { Button } from 'react-bootstrap';
import AddHouseholdMember from '../../../components/subject/household_actions/AddHouseholdMember.js'

describe('AddHouseholdMember', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<AddHouseholdMember responderId={123} />);
    expect(wrapper.find(Button).exists).toBeTruthy();
    expect(wrapper.find(Button).text().includes('Enroll Household Member')).toBeTruthy();
    expect(wrapper.find(Button).prop('href').includes('/patients/123/group')).toBeTruthy();
    expect(wrapper.find('i').hasClass('fa-user-plus')).toBeTruthy();
  });
});
