import React from 'react';
import { shallow } from 'enzyme';
import { Card } from 'react-bootstrap';
import _ from 'lodash';
import Demographics from '../../../../components/analytics/public_health/charts/Demographics';
import WorkflowChart from '../../../../components/analytics/display/WorkflowChart';
import WorkflowTable from '../../../../components/analytics/display/WorkflowTable';
import mockAnalyticsData from '../../../mocks/mockAnalytics';

describe('Demographics', () => {
  it('Properly renders all main components when props.showGraphs is false', () => {
    const wrapper = shallow(<Demographics stats={mockAnalyticsData} />);
    expect(wrapper.find(Card).exists()).toBe(true);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual('Demographics (Active Records Only)');
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(WorkflowTable).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(WorkflowTable).length).toEqual(5);
    expect(wrapper.find(Card.Body).find(WorkflowChart).exists()).toBe(false);
  });

  it('Properly renders all main components when props.showGraphs is true', () => {
    const wrapper = shallow(<Demographics stats={mockAnalyticsData} showGraphs={true} />);
    expect(wrapper.find(Card).exists()).toBe(true);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual('Demographics (Active Records Only)');
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(WorkflowTable).exists()).toBe(false);
    expect(wrapper.find(Card.Body).find(WorkflowChart).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(WorkflowChart).length).toEqual(5);
  });

  it('Hides Sexual Orientation table/chart if jurisdiction does not support it', () => {
    let updatedMockAnalyticsData = _.cloneDeep(mockAnalyticsData);
    let updatedMonitoreeCounts = updatedMockAnalyticsData.monitoree_counts.filter(data => data.category_type != 'Sexual Orientation');
    updatedMockAnalyticsData.monitoree_counts = updatedMonitoreeCounts;
    const wrapper = shallow(<Demographics stats={updatedMockAnalyticsData} />);
    expect(wrapper.find(Card.Body).find(WorkflowTable).length).toEqual(4);
  });
});
