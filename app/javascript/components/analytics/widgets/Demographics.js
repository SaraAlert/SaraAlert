import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Col, Row } from 'react-bootstrap';
import { Bar, BarChart, CartesianGrid, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';

import { mapToChartFormat, parseOutFields } from '../../../utils/Analytics';
import _ from 'lodash';

import CustomizedAxisTick from '../display/CustomizedAxisTick';
import InfoTooltip from '../../util/InfoTooltip';

let WORKFLOWS; // = ['Exposure', 'Isolation'];
const AGEGROUPS = ['0-19', '20-29', '30-39', '40-49', '50-59', '60-69', '70-79', '>=80', 'Missing', 'FAKE_BIRTHDATE'];
const SEXES = ['Male', 'Female', 'Unknown', 'Missing'];
const ETHNICITIES = ['Hispanic or Latino', 'Not Hispanic or Latino', 'Missing'];
const RACES = [
  'White',
  'Black or African American',
  'Asian',
  'American Indian or Alaska Native',
  'Native Hawaiian or Other Pacific Islander',
  'More Than One Race',
  'Unknown',
  'Missing',
];
const SEXUAL_ORIENTATIONS = [
  'Straight or Heterosexual',
  'Lesbian, Gay, or Homosexual',
  'Bisexual',
  'Another',
  'Choose not to disclose',
  'Don’t know',
  'Missing',
];

class Demographics extends React.Component {
  constructor(props) {
    super(props);
    WORKFLOWS = this.props.available_workflows.map(wf => wf.label);

    this.ageData = parseOutFields(this.props.stats.monitoree_counts, AGEGROUPS, 'Age Group', WORKFLOWS);
    this.sexData = parseOutFields(this.props.stats.monitoree_counts, SEXES, 'Sex', WORKFLOWS);
    this.ethnicityData = parseOutFields(this.props.stats.monitoree_counts, ETHNICITIES, 'Ethnicity', WORKFLOWS);
    this.raceData = parseOutFields(this.props.stats.monitoree_counts, RACES, 'Race', WORKFLOWS);
    this.soData = parseOutFields(this.props.stats.monitoree_counts, SEXUAL_ORIENTATIONS, 'Sexual Orientation', WORKFLOWS);
    this.hasFakeBirthdateData = false;
    this.numberOfFakeBirthdates = 0;

    // Meaning we have monitorees with fake birthdates
    if (_.last(_.last(this.ageData)) !== 0) {
      this.hasFakeBirthdateData = true;
      this.numberOfFakeBirthdates = _.last(_.last(this.ageData));
      let indexOfGreaterThan80 = AGEGROUPS.findIndex(x => x === '>=80');
      // This overly complex statement just adds every value from the `110+` fields to the `>=80` fields
      this.ageData[Number(indexOfGreaterThan80)] = this.ageData[Number(indexOfGreaterThan80)].map(
        (x, i) => this.ageData[Number(indexOfGreaterThan80)][Number(i)] + _.last(this.ageData)[Number(i)]
      );
    }

    // If the sum here is 0, means the jurisdiction doesnt track SO
    this.showSexualOrientationData = !!_.sum(this.soData.map(x => _.last(x)));

    // Map and translate all of the Tabular Data to the Chart Format
    this.ageChartData = mapToChartFormat(_.initial(AGEGROUPS), this.ageData, WORKFLOWS);
    this.sexChartData = mapToChartFormat(SEXES, this.sexData, WORKFLOWS);
    this.ethnicityChartData = mapToChartFormat(ETHNICITIES, this.ethnicityData, WORKFLOWS);
    this.raceChartData = mapToChartFormat(RACES, this.raceData, WORKFLOWS);
    this.soChartData = mapToChartFormat(SEXUAL_ORIENTATIONS, this.soData, WORKFLOWS);
    this.barGraphData = [
      { title: 'Current Age (Years)', data: this.ageChartData },
      { title: 'Sex', data: this.sexChartData },
      { title: 'Ethnicity', data: this.ethnicityChartData },
      { title: 'Race', data: this.raceChartData },
      { title: 'Sexual Orientation', data: this.soChartData },
    ];
  }

  renderBarGraphs = () => (
    <Card.Body className="mt-5">
      <Row>
        {this.barGraphData.map((graphData, i) => (
          <Col xl="12" key={i}>
            <div className="mx-2 mt-3 analytics-chart-borders">
              <div className="text-center h4">
                {graphData.title}
                {graphData.title === 'Current Age (Years)' ? (
                  <span className="h6">
                    <InfoTooltip tooltipTextKey="analyticsAgeTip" location="right"></InfoTooltip>
                  </span>
                ) : (
                  ''
                )}
              </div>
              <ResponsiveContainer width="100%" height={400}>
                <BarChart
                  width={500}
                  height={300}
                  data={graphData.data}
                  margin={{
                    top: 20,
                    right: 30,
                    left: 20,
                    bottom: 5,
                  }}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" interval={0} tick={<CustomizedAxisTick />} height={100} />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="Exposure" stackId="a" fill="#557385" />
                  <Bar dataKey="Isolation" stackId="a" fill="#DCC5A7" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </Col>
        ))}
      </Row>
    </Card.Body>
  );

  renderTables = () => (
    <Card.Body className="mt-4">
      <Row>
        <Col md="12">
          <div className="text-left mt-2 mb-n1">
            <span className="h4">Current Age (Years)</span>
            <span className="h6">
              <InfoTooltip tooltipTextKey="analyticsAgeTip" location="right"></InfoTooltip>
            </span>
          </div>
          <table className="analytics-table">
            <thead>
              <tr>
                <th className="py-0"></th>
                {WORKFLOWS.map((header, index) => (
                  <th key={index} className="font-weight-bold">
                    {' '}
                    <u>{_.upperCase(header)}</u>{' '}
                  </th>
                ))}
                <th>Total</th>
              </tr>
            </thead>
            <tbody>
              {_.initial(AGEGROUPS).map((val, index1) => (
                <tr key={`workflow-table-${index1}`} className={index1 % 2 ? '' : 'analytics-zebra-bg'}>
                  <td className="font-weight-bold"> {val} </td>
                  {this.ageData[Number(index1)].map((data, subIndex1) => (
                    <td key={subIndex1}> {data} </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
          {this.hasFakeBirthdateData && (
            <div className="text-secondary fake-demographic-text mb-3">
              <i className="fas fa-info-circle mr-3"></i>
              &gt;=80 years category includes {this.numberOfFakeBirthdates} monitorees where age is greater than 110.
            </div>
          )}
        </Col>
        <Col md="12">
          <div className="text-left mt-2 mb-n1 h4">Race</div>
          <table className="analytics-table">
            <thead>
              <tr>
                <th className="py-0"></th>
                {WORKFLOWS.map((header, index) => (
                  <th key={index} className="font-weight-bold">
                    {' '}
                    <u>{_.upperCase(header)}</u>{' '}
                  </th>
                ))}
                <th>Total</th>
              </tr>
            </thead>
            <tbody>
              {RACES.map((val, index4) => (
                <tr key={`workflow-table-${index4}`} className={index4 % 2 ? '' : 'analytics-zebra-bg'}>
                  <td className="font-weight-bold"> {val} </td>
                  {this.raceData[Number(index4)].map((data, subIndex4) => (
                    <td key={subIndex4}> {data} </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </Col>
        <Col md="12">
          <div className="text-left mt-3 mb-n1 h4">Sex</div>
          <table className="analytics-table">
            <thead>
              <tr>
                <th className="py-0"></th>
                {WORKFLOWS.map((header, index) => (
                  <th key={index} className="font-weight-bold">
                    {' '}
                    <u>{_.upperCase(header)}</u>{' '}
                  </th>
                ))}
                <th>Total</th>
              </tr>
            </thead>
            <tbody>
              {SEXES.map((val, index2) => (
                <tr key={`workflow-table-${index2}`} className={index2 % 2 ? '' : 'analytics-zebra-bg'}>
                  <td className="font-weight-bold"> {val} </td>
                  {this.sexData[Number(index2)].map((data, subIndex2) => (
                    <td key={subIndex2}> {data} </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
          <div className="text-left mt-3 mb-n1 h4">Ethnicity</div>
          <table className="analytics-table">
            <thead>
              <tr>
                <th className="py-0"></th>
                {WORKFLOWS.map((header, index) => (
                  <th key={index} className="font-weight-bold">
                    {' '}
                    <u>{_.upperCase(header)}</u>{' '}
                  </th>
                ))}
                <th>Total</th>
              </tr>
            </thead>
            <tbody>
              {ETHNICITIES.map((val, index3) => (
                <tr key={`workflow-table-${index3}`} className={index3 % 2 ? '' : 'analytics-zebra-bg'}>
                  <td className="font-weight-bold"> {val} </td>
                  {this.ethnicityData[Number(index3)].map((data, subIndex3) => (
                    <td key={subIndex3}> {data} </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </Col>
        <Col md="12">
          {this.showSexualOrientationData && (
            <div>
              <div className="text-left mt-3 mb-n1 h4">Sexual Orientation</div>
              <table className="analytics-table">
                <thead>
                  <tr>
                    <th className="py-0"></th>
                    {WORKFLOWS.map((header, index) => (
                      <th key={index} className="font-weight-bold">
                        {' '}
                        <u>{_.upperCase(header)}</u>{' '}
                      </th>
                    ))}
                    <th>Total</th>
                  </tr>
                </thead>
                <tbody>
                  {SEXUAL_ORIENTATIONS.map((val, index5) => (
                    <tr key={`workflow-table-${index5}`} className={index5 % 2 ? '' : 'analytics-zebra-bg'}>
                      <td className="font-weight-bold"> {val} </td>
                      {this.soData[Number(index5)].map((data, subIndex5) => (
                        <td key={subIndex5}> {data} </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Col>
      </Row>
    </Card.Body>
  );

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <div className="analytics-card-header font-weight-bold h5"> Demographics (Active Records Only) ​ ​</div>
          {this.props.showGraphs ? this.renderBarGraphs() : this.renderTables()}
        </Card>
      </React.Fragment>
    );
  }
}

Demographics.propTypes = {
  stats: PropTypes.object,
  available_workflows: PropTypes.array,
  showGraphs: PropTypes.bool,
};

export default Demographics;
