import React from 'react'
import { shallow } from 'enzyme';
import { Form } from 'react-bootstrap';
import MonitoringActions from '../../components/subject/MonitoringActions';
import AssignedUser from '../../components/subject/AssignedUser';
import CaseStatus from '../../components/subject/CaseStatus'
import Jurisdiction from '../../components/subject/Jurisdiction';
import MonitoringStatus from '../../components/subject/MonitoringStatus';
import GenericAction from '../../components/subject/GenericAction';
import { mockPatient1 } from '../mocks/mockPatients'
import { mockUser1 } from '../mocks/mockUsers'

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const assignedUsers = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ];
const jurisdictionPaths = {
  2: 'USA, State 1',
  3: 'USA, State 1, County 1',
  4: 'USA, State 1, County 2',
  5: 'USA, State 2',
  6: 'USA, State 2, County 3',
  7: 'USA, State 2, County 4'
};

describe('MonitoringActions', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<MonitoringActions patient={mockPatient1} has_dependents={false} in_household_with_member_with_ce_in_exposure={false} isolation={false} 
      authenticity_token={authyToken} jurisdictionPaths={jurisdictionPaths} current_user={mockUser1} assignedUsers={assignedUsers} />);

    expect(wrapper.find(Form).exists()).toBeTruthy();
    expect(wrapper.find(Form.Group).length).toEqual(7);
    expect(wrapper.find(AssignedUser).exists()).toBeTruthy();
    expect(wrapper.find(CaseStatus).exists()).toBeTruthy();
    expect(wrapper.find(Jurisdiction).exists()).toBeTruthy();
    expect(wrapper.find(MonitoringStatus).exists()).toBeTruthy();
    expect(wrapper.find(GenericAction).length).toEqual(3);
  });
});