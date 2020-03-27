import React from 'react';
import { Card } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';

import _ from 'lodash';

let DATES_OF_INTEREST = []; // If certain countries are desired, they can be specified here
const RISKLEVELS = ['High', 'Medium', 'Low', 'No Identified Risk', 'Missing']; // null will be mapped to `missing` later

class MonitoreesByDateOfExposure extends React.Component {
  constructor(props) {
    super(props);
    this.obtainValueFromMonitoreeCounts = this.obtainValueFromMonitoreeCounts.bind(this);

    DATES_OF_INTEREST = _.uniq(this.props.stats.monitoree_counts.filter(x => x.category_type === 'Last Exposure Date').map(x => x.category))
      .sort()
      .slice(0, 14);
    this.lastExposureDateDate = this.obtainValueFromMonitoreeCounts(DATES_OF_INTEREST, 'Last Exposure Date', true);
  }

  obtainValueFromMonitoreeCounts = (enumerations, category_type, onlyActive) => {
    let activeMonitorees = this.props.stats.monitoree_counts.filter(x => x.active_monitoring === onlyActive);
    let thisCategoryGroups = activeMonitorees.filter(x => x.category_type === category_type);
    return enumerations.map(x => {
      let thisGroup = thisCategoryGroups.filter(group => group.category === x);
      let retVal = { name: x };
      RISKLEVELS.forEach(val => {
        retVal[String(val)] = _.sum(thisGroup.filter(z => z.risk_level === val).map(z => z.total));
        if (onlyActive) {
          // REMOVE THIS CODE IT IS BAD AND ONLY FOR TESTING
          retVal[String(val)] += 5;
        }
      });
      return retVal;
    });
  };

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <Card.Header as="h5" className="text-left">
            Total Monitorees by Date of Last Exposure By Risk Status
          </Card.Header>
          <Card.Body>
            <ResponsiveContainer width="100%" height={400}>
              <BarChart
                width={500}
                height={300}
                data={this.lastExposureDateDate}
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
