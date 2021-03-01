import React from 'react'
import { shallow } from 'enzyme';
import EnrollerStatistics from '../../components/analytics/widgets/EnrollerStatistics';

import EnrollerAnalytics from '../../components/analytics/EnrollerAnalytics.js'
import { mockUser1 } from '../mocks/mockUsers'
import { mockEnrollerStatistics1 } from '../mocks/mockEnrollerStatistics'

describe('EnrollerAnalytics', () => {
  it('Properly Renders Both EnrollerStatistics Cards correctly', () => {
    const eaWrapper = shallow(<EnrollerAnalytics user={mockUser1} stats={mockEnrollerStatistics1}/>);
    expect(eaWrapper.find('Fragment').find('Row').find('Col').at(0).containsMatchingElement(<EnrollerStatistics />)).toBeTruthy();
    expect(eaWrapper.find(EnrollerStatistics).at(0).prop('title')).toEqual('System Statistics');
    expect(eaWrapper.find(EnrollerStatistics).at(0).prop('total_monitorees')).toEqual(mockEnrollerStatistics1.system_subjects);
    expect(eaWrapper.find(EnrollerStatistics).at(0).prop('new_monitorees')).toEqual(mockEnrollerStatistics1.system_subjects_last_24);
    expect(eaWrapper.find(EnrollerStatistics).at(0).prop('total_reports')).toEqual(mockEnrollerStatistics1.system_assessments);
    expect(eaWrapper.find(EnrollerStatistics).at(0).prop('new_reports')).toEqual(mockEnrollerStatistics1.system_assessments_last_24);

    expect(eaWrapper.find('Fragment').find('Row').find('Col').at(1).containsMatchingElement(<EnrollerStatistics />)).toBeTruthy();
    expect(eaWrapper.find(EnrollerStatistics).at(1).prop('title')).toEqual('Your Statistics');
    expect(eaWrapper.find(EnrollerStatistics).at(1).prop('total_monitorees')).toEqual(mockEnrollerStatistics1.user_subjects);
    expect(eaWrapper.find(EnrollerStatistics).at(1).prop('new_monitorees')).toEqual(mockEnrollerStatistics1.user_subjects_last_24);
    expect(eaWrapper.find(EnrollerStatistics).at(1).prop('total_reports')).toEqual(mockEnrollerStatistics1.user_assessments);
    expect(eaWrapper.find(EnrollerStatistics).at(1).prop('new_reports')).toEqual(mockEnrollerStatistics1.user_assessments_last_24);

  });
});
