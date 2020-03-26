import React from 'react';
import { Card, Table } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import Switch from 'react-switch';
import _ from 'lodash';

const SEXES = ['Male', 'Female', 'Unknown'];
const COUNTRIES_OF_INTEREST = ['United States of America', 'China', 'South Korea', 'Italy', 'United Kingdom'];
const RISKLEVELS = ['High', 'Medium', 'Low', 'No Identified Risk', 'Missing']; // null will be mapped to `missing` later

class AgeStratificationActive extends React.Component {
  constructor(props) {
    super(props);
    this.state = { checked: true, viewTotal: false };
    this.handleChange = this.handleChange.bind(this);
    this.toggleBetweenActiveAndTotal = this.toggleBetweenActiveAndTotal.bind(this);
    this.obtainValueFromMonitoreeCounts = this.obtainValueFromMonitoreeCounts.bind(this);
    this.ERRORS = !Object.prototype.hasOwnProperty.call(this.props.stats, 'monitoree_counts');
    this.ERRORSTRING = this.ERRORS ? 'Incorrect Object Schema' : null;
    if (!this.ERRORS) {
      this.sexData = this.obtainValueFromMonitoreeCounts(SEXES, 'sex', this.state.viewTotal);
      this.coiData = this.obtainValueFromMonitoreeCounts(COUNTRIES_OF_INTEREST, 'exposure_country', this.state.viewTotal);
    }
  }

  obtainValueFromMonitoreeCounts = (enumerations, category_type, onlyActive) => {
    let activeMonitorees = this.props.stats.monitoree_counts.filter(x => x.active_monitoring === onlyActive);
    let thisCategoryGroups = activeMonitorees.filter(x => x.category_type === category_type);
    return enumerations.map(x => {
      let thisGroup = thisCategoryGroups.filter(group => group.category === x);
      let retVal = { name: x };
      RISKLEVELS.forEach(val => {
        retVal[val] = _.sum(thisGroup.filter(z => z.risk_level === val).map(z => z.total));
        if (onlyActive) {
          // REMOVE THIS CODE IT IS BAD AND ONLY FOR TESTING
          retVal[val] += 5;
        }
      });
      return retVal;
    });
  };

  handleChange = checked => this.setState({ checked });

  toggleBetweenActiveAndTotal = viewTotal => {
    this.sexData = this.obtainValueFromMonitoreeCounts(SEXES, 'sex', viewTotal);
    this.coiData = this.obtainValueFromMonitoreeCounts(COUNTRIES_OF_INTEREST, 'exposure_country', viewTotal);
    this.setState({ viewTotal });
  };
  renderBarGraph() {
    return (
      <div className="mx-3 mt-2">
        <ResponsiveContainer width="100%" height={400}>
          <BarChart
            width={500}
            height={300}
            data={this.sexData}
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
        <ResponsiveContainer width="100%" height={400}>
          <BarChart
            width={500}
            height={300}
            data={this.coiData}
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
      <div>
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
            {SEXES.map(sexgroup => (
              <tr key={sexgroup.toString() + '1'}>
                <td key={sexgroup.toString() + '2'} className="font-weight-bold">
                  {' '}
                  {sexgroup}{' '}
                </td>
                {RISKLEVELS.map((risklevel, risklevelIndex) => (
                  <td key={sexgroup.toString() + risklevelIndex.toString()}>{this.sexData.find(x => x.name === sexgroup)[risklevel]}</td>
                ))}
              </tr>
            ))}
          </tbody>
        </Table>
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
            {COUNTRIES_OF_INTEREST.map(coiGroup => (
              <tr key={coiGroup.toString() + '1'}>
                <td key={coiGroup.toString() + '2'} className="font-weight-bold">
                  {' '}
                  {coiGroup}{' '}
                </td>
                {RISKLEVELS.map((risklevel, risklevelIndex) => (
                  <td key={coiGroup.toString() + risklevelIndex.toString()}>{this.coiData.find(x => x.name === coiGroup)[risklevel]}</td>
                ))}
              </tr>
            ))}
          </tbody>
        </Table>
      </div>
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
            Among Those {this.state.viewTotal ? 'Ever Monitored (includes current)' : 'Currently Under Active Monitoring'}
            <span className="float-right display-6">
              {' '}
              View Total
              <Switch
                className="ml-2"
                onChange={this.toggleBetweenActiveAndTotal}
                onColor="#82A0E4"
                height={18}
                width={40}
                uncheckedIcon={false}
                checked={this.state.viewTotal}
              />
            </span>
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
