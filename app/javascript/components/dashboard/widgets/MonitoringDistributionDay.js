import React from "react"
import { Card } from 'react-bootstrap';
import { BarChart, Bar, ResponsiveContainer, CartesianGrid, Text, XAxis, YAxis, Label } from 'recharts';

class MonitoringDistributionDay extends React.Component {

  constructor(props) {
    super(props);
  }

  render () {

    const data = [
      {
        day: '0', cases: 50
      },
      {
        day: '1', cases: 54
      },
      {
        day: '2', cases: 42
      },
      {
        day: '3', cases: 34
      },
      {
        day: '4', cases: 67
      },
      {
        day: '5', cases: 12
      },
    ];

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

export default MonitoringDistributionDay