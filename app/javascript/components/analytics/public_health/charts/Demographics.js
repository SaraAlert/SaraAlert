import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Col, Row } from 'react-bootstrap';
import _ from 'lodash';
import WorkflowChart from '../../display/WorkflowChart';
import WorkflowTable from '../../display/WorkflowTable';
import { mapToChartFormat, parseOutFields } from '../../../../utils/Analytics';

const AGEGROUPS = ['0-19', '20-29', '30-39', '40-49', '50-59', '60-69', '70-79', '80-89', '90-99', '100-109', '≥ 110', 'Missing'];
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

    // If the sum here is 0, means the jurisdiction doesnt track SO
    this.showSexualOrientationData = !!_.sum(this.soData.map(x => _.last(x)));

    // Map and translate all of the Tabular Data to the Chart Format
    this.barGraphData = [
      { title: 'Current Age (Years)', data: mapToChartFormat(_.initial(AGEGROUPS), this.ageData), show: true, tooltipKey: 'analyticsAgeTip' },
      { title: 'Sex', data: mapToChartFormat(SEXES, this.sexData), show: true },
      { title: 'Ethnicity', data: mapToChartFormat(ETHNICITIES, this.ethnicityData), show: true },
      { title: 'Race', data: mapToChartFormat(RACES, this.raceData), show: true },
      { title: 'Sexual Orientation', data: mapToChartFormat(SEXUAL_ORIENTATIONS, this.soData), show: this.showSexualOrientationData },
    ];
  }

  renderBarGraphs = () => (
    <Row>
      {this.barGraphData.map((graph, i) => (
        <React.Fragment key={i}>
          {graph.show && (
            <Col xl="12">
              <WorkflowChart title={graph.title} tooltipKey={graph.tooltipKey} data={graph.data} />
            </Col>
          )}
        </React.Fragment>
      ))}
    </Row>
  );

  renderTables = () => (
    <Row>
      <Col lg="12">
        <WorkflowTable title={'Current Age (Years)'} rowHeaders={AGEGROUPS} data={this.ageData} tooltipKey={'analyticsAgeTip'} />
        <WorkflowTable title={'Sex'} rowHeaders={SEXES} data={this.sexData} />
      </Col>
      <Col lg="12">
        <WorkflowTable title={'Ethnicity'} rowHeaders={ETHNICITIES} data={this.ethnicityData} />
        <WorkflowTable title={'Race'} rowHeaders={RACES} data={this.raceData} />
        {this.showSexualOrientationData && <WorkflowTable title={'Sexual Orientation'} rowHeaders={SEXUAL_ORIENTATIONS} data={this.soData} />}
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
