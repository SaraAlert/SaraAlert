import React from 'react';
import { Row, Col, Card } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import { PieChart, Pie, ResponsiveContainer, Cell, Legend, Label, Tooltip } from 'recharts';

const COLOR_MAPPING = [
  { name: 'Asymptomatic', color: '#39CC7D' },
  { name: 'Non-Reporting', color: '#FCDA4B' },
  { name: 'Symptomatic', color: '#FF6868' },
  { name: 'Closed', color: '#363537' },
];

class SystemStatistics extends React.Component {
  constructor(props) {
    super(props);
    this.getColorForType = this.getColorForType.bind(this);
    this.data = [...this.props.stats.subject_status];
    this.percentageChange = (this.props.stats.system_subjects_last_24 + this.props.stats.system_subjects) / this.props.stats.system_subjects;
    this.percentageChange = (this.percentageChange * 100 - 100).toFixed(1);
  }

  getColorForType(type) {
    let colorMapping = COLOR_MAPPING.find(color => color.name === type.name);
    if (typeof colorMapping === 'undefined') {
      return '#000';
    } else {
      return colorMapping.color;
    }
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square">
          <Card.Header as="h5">System Statistics</Card.Header>
          <Card.Body className="pb-1">
            <Row className="text-center">
              <Col className="">
                <h4 className="mb-0"> Total Monitorees </h4>
                <div style={{ width: '100%', height: 250 }} className="recharts-wrapper">
                  <ResponsiveContainer>
                    <PieChart onMouseEnter={this.onPieEnter}>
                      <Pie data={this.data} innerRadius={55} outerRadius={85} fill="#8884d8" paddingAngle={2} dataKey="value">
                        {this.data.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={this.getColorForType(entry)} />
                        ))}
                        <Label className="display-5" value={this.props.stats.system_subjects} position="center" />
                      </Pie>
                      <Legend layout="vertical" align="right" verticalAlign="middle">
                        {' '}
                      </Legend>
                      <Tooltip />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
                <div className="text-muted">
                  {this.percentageChange > 0
                    ? `Count is up ${this.props.stats.system_subjects_last_24} (${this.percentageChange}%) within last 24 hours`
                    : null}
                </div>
              </Col>
            </Row>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

SystemStatistics.propTypes = {
  stats: PropTypes.object,
};

export default SystemStatistics;
