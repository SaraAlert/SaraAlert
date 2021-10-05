import React from 'react';
import { shallow } from 'enzyme';
import { Form } from 'react-bootstrap';
import MonitoringActions from '../../../components/patient/monitoring_actions/MonitoringActions';
import AssignedUser from '../../../components/patient/monitoring_actions/AssignedUser';
import CaseStatus from '../../../components/patient/monitoring_actions/CaseStatus';
import ExposureRiskAssessment from '../../../components/patient/monitoring_actions/ExposureRiskAssessment';
import Jurisdiction from '../../../components/patient/monitoring_actions/Jurisdiction';
import MonitoringPlan from '../../../components/patient/monitoring_actions/MonitoringPlan';
import MonitoringStatus from '../../../components/patient/monitoring_actions/MonitoringStatus';
import PublicHealthAction from '../../../components/patient/monitoring_actions/PublicHealthAction';
import { mockPatient1 } from '../../mocks/mockPatients';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockMonitoringReasons } from '../../mocks/mockMonitoringReasons';

const mockToken = 'testMockTokenString12345';
const assigned_users = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

describe('MonitoringActions', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<MonitoringActions patient={mockPatient1} household_members={[]} isolation={false} authenticity_token={mockToken} jurisdiction_paths={mockJurisdictionPaths} current_user={mockUser1} assigned_users={assigned_users} user_can_transfer={false} monitoring_reasons={mockMonitoringReasons} workflow={'global'} />);

    expect(wrapper.find(Form).exists()).toBe(true);
    expect(wrapper.find(Form.Group).length).toEqual(7);
    expect(wrapper.find(AssignedUser).exists()).toBe(true);
    expect(wrapper.find(CaseStatus).exists()).toBe(true);
    expect(wrapper.find(ExposureRiskAssessment).exists()).toBe(true);
    expect(wrapper.find(Jurisdiction).exists()).toBe(true);
    expect(wrapper.find(MonitoringPlan).exists()).toBe(true);
    expect(wrapper.find(MonitoringStatus).exists()).toBe(true);
    expect(wrapper.find(PublicHealthAction).exists()).toBe(true);
  });
});
