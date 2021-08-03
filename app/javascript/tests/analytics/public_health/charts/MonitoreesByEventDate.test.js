import React from 'react';
import { shallow } from 'enzyme';
import { Card, Col, Form } from 'react-bootstrap';
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import MonitoreesByEventDate from '../../../../components/analytics/public_health/charts/MonitoreesByEventDate';
import mockAnalyticsData from '../../../mocks/mockAnalytics';

const timeResolutionOptions = ['Day', 'Week', 'Month'];
const graphInfo = [
  { title: 'Exposure Workflow', axisLabel: 'Last Date of Exposure' },
  { title: 'Isolation Workflow', axisLabel: 'Symptom Onset Date' },
];

const available_workflows = [
  { name: 'exposure', label: 'Exposure' },
  { name: 'isolation', label: 'Isolation' },
];

function getWrapper() {
  return shallow(<MonitoreesByEventDate stats={mockAnalyticsData} available_workflows={available_workflows} />);
}

describe('MonitoreesByEventDate', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Card).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).exists()).toBeTruthy();
    expect(wrapper.find(Card.Header).text()).toEqual('Monitorees by Event Date (Active Records Only)');
    expect(wrapper.find(Card.Body).exists()).toBeTruthy();
    expect(
      wrapper
        .find(Card.Body)
        .find(Form.Group)
        .exists()
    ).toBeTruthy();
    expect(
      wrapper
        .find(Card.Body)
        .find(Form.Label)
        .exists()
    ).toBeTruthy();
    expect(
      wrapper
        .find(Card.Body)
        .find(Form.Label)
        .text()
    ).toEqual('Time Resolution');
    expect(
      wrapper
        .find(Card.Body)
        .find(Form.Control)
        .exists()
    ).toBeTruthy();
    expect(
      wrapper
        .find(Card.Body)
        .find(Form.Control)
        .find('option').length
    ).toEqual(timeResolutionOptions.length);
    timeResolutionOptions.forEach((option, index) => {
      expect(
        wrapper
          .find(Card.Body)
          .find(Form.Control)
          .find('option')
          .at(index)
          .text()
      ).toEqual(option);
    });
  });

  it('Properly renders bar charts', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Card.Body).find(ResponsiveContainer).length).toEqual(2);
    expect(wrapper.find(Card.Body).find(BarChart).length).toEqual(2);

    graphInfo.forEach((graph, index) => {
      expect(
        wrapper
          .find(Col)
          .at(index)
          .find('.h5')
          .text()
      ).toEqual(graph.title);
      expect(
        wrapper
          .find(Col)
          .at(index)
          .find(ResponsiveContainer)
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find(Col)
          .at(index)
          .find(BarChart)
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find(Col)
          .at(index)
          .find(BarChart)
          .find(CartesianGrid)
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find(Col)
          .at(index)
          .find(BarChart)
          .find(XAxis)
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find(Col)
          .at(index)
          .find(BarChart)
          .find(YAxis)
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find(Col)
          .at(index)
          .find(BarChart)
          .find(Tooltip)
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find(Col)
          .at(index)
          .find(BarChart)
          .find(Bar)
          .exists()
      ).toBeTruthy();
      expect(
        wrapper
          .find(Col)
          .at(index)
          .find('.h6')
          .text()
      ).toEqual(graph.axisLabel);
    });
  });

  it('Properly filters analytics data by selected time resolution', () => {
    const wrapper = getWrapper();
    expect(wrapper.state().graphData[0].length).toEqual(15); // exposure day entries
    expect(wrapper.state().graphData[1].length).toEqual(15); // isolation day entries

    wrapper.find(Form.Control).simulate('change', { target: { value: 'Week' } });
    expect(wrapper.state().graphData[0].length).toEqual(5); // exposure week entries
    expect(wrapper.state().graphData[1].length).toEqual(5); // isolation week entries

    wrapper.find(Form.Control).simulate('change', { target: { value: 'Month' } });
    expect(wrapper.state().graphData[0].length).toEqual(2); // exposure month entries
    expect(wrapper.state().graphData[1].length).toEqual(2); // isolation month entries

    wrapper.find(Form.Control).simulate('change', { target: { value: 'Day' } });
    expect(wrapper.state().graphData[0].length).toEqual(15); // exposure day entries
    expect(wrapper.state().graphData[1].length).toEqual(15); // isolation day entries
  });
});
