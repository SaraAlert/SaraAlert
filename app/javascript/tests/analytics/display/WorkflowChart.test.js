import React from 'react';
import { shallow } from 'enzyme';
import { Bar, BarChart, CartesianGrid, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import WorkflowChart from '../../../components/analytics/display/WorkflowChart';
import InfoTooltip from '../../../components/util/InfoTooltip';

const chartTitle = 'some chart title';
const chartData = [
  { name: 'row1', Exposure: 11, Isolation: 12 },
  { name: 'row2', Exposure: 3, Isolation: 17 },
  { name: 'row3', Exposure: 9, Isolation: 2 },
  { name: 'row4', Exposure: 8, Isolation: 5 },
  { name: 'row5', Exposure: 15, Isolation: 7 },
];

describe('WorkflowChart', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<WorkflowChart title={chartTitle} data={chartData} />);
    expect(wrapper.find('.analytics-chart-borders').exists()).toBeTruthy();
    expect(wrapper.find('h5').exists()).toBeTruthy();
    expect(wrapper.find('h5').text()).toEqual(chartTitle);
    expect(wrapper.find(InfoTooltip).exists()).toBeFalsy();
    expect(wrapper.find(ResponsiveContainer).exists()).toBeTruthy();
    expect(wrapper.find(BarChart).exists()).toBeTruthy();
    expect(wrapper.find(CartesianGrid).exists()).toBeTruthy();
    expect(wrapper.find(XAxis).exists()).toBeTruthy();
    expect(wrapper.find(YAxis).exists()).toBeTruthy();
    expect(wrapper.find(Tooltip).exists()).toBeTruthy();
    expect(wrapper.find(Legend).exists()).toBeTruthy();
    expect(wrapper.find(Bar).exists()).toBeTruthy();
    expect(wrapper.find(Bar).length).toEqual(2);
  });

  it('Renders info tooltip in header if props.tooltipKey is defined', () => {
    const wrapper = shallow(<WorkflowChart title={chartTitle} tooltipKey={'analyticsAgeTip'} data={chartData} />);
    expect(wrapper.find('h5').find(InfoTooltip).exists()).toBeTruthy();
    expect(wrapper.find('h5').find(InfoTooltip).prop('tooltipTextKey')).toEqual('analyticsAgeTip');
  });
});
