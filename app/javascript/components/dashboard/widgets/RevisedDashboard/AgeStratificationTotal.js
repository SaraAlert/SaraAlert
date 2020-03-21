import React from 'react';
import { Card, Table } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import Switch from 'react-switch';

const AGEGROUPS = ['0-19', '20-29', '30-39', '40-49', '50-59', '60-69', '70-79', '>=80'];
const RISKLEVELS = ['High', 'Medium', 'Low', 'No Identified Risk', 'Missing']; // null will be mapped to `missing` later

class AgeStratificationActive extends React.Component {
  constructor(props) {
    super(props);
    console.log(JSON.parse(JSON.stringify(props)));
    this.state = { checked: false, viewTotal: false };
    this.handleChange = this.handleChange.bind(this);
    this.ERRORS = !Object.prototype.hasOwnProperty.call(this.props.stats, 'risk_level_counts');
    this.ERRORSTRING = this.ERRORS ? 'Incorrect Object Schema' : null;
    if (!this.ERRORS) {
      let activeMonitorees = this.props.stats.risk_level_counts.filter(x => x.active_monitoring);
      let ageGroups = activeMonitorees.filter(x => x.category_type === 'age_group');
      this.data = AGEGROUPS.map(x => {
        let thisAgeGroup = ageGroups.filter(group => group.category === x);
        let retVal = { name: x };
        RISKLEVELS.forEach(val => {
          retVal[val] = thisAgeGroup.find(z => z.risk_level === (val === 'Missing' ? null : val))?.risk_level_count;
        });
        return retVal;
      });
    }
  }

  handleChange = checked => this.setState({ checked });

  toggleBetweenActiveAndTotal = viewTotal => {
    this.setState({ viewTotal });
    let activeMonitorees = this.props.stats.risk_level_counts;
    if (viewTotal) {
      activeMonitorees = activeMonitorees.filter(x => x.active_monitoring);
    }
    let ageGroups = activeMonitorees.filter(x => x.category_type === 'age_group');
    this.data = AGEGROUPS.map(x => {
      let thisAgeGroup = ageGroups.filter(group => group.category === x);
      let retVal = { name: x };
      RISKLEVELS.forEach(val => {
        retVal[val] = thisAgeGroup.find(z => z.risk_level === (val === 'Missing' ? null : val))?.risk_level_count;
      });
      return retVal;
    });
  };

  renderBarGraph() {
    return (
      <div className="mx-3 mt-2">
        <ResponsiveContainer width="100%" height={400}>
          <BarChart
            width={500}
            height={300}
            data={this.data}
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
      </div>
    );
  }

  renderTable() {
    return (
      <Table striped hover className="border mt-2">
        <thead>
          <tr>
            <th></th>
            {RISKLEVELS.map(risklevel => (
              <th key={risklevel.toString()}>{risklevel}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {AGEGROUPS.map(agegroup => (
            <tr key={agegroup.toString() + '1'}>
              <td key={agegroup.toString() + '2'} className="font-weight-bold">
                {' '}
                {agegroup}{' '}
              </td>
              {RISKLEVELS.map((risklevel, risklevelIndex) => (
                <td key={agegroup.toString() + risklevelIndex.toString()}>{this.data.find(x => x.name === agegroup)[risklevel]}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </Table>
    );
  }

  renderErrors() {
    return <div className="text-danger display-6"> ERROR: {this.ERRORSTRING}. </div>;
  }

  renderCard() {
    return (
      <span>
        <div className="text-right">
          <span className="mr-2 display-6"> View Data as Graph </span>
          <Switch onChange={this.handleChange} onColor="#82A0E4" height={18} width={40} uncheckedIcon={false} checked={this.state.checked} />
        </div>
        {this.state.checked ? this.renderBarGraph() : this.renderTable()}
      </span>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <Card.Header as="h5" className="text-left">
            Among Those Currently Under Active Monitoring
            <div className="text-right">
              <span className="mr-2 display-6"> View Total </span>
              <Switch
                onChange={this.toggleBetweenActiveAndTotal}
                onColor="#82A0E4"
                height={18}
                width={40}
                uncheckedIcon={false}
                checked={this.state.viewTotal}
              />
            </div>
          </Card.Header>
          <Card.Body>{this.ERRORS ? this.renderErrors() : this.renderCard()}</Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

AgeStratificationActive.propTypes = {
  stats: PropTypes.object,
};

export default AgeStratificationActive;
