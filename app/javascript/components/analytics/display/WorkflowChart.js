import React from 'react';
import { PropTypes } from 'prop-types';
import { Bar, BarChart, CartesianGrid, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import CustomizedAxisTick from '../display/CustomizedAxisTick';
import InfoTooltip from '../../util/InfoTooltip';

const COLORS = ['#226891', '#3d8f8f', '#90ad8a', '#dcc5a7'];

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
        <div>
        <ResponsiveContainer width="100%" height={500}>
          <BarChart
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
            {this.props.workflows.map((workflow, i) => (
              <Bar key={i} dataKey={workflow} stackId="a" fill={COLORS[i]} />
            ))}
          </BarChart>
        </ResponsiveContainer>
        </div>
      </div>
    );
  }
}

WorkflowChart.propTypes = {
  title: PropTypes.string,
  tooltipKey: PropTypes.string,
  workflows: PropTypes.array,
  data: PropTypes.array,
};

WorkflowChart.defaultProps = {
  workflows: ['Exposure', 'Isolation'],
};

export default WorkflowChart;
