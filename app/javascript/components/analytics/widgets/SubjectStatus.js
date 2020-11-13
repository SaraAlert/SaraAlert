import React from 'react';
import { PropTypes } from 'prop-types';
import { Card } from 'react-bootstrap';
import { PieChart, Pie, ResponsiveContainer, Cell, Legend, Label, Tooltip } from 'recharts';

class SubjectStatus extends React.Component {
  constructor(props) {
    super(props);
  }
  render() {
    const data = [...this.props.stats.subject_status];
    const COLORS = ['#39CC7D', '#FCDA4B', '#FF6868', '#6C757D'];

    return (
      <React.Fragment>
        <Card className="card-square">
          <Card.Header className="h5">Monitoree Status</Card.Header>
          <Card.Body>
            <div style={{ width: '100%', height: 260 }} className="recharts-wrapper">
              <ResponsiveContainer>
                <PieChart onMouseEnter={this.onPieEnter}>
                  <Pie data={data} innerRadius={70} outerRadius={100} fill="#8884d8" paddingAngle={2} dataKey="value" label>
                    {data.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                    <Label className="display-5" value={this.props.stats.system_subjects} position="center" />
                  </Pie>
                  <Legend layout="vertical" align="right" verticalAlign="middle" />
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

SubjectStatus.propTypes = {
  stats: PropTypes.object,
};

export default SubjectStatus;
