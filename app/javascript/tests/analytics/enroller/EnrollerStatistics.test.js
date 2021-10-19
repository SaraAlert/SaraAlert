import React from 'react';
import { shallow } from 'enzyme';
import { Card } from 'react-bootstrap';
import EnrollerStatistics from '../../../components/analytics/enroller/EnrollerStatistics';
import { mockEnrollerStatistics1 } from '../../mocks/mockEnrollerStatistics';

const componentProps = {
  title: 'System Statistics',
  total_monitorees: mockEnrollerStatistics1.system_subjects,
  new_monitorees: mockEnrollerStatistics1.system_subjects_last_24,
  total_reports: mockEnrollerStatistics1.system_assessments,
  new_reports: mockEnrollerStatistics1.system_assessments_last_24,
};

describe('EnrollerStatistics', () => {
  it('Properly Renders All Values and Headers correctly', () => {
    const wrapper = shallow(<EnrollerStatistics title={componentProps.title} total_monitorees={componentProps.total_monitorees} new_monitorees={componentProps.new_monitorees} total_reports={componentProps.total_reports} new_reports={componentProps.new_reports} />);
    expect(wrapper.find(Card).exists());
    expect(wrapper.find(Card.Header).text()).toEqual(componentProps.title);
    expect(wrapper.find(Card.Body).find('#monitoree-analytics').find('h4').at(0).text()).toEqual('TOTAL MONITOREES');
    expect(wrapper.find(Card.Body).find('#monitoree-analytics').find('h3').at(0).text()).toEqual(String(componentProps.total_monitorees));
    expect(wrapper.find(Card.Body).find('#monitoree-analytics').find('h4').at(1).text()).toEqual('NEW LAST 24 HOURS');
    expect(wrapper.find(Card.Body).find('#monitoree-analytics').find('h3').at(1).text()).toEqual(String(componentProps.new_monitorees));
    expect(wrapper.find(Card.Body).find('#report-analytics').find('h4').at(0).text()).toEqual('TOTAL REPORTS');
    expect(wrapper.find(Card.Body).find('#report-analytics').find('h3').at(0).text()).toEqual(String(componentProps.total_reports));
    expect(wrapper.find(Card.Body).find('#report-analytics').find('h4').at(1).text()).toEqual('NEW LAST 24 HOURS');
    expect(wrapper.find(Card.Body).find('#report-analytics').find('h3').at(1).text()).toEqual(String(componentProps.new_reports));
  });
});
