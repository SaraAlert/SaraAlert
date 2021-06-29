import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Col, Row } from 'react-bootstrap';
import _ from 'lodash';
import BarGraph from '../../display/BarGraph';
import InfoTooltip from '../../../util/InfoTooltip';
import { mapToChartFormat, parseOutFields } from '../../../../utils/Analytics';

const WORKFLOWS = ['Exposure', 'Isolation'];
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
    this.ageData = parseOutFields(this.props.stats.monitoree_counts, AGEGROUPS, 'Age Group');
    this.sexData = parseOutFields(this.props.stats.monitoree_counts, SEXES, 'Sex');
    this.ethnicityData = parseOutFields(this.props.stats.monitoree_counts, ETHNICITIES, 'Ethnicity');
    this.raceData = parseOutFields(this.props.stats.monitoree_counts, RACES, 'Race');
    this.soData = parseOutFields(this.props.stats.monitoree_counts, SEXUAL_ORIENTATIONS, 'Sexual Orientation');
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
    this.ageChartData = mapToChartFormat(_.initial(AGEGROUPS), this.ageData);
    this.sexChartData = mapToChartFormat(SEXES, this.sexData);
    this.ethnicityChartData = mapToChartFormat(ETHNICITIES, this.ethnicityData);
    this.raceChartData = mapToChartFormat(RACES, this.raceData);
    this.soChartData = mapToChartFormat(SEXUAL_ORIENTATIONS, this.soData);
    this.barGraphData = [
      { title: 'Current Age (Years)', data: this.ageChartData, tooltipKey: 'analyticsAgeTip' },
      { title: 'Sex', data: this.sexChartData },
      { title: 'Ethnicity', data: this.ethnicityChartData },
      { title: 'Race', data: this.raceChartData },
      { title: 'Sexual Orientation', data: this.soChartData },
    ];
  }

  renderBarGraphs = () => (
    <Row>
      {this.barGraphData.map((graphData, i) => (
        <Col xl="12" key={i}>
          <BarGraph title={graphData.title} tooltipKey={graphData.tooltipKey} data={graphData.data} />
        </Col>
      ))}
    </Row>
  );

  renderTables = () => (
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
  );

  render() {
    return (
      <Card>
        <Card.Header as="h4" className="text-center">
          Demographics (Active Records Only)
        </Card.Header>
        <Card.Body>{this.props.showGraphs ? this.renderBarGraphs() : this.renderTables()}</Card.Body>
      </Card>
    );
  }
}

Demographics.propTypes = {
  stats: PropTypes.object,
  showGraphs: PropTypes.bool,
};

export default Demographics;
