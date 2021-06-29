import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card, Col, Row } from 'react-bootstrap';
import _ from 'lodash';
import BarGraph from '../../display/BarGraph';
import ExposureIsolationTable from '../../display/ExposureIsolationTable';
import { mapToChartFormat, parseOutFields } from '../../../../utils/Analytics';

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
    this.barGraphData = [
      { title: 'Risk Factors', data: mapToChartFormat(RISKFACTORS, this.rfData) },
      { title: 'Country of Exposure', data: mapToChartFormat(this.COUNTRY_HEADERS, this.countryData) },
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
      {this.barGraphData.map((graph, i) => (
        <Col xl="12" key={i}>
          <BarGraph title={graph.title} data={graph.data} />
        </Col>
      ))}
    </Row>
  );

  renderTables = () => {
    return (
      <Row>
        <Col lg="12">
          <ExposureIsolationTable title={'Risk Factors'} rowHeaders={RISKFACTORS} data={this.rfData} />
        </Col>
        <Col lg="12">
          <ExposureIsolationTable title={'Country of Exposure'} rowHeaders={this.COUNTRY_HEADERS} data={this.countryData} />
          <Button variant="primary" className="float-right" onClick={this.exportFullCountryData}>
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
        <Card.Header as="h4" className="text-center">
          Exposure Summary (Active Records Only)
        </Card.Header>
        <Card.Body>{this.props.showGraphs ? this.renderBarGraphs() : this.renderTables()}</Card.Body>
      </Card>
    );
  }
}

ExposureSummary.propTypes = {
  stats: PropTypes.object,
  showGraphs: PropTypes.bool,
};

export default ExposureSummary;
