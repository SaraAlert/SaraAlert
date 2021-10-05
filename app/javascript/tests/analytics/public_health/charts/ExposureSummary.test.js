import React from 'react';
import { shallow } from 'enzyme';
import { Button, Card } from 'react-bootstrap';
import ExposureSummary from '../../../../components/analytics/public_health/charts/ExposureSummary';
import WorkflowChart from '../../../../components/analytics/display/WorkflowChart';
import WorkflowTable from '../../../../components/analytics/display/WorkflowTable';
import mockAnalyticsData from '../../../mocks/mockAnalytics';

describe('ExposureSummary', () => {
  it('Properly renders all main components when props.showGraphs is false', () => {
    const wrapper = shallow(<ExposureSummary stats={mockAnalyticsData} />);
    expect(wrapper.find(Card).exists()).toBe(true);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual('Exposure Summary (Active Records Only)');
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(WorkflowTable).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(WorkflowTable).length).toEqual(2);
    expect(wrapper.find(Card.Body).find(WorkflowChart).exists()).toBe(false);
    expect(wrapper.find(Card.Body).find(Button).exists()).toBe(true);
  });

  it('Properly renders all main components when props.showGraphs is true', () => {
    const wrapper = shallow(<ExposureSummary stats={mockAnalyticsData} showGraphs={true} />);
    expect(wrapper.find(Card).exists()).toBe(true);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual('Exposure Summary (Active Records Only)');
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(WorkflowTable).exists()).toBe(false);
    expect(wrapper.find(Card.Body).find(WorkflowChart).exists()).toBe(true);
    expect(wrapper.find(Card.Body).find(WorkflowChart).length).toEqual(2);
    expect(wrapper.find(Card.Body).find(Button).exists()).toBe(false);
  });

  it('Clicking the Export Complete Country Data button calls exportFullCountryData method', () => {
    window.URL.createObjectURL = jest.fn();
    const wrapper = shallow(<ExposureSummary stats={mockAnalyticsData} />);
    const exportFullCountryDataSpy = jest.spyOn(wrapper.instance(), 'exportFullCountryData');
    wrapper.instance().forceUpdate();
    expect(exportFullCountryDataSpy).not.toHaveBeenCalled();
    wrapper.find(Button).simulate('click');
    expect(exportFullCountryDataSpy).toHaveBeenCalled();
  });
});
