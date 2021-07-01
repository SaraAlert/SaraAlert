import React from 'react';
import { PropTypes } from 'prop-types';
import { Bar, BarChart, CartesianGrid, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import CustomizedAxisTick from '../display/CustomizedAxisTick';
import InfoTooltip from '../../util/InfoTooltip';

class WorkflowChart extends React.Component {
  render() {
    return (
      <div className="analytics-chart-borders">
        <h5 className="text-center">
          {this.props.title}
          {this.props.tooltipKey && (
            <span className="h6 text-left">
              <InfoTooltip tooltipTextKey={this.props.tooltipKey} location="right"></InfoTooltip>
            </span>
          )}
        </h5>
        <ResponsiveContainer width="100%" height={400}>
          <BarChart
            width={500}
            height={300}
            data={this.props.data}
            margin={{
              top: 20,
              right: 30,
              left: 20,
              bottom: 5,
            }}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" interval={0} tick={<CustomizedAxisTick />} height={100} />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="Exposure" stackId="a" fill="#557385" />
            <Bar dataKey="Isolation" stackId="a" fill="#DCC5A7" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    );
  }
}

WorkflowChart.propTypes = {
  title: PropTypes.string,
  tooltipKey: PropTypes.string,
  data: PropTypes.array,
};

export default WorkflowChart;
