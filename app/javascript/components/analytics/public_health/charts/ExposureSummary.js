import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card, Col, Row } from 'react-bootstrap';
import { Bar, BarChart, CartesianGrid, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import _ from 'lodash';
import CustomizedAxisTick from '../../display/CustomizedAxisTick';
import { mapToChartFormat, parseOutFields } from '../../../../utils/Analytics';

const WORKFLOWS = ['Exposure', 'Isolation'];
const RISKFACTORS = [
  'Close Contact with Known Case',
  'Travel from Affected Country or Area',
  'Was in Healthcare Facility with Known Cases',
  'Healthcare Personnel',
  'Common Exposure Cohort',
  'Crew on Passenger or Cargo Flight',
  'Laboratory Personnel',
];
const NUM_COUNTRIES_TO_SHOW = 5;

class ExposureSummary extends React.Component {
  constructor(props) {
    super(props);

    this.allCountryData = _.uniq(props.stats.monitoree_counts.filter(x => x.category_type === 'Exposure Country').map(x => x.category)).map(country => {
      return {
        country,
        total: _.sum(props.stats.monitoree_counts.filter(x => x.category_type === 'Exposure Country' && x.category === country).map(x => x.total)),
      };
    });
    this.COUNTRY_HEADERS = this.allCountryData.sort((a, b) => b.total - a.total).map(x => x.country);

    this.rfData = parseOutFields(this.props.stats.monitoree_counts, RISKFACTORS, 'Risk Factor');
    this.countryData = parseOutFields(this.props.stats.monitoree_counts, this.COUNTRY_HEADERS, 'Exposure Country');

    this.fullCountryData = _.cloneDeep(this.countryData); // Get the full countryData object for exporting
    this.COUNTRY_HEADERS = this.COUNTRY_HEADERS.slice(0, NUM_COUNTRIES_TO_SHOW); // and trim the headers so it wont display all the countries

    // Map and translate all of the Tabular Data to the Chart Format
    this.rfChartData = mapToChartFormat(RISKFACTORS, this.rfData);
    this.countryChartData = mapToChartFormat(this.COUNTRY_HEADERS, this.countryData);
    this.barGraphData = [
      { title: 'Risk Factors', data: this.rfChartData },
      { title: 'Country of Exposure', data: this.countryChartData },
    ];
  }

  exportFullCountryData = () => {
    let topRow = ['\t', 'Exposure Workflow', 'Isolation Workflow', 'Total'];
    let entryArray = this.fullCountryData.map((x, i) => _.join([this.allCountryData[Number(i)].country, ...x], ','));
    let contentString = _.join(entryArray, '\n');
    let csvContent = _.join([topRow, contentString], '\n');
    const url = window.URL.createObjectURL(new Blob([csvContent]));
    const link = document.createElement('a');
    link.href = url;
    this.csvFileName = `CompleteCountryData.csv`;
    link.setAttribute('download', `${this.csvFileName}`);
    document.body.appendChild(link);
    link.click();
  };

  renderBarGraphs = () => (
    <Row>
      {this.barGraphData.map((graphData, i) => (
        <Col xl="12" key={i}>
          <div className="mx-2 mt-3 analytics-chart-borders">
            <div className="text-center h4">{graphData.title}</div>
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
  );

  renderTables = () => {
    return (
      <Row>
        <Col md="12">
          <div className="text-left mt-3 mb-n1 h4"> Risk Factors </div>
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
            {RISKFACTORS.map((val, index1) => (
              <tbody key={`workflow-table-${index1}`}>
                <tr className={index1 % 2 ? '' : 'analytics-zebra-bg'}>
                  <td className="font-weight-bold"> {val} </td>
                  {this.rfData[Number(index1)].map((data, subIndex1) => (
                    <td key={subIndex1}> {data} </td>
                  ))}
                </tr>
              </tbody>
            ))}
          </table>
        </Col>
        <Col md="12">
          <div className="text-left mt-3 mb-n1 h4"> Country of Exposure </div>
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
            {this.COUNTRY_HEADERS.map((val, index2) => (
              <tbody key={`workflow-table-${index2}`}>
                <tr className={index2 % 2 ? '' : 'analytics-zebra-bg'}>
                  <td className="font-weight-bold"> {val} </td>
                  {this.countryData[Number(index2)].map((data, subIndex2) => (
                    <td key={subIndex2}> {data} </td>
                  ))}
                </tr>
              </tbody>
            ))}
          </table>
          <Button variant="primary" className="float-right mt-3 btn-square" onClick={this.exportFullCountryData}>
            <i className="fas fa-download mr-1"></i>
            Export Complete Country Data
          </Button>
        </Col>
      </Row>
    );
  };

  render() {
    return (
      <Card>
        <Card.Header as="h4" className="text-center">Exposure Summary (Active Records Only)</Card.Header>
        <Card.Body>
          {this.props.showGraphs ? this.renderBarGraphs() : this.renderTables()}
        </Card.Body>
      </Card>
    );
  }
}

ExposureSummary.propTypes = {
  stats: PropTypes.object,
  showGraphs: PropTypes.bool,
};

export default ExposureSummary;
