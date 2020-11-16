import React from 'react';
import { PropTypes } from 'prop-types';
import { Card } from 'react-bootstrap';
import { BarChart, Bar, ResponsiveContainer, CartesianGrid, Text, XAxis, YAxis, Label } from 'recharts';

class MonitoringDistributionDay extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    const data = this.props.stats.monitoring_distribution_by_day;
    return (
      <React.Fragment>
        <Card className="card-square">
          <Card.Header className="h5">Monitoring Distribution by Day</Card.Header>
          <Card.Body>
            <div className="pb-4 h5">DISTRIBUTION OF MONITOREES UNDER MONITORING</div>
            <div style={{ width: '100%', height: '286px' }} className="recharts-wrapper">
              <ResponsiveContainer>
                <BarChart data={data}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="day">
                    <Label value="Day of Monitoring" position="insideBottom" offset={-3} />
                  </XAxis>
                  <YAxis
                    label={
                      <Text x={-30} y={60} dx={50} dy={150} offset={0} angle={-90}>
                        Number of Monitorees
                      </Text>
                    }
                  />
                  <Bar dataKey="cases" fill="#0E4F6D" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

MonitoringDistributionDay.propTypes = {
  stats: PropTypes.object,
};

export default MonitoringDistributionDay;
