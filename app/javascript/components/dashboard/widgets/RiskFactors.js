import React from 'react';
import { Card, Table } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import Switch from 'react-switch';
import _ from 'lodash';

let RISK_FACTORS = [];
const RISKLEVELS = ['High', 'Medium', 'Low', 'No Identified Risk', 'Missing']; // null will be mapped to `missing` later
class RiskFactor extends React.Component {
  constructor(props) {
    super(props);
    this.state = { checked: false, viewTotal: this.props.viewTotal };
    this.handleChange = this.handleChange.bind(this);
    this.toggleBetweenActiveAndTotal = this.toggleBetweenActiveAndTotal.bind(this);
    this.obtainValueFromMonitoreeCounts = this.obtainValueFromMonitoreeCounts.bind(this);
    this.ERRORS = !Object.prototype.hasOwnProperty.call(this.props.stats, 'monitoree_counts');
    this.ERRORSTRING = this.ERRORS ? 'Incorrect Object Schema' : null;
    RISK_FACTORS = _.uniq(this.props.stats.monitoree_counts.filter(x => x.category_type === 'Risk Factor').map(x => x.category)).sort();

    if (!this.ERRORS) {
      this.riskData = this.obtainValueFromMonitoreeCounts(RISK_FACTORS, 'Risk Factor', this.state.viewTotal);
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.viewTotal !== prevProps.viewTotal) {
      this.toggleBetweenActiveAndTotal(this.props.viewTotal);
    }
  }

  obtainValueFromMonitoreeCounts(enumerations, category_type, onlyActive) {
    let activeMonitorees = this.props.stats.monitoree_counts.filter(x => x.active_monitoring === onlyActive);
    let categoryGroups = activeMonitorees.filter(x => x.category_type === category_type);
    return enumerations.map(x => {
      let thisGroup = categoryGroups.filter(group => group.category === x);
      let retVal = { name: x, total: 0 };
      RISKLEVELS.forEach(val => {
        retVal[String(val)] = _.sum(thisGroup.filter(z => z.risk_level === val).map(z => z.total));
        retVal.total += _.sum(thisGroup.filter(z => z.risk_level === val).map(z => z.total));
      });
      return retVal;
    });
  }

  handleChange = checked => this.setState({ checked });

  toggleBetweenActiveAndTotal = viewTotal => {
    this.riskData = this.obtainValueFromMonitoreeCounts(RISK_FACTORS, 'Risk Factor', viewTotal);
  };

  renderBarGraph() {
    return (
      <div className="mx-3 mt-2">
        <ResponsiveContainer width="100%" height={400}>
          <BarChart
            width={500}
            height={300}
            data={this.riskFactor}
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
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            {this.riskData
              .map(x => x.name)
              .map(riskGroup => (
                <tr key={riskGroup.toString() + '1'}>
                  <td key={riskGroup.toString() + '2'} className="font-weight-bold">
                    {riskGroup}
                  </td>
                  {RISKLEVELS.map((risklevel, risklevelIndex) => (
                    <td key={riskGroup.toString() + risklevelIndex.toString()}>{this.riskData.find(x => x.name === riskGroup)[String(risklevel)]}</td>
                  ))}
                  <td>{this.riskData.find(x => x.name === riskGroup)['total']}</td>
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
          </Card.Header>
          <Card.Body>{this.ERRORS ? this.renderErrors() : this.renderCard()}</Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

RiskFactor.propTypes = {
  stats: PropTypes.object,
  viewTotal: PropTypes.bool,
};

export default RiskFactor;
