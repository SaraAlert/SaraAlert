import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Form, Col } from 'react-bootstrap';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import _ from 'lodash';

let DATES_OF_INTEREST = []; // If certain dates are desired, they can be specified here
const RISKLEVELS = ['High', 'Medium', 'Low', 'No Identified Risk', 'Missing']; // null will be mapped to `missing` later

class MonitoreesByDateOfExposure extends React.Component {
  constructor(props) {
    super(props);
    this.obtainValueFromMonitoreeCounts = this.obtainValueFromMonitoreeCounts.bind(this);
    this.setTimeResolution = this.setTimeResolution.bind(this);
    this.state = {
      lastExposureDateDate: [],
    };
  }

  componentDidMount() {
    this.setTimeResolution('Day');
  }

  obtainValueFromMonitoreeCounts = (enumerations, category_type) => {
    let activeMonitorees = this.props.stats.monitoree_counts.filter(x => x.active_monitoring);
    let categoryGroups = activeMonitorees.filter(x => x.category_type === category_type);
    return enumerations.map(x => {
      let thisGroup = categoryGroups.filter(group => group.category === x);
      let retVal = { name: x };
      RISKLEVELS.forEach(val => {
        retVal[String(val)] = _.sum(thisGroup.filter(z => z.risk_level === val).map(z => z.total));
      });
      return retVal;
    });
  };

  setTimeResolution(timeRes) {
    let categoryString;
    if (timeRes === 'Day') {
      categoryString = 'Last Exposure Date';
    } else if (timeRes === 'Week') {
      categoryString = 'Last Exposure Week';
    } else if (timeRes === 'Month') {
      categoryString = 'Last Exposure Month';
    }
    DATES_OF_INTEREST = _.uniq(this.props.stats.monitoree_counts.filter(x => x.category_type === categoryString).map(x => x.category))
      .sort()
      .slice(0, 14);
    this.setState({ lastExposureDateDate: _.cloneDeep(this.obtainValueFromMonitoreeCounts(DATES_OF_INTEREST, categoryString)) });
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <Card.Header className="text-left h5">Total Monitorees by Date of Last Exposure By Risk Status</Card.Header>
          <Card.Body>
            <Form.Row className="justify-content-md-center">
              <Form.Group
                as={Col}
                md="8"
                onChange={val => {
                  this.setTimeResolution(val.target.value);
                }}>
                <Form.Label>Time Resolution</Form.Label>
                <Form.Control as="select" size="md">
                  <option>Day</option>
                  <option>Week</option>
                  <option>Month</option>
                </Form.Control>
              </Form.Group>
            </Form.Row>
            <ResponsiveContainer width="100%" height={400}>
              <BarChart
                width={500}
                height={300}
                data={this.state.lastExposureDateDate}
                margin={{
                  top: 20,
                  right: 30,
                  left: 20,
                  bottom: 5,
                }}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="High" stackId="a" fill="#FA897B" />
                <Bar dataKey="Medium" stackId="a" fill="#FFDD94" />
                <Bar dataKey="Low" stackId="a" fill="#D0E6A5" />
                <Bar dataKey="No Identified Risk" stackId="a" fill="#333" />
                <Bar dataKey="Missing" stackId="a" fill="#BABEC4" />
              </BarChart>
            </ResponsiveContainer>
            <div className="text-secondary text-right">
              <i className="fas fa-exclamation-circle mr-1"></i>
              Illnesses that began
              {` ${this.state.lastExposureDateDate[this.state.lastExposureDateDate.length - 1]?.name} `}
              may not yet be reported
            </div>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

MonitoreesByDateOfExposure.propTypes = {
  stats: PropTypes.object,
};

export default MonitoreesByDateOfExposure;
