import React from 'react';
import { PropTypes } from 'prop-types';
import { Card } from 'react-bootstrap';
import { BarChart, Bar, ResponsiveContainer, CartesianGrid, Text, XAxis, YAxis, Tooltip } from 'recharts';

class ReportingSummary extends React.Component {
  constructor(props) {
    super(props);
    this.data = [...this.props.stats.assessment_result_by_day];
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square">
          <Card.Header className="h5">Total Assessments Over Time</Card.Header>
          <Card.Body>
            <div style={{ width: '100%', height: '286px' }} className="recharts-wrapper">
              <ResponsiveContainer>
                <BarChart data={this.data}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <Tooltip />
                  <YAxis
                    label={
                      <Text x={-30} y={60} dx={50} dy={150} offset={0} angle={-90}>
                        Number of Monitorees
                      </Text>
                    }
                  />
                  <Bar dataKey="Asymptomatic Assessments" stackId="a" fill="#39CC7D" />
                  <Bar dataKey="Symptomatic Assessments" stackId="a" fill="#FF6868" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

ReportingSummary.propTypes = {
  stats: PropTypes.object,
};

export default ReportingSummary;
