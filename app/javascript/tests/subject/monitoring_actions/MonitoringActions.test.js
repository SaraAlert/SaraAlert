import React from 'react'
import { shallow } from 'enzyme';
import { Form } from 'react-bootstrap';
import MonitoringActions from '../../../components/subject/monitoring_actions/MonitoringActions';
import AssignedUser from '../../../components/subject/monitoring_actions/AssignedUser';
import CaseStatus from '../../../components/subject/monitoring_actions/CaseStatus'
import ExposureRiskAssessment from '../../../components/subject/monitoring_actions/ExposureRiskAssessment'
import Jurisdiction from '../../../components/subject/monitoring_actions/Jurisdiction';
import MonitoringPlan from '../../../components/subject/monitoring_actions/MonitoringPlan';
import MonitoringStatus from '../../../components/subject/monitoring_actions/MonitoringStatus';
import PublicHealthAction from '../../../components/subject/monitoring_actions/PublicHealthAction';
import { mockPatient1 } from '../../mocks/mockPatients'
import { mockUser1 } from '../../mocks/mockUsers'
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction'
import { mockMonitoringReasons } from '../../mocks/mockMonitoringReasons'

const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';
const assigned_users = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ];

describe('MonitoringActions', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<MonitoringActions patient={mockPatient1} has_dependents={false} in_household_with_member_with_ce_in_exposure={false} isolation={false}
      authenticity_token={authyToken} jurisdiction_paths={mockJurisdictionPaths} current_user={mockUser1} assigned_users={assigned_users} user_can_transfer={false}
      monitoring_reasons={mockMonitoringReasons}/>);

    expect(wrapper.find(Form).exists()).toBeTruthy();
    expect(wrapper.find(Form.Group).length).toEqual(7);
    expect(wrapper.find(AssignedUser).exists()).toBeTruthy();
    expect(wrapper.find(CaseStatus).exists()).toBeTruthy();
    expect(wrapper.find(ExposureRiskAssessment).exists()).toBeTruthy();
    expect(wrapper.find(Jurisdiction).exists()).toBeTruthy();
    expect(wrapper.find(MonitoringPlan).exists()).toBeTruthy();
    expect(wrapper.find(MonitoringStatus).exists()).toBeTruthy();
    expect(wrapper.find(PublicHealthAction).exists()).toBeTruthy();
  });
});