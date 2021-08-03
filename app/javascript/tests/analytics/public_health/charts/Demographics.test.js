import React from 'react';
import { shallow } from 'enzyme';
import { Card } from 'react-bootstrap';
import _ from 'lodash';
import Demographics from '../../../../components/analytics/public_health/charts/Demographics';
import WorkflowChart from '../../../../components/analytics/display/WorkflowChart';
import WorkflowTable from '../../../../components/analytics/display/WorkflowTable';
import mockAnalyticsData from '../../../mocks/mockAnalytics';

const available_workflows = [
  { name: 'exposure', label: 'Exposure' },
  { name: 'isolation', label: 'Isolation' },
];

describe('Demographics', () => {
  it('Properly renders all main components when props.showGraphs is false', () => {
    const wrapper = shallow(<Demographics stats={mockAnalyticsData} available_workflows={available_workflows} />);
    expect(wrapper.find(Card).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).text()).toEqual('Demographics (Active Records Only)');
    expect(wrapper.find(Card.Body).exists()).toBeTruthy();
    expect(
      wrapper
        .find(Card.Body)
        .find(WorkflowTable)
        .exists()
    ).toBeTruthy();
    expect(wrapper.find(Card.Body).find(WorkflowTable).length).toEqual(5);
    expect(
      wrapper
        .find(Card.Body)
        .find(WorkflowChart)
        .exists()
    ).toBeFalsy();
  });

  it('Properly renders all main components when props.showGraphs is true', () => {
    const wrapper = shallow(<Demographics stats={mockAnalyticsData} showGraphs={true} available_workflows={available_workflows} />);
    expect(wrapper.find(Card).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).text()).toEqual('Demographics (Active Records Only)');
    expect(wrapper.find(Card.Body).exists()).toBeTruthy();
    expect(
      wrapper
        .find(Card.Body)
        .find(WorkflowTable)
        .exists()
    ).toBeFalsy();
    expect(
      wrapper
        .find(Card.Body)
        .find(WorkflowChart)
        .exists()
    ).toBeTruthy();
    expect(wrapper.find(Card.Body).find(WorkflowChart).length).toEqual(5);
  });

  it('Hides Sexual Orientation table/chart if jurisdiction does not support it', () => {
    let updatedMockAnalyticsData = _.cloneDeep(mockAnalyticsData);
    let updatedMonitoreeCounts = updatedMockAnalyticsData.monitoree_counts.filter(data => data.category_type != 'Sexual Orientation');
    updatedMockAnalyticsData.monitoree_counts = updatedMonitoreeCounts;
    const wrapper = shallow(<Demographics stats={updatedMockAnalyticsData} available_workflows={available_workflows} />);
    expect(wrapper.find(Card.Body).find(WorkflowTable).length).toEqual(4);
  });
});
