import React from 'react';
import { shallow } from 'enzyme';
import { Button, Card } from 'react-bootstrap';
import ExposureSummary from '../../../../components/analytics/public_health/charts/ExposureSummary';
import WorkflowChart from '../../../../components/analytics/display/WorkflowChart';
import WorkflowTable from '../../../../components/analytics/display/WorkflowTable';
import mockAnalyticsData from '../../../mocks/mockAnalytics';

const available_workflows = [
  { name: 'exposure', label: 'Exposure' },
  { name: 'isolation', label: 'Isolation' },
];

describe('ExposureSummary', () => {
  it('Properly renders all main components when props.showGraphs is false', () => {
    const wrapper = shallow(<ExposureSummary stats={mockAnalyticsData} available_workflows={available_workflows} />);
    expect(wrapper.find(Card).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).text()).toEqual('Exposure Summary (Active Records Only)');
    expect(wrapper.find(Card.Body).exists()).toBeTruthy();
    expect(
      wrapper
        .find(Card.Body)
        .find(WorkflowTable)
        .exists()
    ).toBeTruthy();
    expect(wrapper.find(Card.Body).find(WorkflowTable).length).toEqual(2);
    expect(
      wrapper
        .find(Card.Body)
        .find(WorkflowChart)
        .exists()
    ).toBeFalsy();
    expect(
      wrapper
        .find(Card.Body)
        .find(Button)
        .exists()
    ).toBeTruthy();
  });

  it('Properly renders all main components when props.showGraphs is true', () => {
    const wrapper = shallow(<ExposureSummary stats={mockAnalyticsData} showGraphs={true} available_workflows={available_workflows} />);
    expect(wrapper.find(Card).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).text()).toEqual('Exposure Summary (Active Records Only)');
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
    expect(wrapper.find(Card.Body).find(WorkflowChart).length).toEqual(2);
    expect(
      wrapper
        .find(Card.Body)
        .find(Button)
        .exists()
    ).toBeFalsy();
  });

  it('Clicking the Export Complete Country Data button calls exportFullCountryData method', () => {
    window.URL.createObjectURL = jest.fn();
    const wrapper = shallow(<ExposureSummary stats={mockAnalyticsData} available_workflows={available_workflows} />);
    const exportFullCountryDataSpy = jest.spyOn(wrapper.instance(), 'exportFullCountryData');
    wrapper.instance().forceUpdate();
    expect(exportFullCountryDataSpy).toHaveBeenCalledTimes(0);
    wrapper.find(Button).simulate('click');
    expect(exportFullCountryDataSpy).toHaveBeenCalledTimes(1);
  });
});
