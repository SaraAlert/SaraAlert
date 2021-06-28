import React from 'react';
import { shallow } from 'enzyme';
import EnrollerStatistics from '../../../components/analytics/enroller/EnrollerStatistics';
import EnrollerAnalytics from '../../../components/analytics/enroller/EnrollerAnalytics';
import { mockUser1 } from '../../mocks/mockUsers';
import { mockEnrollerStatistics1 } from '../../mocks/mockEnrollerStatistics';

describe('EnrollerAnalytics', () => {
  it('Properly Renders Both EnrollerStatistics Cards correctly', () => {
    const wrapper = shallow(<EnrollerAnalytics user={mockUser1} stats={mockEnrollerStatistics1} />);
    expect(wrapper.find(EnrollerStatistics).exists()).toBeTruthy();
    expect(wrapper.find(EnrollerStatistics).length).toEqual(2);

    expect(wrapper.find(EnrollerStatistics).at(0).prop('title')).toEqual('System Statistics');
    expect(wrapper.find(EnrollerStatistics).at(0).prop('total_monitorees')).toEqual(mockEnrollerStatistics1.system_subjects);
    expect(wrapper.find(EnrollerStatistics).at(0).prop('new_monitorees')).toEqual(mockEnrollerStatistics1.system_subjects_last_24);
    expect(wrapper.find(EnrollerStatistics).at(0).prop('total_reports')).toEqual(mockEnrollerStatistics1.system_assessments);
    expect(wrapper.find(EnrollerStatistics).at(0).prop('new_reports')).toEqual(mockEnrollerStatistics1.system_assessments_last_24);

    expect(wrapper.find(EnrollerStatistics).at(1).prop('title')).toEqual('Your Statistics');
    expect(wrapper.find(EnrollerStatistics).at(1).prop('total_monitorees')).toEqual(mockEnrollerStatistics1.user_subjects);
    expect(wrapper.find(EnrollerStatistics).at(1).prop('new_monitorees')).toEqual(mockEnrollerStatistics1.user_subjects_last_24);
    expect(wrapper.find(EnrollerStatistics).at(1).prop('total_reports')).toEqual(mockEnrollerStatistics1.user_assessments);
    expect(wrapper.find(EnrollerStatistics).at(1).prop('new_reports')).toEqual(mockEnrollerStatistics1.user_assessments_last_24);
  });
});
