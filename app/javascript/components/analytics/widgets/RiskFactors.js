import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Table, Button, Row, Col } from 'react-bootstrap';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import Switch from 'react-switch';
import _ from 'lodash';

const RISKLEVELS = ['High', 'Medium', 'Low', 'No Identified Risk', 'Missing']; // null will be mapped to `missing` later
let RISK_FACTORS = [];
let COUNTRIES_OF_INTEREST = []; // If certain countries are desired, they can be specified here
const NUMBER_OF_COUNTRIES_TO_SHOW = 5;

class RiskFactors extends React.Component {
  constructor(props) {
    super(props);
    this.state = { checked: false, viewTotal: this.props.viewTotal };
    this.exportFullCountryData = this.exportFullCountryData.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.toggleBetweenActiveAndTotal = this.toggleBetweenActiveAndTotal.bind(this);
    this.obtainValueFromMonitoreeCounts = this.obtainValueFromMonitoreeCounts.bind(this);
    this.ERRORS = !Object.prototype.hasOwnProperty.call(this.props.stats, 'monitoree_counts');
    this.ERRORSTRING = this.ERRORS ? 'Incorrect Object Schema' : null;
    this.NO_COUNTRY_DATA = false;
    COUNTRIES_OF_INTEREST = _.uniq(this.props.stats.monitoree_counts.filter(x => x.category_type === 'Exposure Country').map(x => x.category)).sort();
    COUNTRIES_OF_INTEREST = [...COUNTRIES_OF_INTEREST.filter(riskFactor => riskFactor !== 'Total'), 'Total']; // Risk Factor has a category of Total
    // // COUNTRIES_OF_INTEREST = COUNTRIES_OF_INTEREST.filter(country => country !== 'Total');
    RISK_FACTORS = _.uniq(this.props.stats.monitoree_counts.filter(x => x.category_type === 'Risk Factor').map(x => x.category)).sort();
    RISK_FACTORS = [...RISK_FACTORS.filter(riskFactor => riskFactor !== 'Total'), 'Total']; // Risk Factor has a category of Total
    // This complex looking statement essentially removes the hardcoded string Total from the array, and makes sure that it is at the end
    // So that the UI shows Total at the bottom of the table
    if (!this.ERRORS) {
      this.riskData = this.obtainValueFromMonitoreeCounts(RISK_FACTORS, 'Risk Factor', this.state.viewTotal);
      this.coiData = this.obtainValueFromMonitoreeCounts(COUNTRIES_OF_INTEREST, 'Exposure Country', this.state.viewTotal);
      this.coiData = this.coiData.filter(data => data.name && data.name != null);
      this.NO_COUNTRY_DATA = this.coiData.length === 0;
      this.fullCountryData = JSON.parse(JSON.stringify(this.coiData));
      // obtainValueFromMonitoreeCounts returns the data in a format that recharts can read
      // but is not the easiest to parse. The gross lodash functions here just sum the total count of each category
      // for each country, then sort them, then take the top NUMBER_OF_COUNTRIES_TO_SHOW.
      this.coiData = this.coiData
        .sort((v1, v2) => _.sumBy(_.valuesIn(v2), a => (isNaN(a) ? 0 : a)) - _.sumBy(_.valuesIn(v1), a => (isNaN(a) ? 0 : a)))
        .slice(0, NUMBER_OF_COUNTRIES_TO_SHOW + 1); // the +1 is for one extra row for `Total`
      // 'Total' will always the most number of monitorees, so it will be at [0]
      // This array/spread creation essentially just reorders 'Total' to be at the bottom
      this.coiData = [...this.coiData.slice(1, 6), this.coiData[0]];
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

  exportFullCountryData = () => {
    let entryArray = this.fullCountryData.map(x => _.join(_.valuesIn(x).map(y => _.startCase(y))));
    let contentString = _.join(entryArray, '\n');
    let headerString = _.join(_.keysIn(this.fullCountryData[0]).map(x => _.startCase(x)));
    let csvContent = _.join([headerString, contentString], '\n');
    const url = window.URL.createObjectURL(new Blob([csvContent]));
    const link = document.createElement('a');
    link.href = url;
    self.csvFileName = `CompleteCountryData.csv`;
    link.setAttribute('download', `${self.csvFileName}`);
    document.body.appendChild(link);
    link.click();
  };
  handleChange = checked => this.setState({ checked });

  toggleBetweenActiveAndTotal = viewTotal => {
    this.riskData = this.obtainValueFromMonitoreeCounts(RISK_FACTORS, 'Risk Factor', viewTotal);
    this.coiData = this.obtainValueFromMonitoreeCounts(COUNTRIES_OF_INTEREST, 'Exposure Country', this.state.viewTotal);
    this.fullCountryData = JSON.parse(JSON.stringify(this.coiData));
    // obtainValueFromMonitoreeCounts returns the data in a format that recharts can read
    // but is not the easiest to parse. The gross lodash functions here just sum the total count of each category
    // for each country, then sort them, then take the top NUMBER_OF_COUNTRIES_TO_SHOW.
    this.coiData = this.coiData
      .sort((v1, v2) => _.sumBy(_.valuesIn(v2), a => (isNaN(a) ? 0 : a)) - _.sumBy(_.valuesIn(v1), a => (isNaN(a) ? 0 : a)))
      .slice(0, NUMBER_OF_COUNTRIES_TO_SHOW + 1); // the +1 is for one extra row for `Total`
    // 'Total' will always the most number of monitorees, so it will be at [0]
    // This array/spread creation essentially just reorders 'Total' to be at the bottom
    this.coiData = [...this.coiData.slice(1, 6), this.coiData[0]];
  };
  renderBarGraph() {
    return (
      <div className="mx-3 mt-2">
        <ResponsiveContainer width="100%" height={400}>
          <BarChart
            width={500}
            height={300}
            data={this.riskData.filter(x => x.name !== 'Total')}
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
            data={this.coiData.filter(x => x.name !== 'Total')}
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
        <div className="text-left h4">Exposure Risk Factors</div>
        <Table striped hover className="border mt-2 mb-0">
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
            {RISK_FACTORS.map(riskGroup => (
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
        <div className="text-secondary text-right mb-3">
          <i className="fas fa-info-circle mr-1"></i>
          Cumulative percentage may not sum to 100 as monitorees may report more than one exposure risk factor
        </div>
        {this.NO_COUNTRY_DATA ? (
          <div>
            <Row>
              <Col className="h4 text-left">Country of Exposure</Col>
            </Row>
            <div className="text-info display-6"> No Country Data Available </div>
          </div>
        ) : (
          <div>
            <Row>
              <Col className="h4 text-left">Country of Exposure</Col>
              <Col className="text-right">
                <Button variant="primary" className="ml-2 btn-square" onClick={this.exportFullCountryData}>
                  <i className="fas fa-download mr-1"></i>
                  Export Complete Country Data
                </Button>
              </Col>
            </Row>
            <Table striped hover className="border mt-2 mb-0">
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
                {this.coiData
                  .map(x => x.name)
                  .map(coiGroup => (
                    <tr key={coiGroup.toString() + '1'}>
                      <td key={coiGroup.toString() + '2'} className="font-weight-bold">
                        {coiGroup}
                      </td>
                      {RISKLEVELS.map((risklevel, risklevelIndex) => (
                        <td key={coiGroup.toString() + risklevelIndex.toString()}>{this.coiData.find(x => x.name === coiGroup)[String(risklevel)]}</td>
                      ))}
                      <td>{this.coiData.find(x => x.name === coiGroup)['total']}</td>
                    </tr>
                  ))}
              </tbody>
            </Table>
            <div className="text-secondary text-right mb-3">
              <i className="fas fa-info-circle mr-1"></i>
              Excludes monitorees where exposure country is not reported
            </div>
          </div>
        )}
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
          <Card.Header className="text-left h5">
            Among Those {this.state.viewTotal ? 'Ever Monitored (includes current)' : 'Currently Under Active Monitoring'}
          </Card.Header>
          <Card.Body>{this.ERRORS ? this.renderErrors() : this.renderCard()}</Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

RiskFactors.propTypes = {
  stats: PropTypes.object,
  viewTotal: PropTypes.bool,
};

export default RiskFactors;
