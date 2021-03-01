import React from 'react'
import { shallow } from 'enzyme';
import EnrollerStatistics from '../../../components/analytics/widgets/EnrollerStatistics';

import { mockEnrollerStatistics1 } from '../../mocks/mockEnrollerStatistics'

// Only need to test System Statistics because the behavior for "Your Statistics" is identical
const componentProps = {
  title: "System Statistics",
  total_monitorees: mockEnrollerStatistics1.system_subjects,
  new_monitorees: mockEnrollerStatistics1.system_subjects_last_24,
  total_reports: mockEnrollerStatistics1.system_assessments,
  new_reports: mockEnrollerStatistics1.system_assessments_last_24,
}

describe('EnrollerStatistics', () => {
  it('Properly Renders All Values and Headers correctly', () => {
    const esWrapper = shallow(<EnrollerStatistics
      title={componentProps.title}
      total_monitorees={componentProps.total_monitorees}
      new_monitorees={componentProps.new_monitorees}
      total_reports={componentProps.total_reports}
      new_reports={componentProps.new_reports}
    />);
    expect(esWrapper.find('Card').find('div').at(0).text()).toContain(componentProps.title);
    expect(esWrapper.find('Card').find('CardBody').find('#monitoreeAnalytics').find('h4').at(0).text()).toContain("TOTAL MONITOREES");
    expect(esWrapper.find('Card').find('CardBody').find('#monitoreeAnalytics').find('h3').at(0).text()).toContain(componentProps.total_monitorees);
    expect(esWrapper.find('Card').find('CardBody').find('#monitoreeAnalytics').find('h4').at(1).text()).toContain("NEW LAST 24 HOURS");
    expect(esWrapper.find('Card').find('CardBody').find('#monitoreeAnalytics').find('h3').at(1).text()).toContain(componentProps.new_monitorees);

    expect(esWrapper.find('Card').find('CardBody').find('#reportAnalytics').find('h4').at(0).text()).toContain("TOTAL REPORTS");
    expect(esWrapper.find('Card').find('CardBody').find('#reportAnalytics').find('h3').at(0).text()).toContain(componentProps.total_reports);
    expect(esWrapper.find('Card').find('CardBody').find('#reportAnalytics').find('h4').at(1).text()).toContain("NEW LAST 24 HOURS");
    expect(esWrapper.find('Card').find('CardBody').find('#reportAnalytics').find('h3').at(1).text()).toContain(componentProps.new_reports);
  });
});
