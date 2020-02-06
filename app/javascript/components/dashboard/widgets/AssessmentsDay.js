import React from "react";
import { Card } from 'react-bootstrap';
import { LineChart, ResponsiveContainer, XAxis, YAxis, Legend, CartesianGrid, Line, Tooltip } from 'recharts';
import { PropTypes } from 'prop-types';

class AssessmentsDay extends React.Component {

  constructor(props) {
    super(props);
  }

  render () {
    const data = this.props.stats.assessment_result_by_day;
    return (
      <React.Fragment>
        <Card className="card-square">
          <Card.Header as="h5">Assessment Type Over Time</Card.Header>
          <Card.Body>
            <div style={{ width: '100%', height: '300px' }} className="recharts-wrapper">
              <ResponsiveContainer>
                <LineChart data={data}>
                  <XAxis dataKey="name"/>
                  <YAxis/>
                  <CartesianGrid strokeDasharray="3 3"/>
                  <Legend />
                  <Tooltip />
                  <Line type="monotone" dataKey="Symptomatic Assessments" stroke="#8884d8" activeDot={{r: 8}}/>
                  <Line type="monotone" dataKey="Asymptomatic Assessments" stroke="#82ca9d" />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

AssessmentsDay.propTypes = {
  stats: PropTypes.object
};

export default AssessmentsDay