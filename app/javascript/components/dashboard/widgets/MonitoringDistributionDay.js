import React from "react"
import { Card } from 'react-bootstrap';
import { BarChart, Bar, ResponsiveContainer, CartesianGrid, Text, XAxis, YAxis, Label, Tooltip } from 'recharts';
import { PropTypes } from 'prop-types';

class MonitoringDistributionDay extends React.Component {

  constructor(props) {
    super(props);
  }

  render () {
    const data = this.props.stats.monitoring_distribution_by_day;
    return (
      <React.Fragment>
        <Card className="card-square">
          <Card.Header as="h5">Monitoring Distribution by Day</Card.Header>
          <Card.Body>
            <h5 className="pb-4">DISTRIBUTION OF SUBJECTS UNDER MONITORING</h5>
            <div style={{ width: '100%', height: '330px' }} className="recharts-wrapper">
              <ResponsiveContainer>
                <BarChart
                  data={data}
                >
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="day">
                    <Label value="Day of Monitoring" position="insideBottom" />
                  </XAxis>
                  <Tooltip />
                  <YAxis label={<Text x={-30} y={60} dx={50} dy={150} offset={0} angle={-90}>Number of Subjects</Text>} />
                  <Bar dataKey="cases" fill="#0088FE" />
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
  stats: PropTypes.object
};

export default MonitoringDistributionDay