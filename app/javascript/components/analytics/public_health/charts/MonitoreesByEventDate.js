import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Col, Form, Row } from 'react-bootstrap';
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';

import { formatDate } from '../../../../utils/DateTime';
import { mapToChartFormat, parseOutFields } from '../../../../utils/Analytics';
import _ from 'lodash';

import 'resize-observer-polyfill/dist/ResizeObserver.global';

const WORKFLOWS = ['Exposure', 'Isolation'];
const GRAPH_CONFIGS = [
  { dataKey: 'Exposure', fill: '#557385', legendText: 'Last Date of Exposure' },
  { dataKey: 'Isolation', fill: '#DCC5A7', legendText: 'Symptom Onset Date' },
];
let DATES_OF_INTEREST = []; // If certain dates are desired, they can be specified here

class MonitoreesByEventDate extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      graphData: {},
    };
  }

  componentDidMount() {
    this.setTimeResolution('Day');
  }

  setTimeResolution = timeRes => {
    let dateRangeInQuestion;
    if (timeRes === 'Day') {
      dateRangeInQuestion = 'Last Exposure Date';
    } else if (timeRes === 'Week') {
      dateRangeInQuestion = 'Last Exposure Week';
    } else if (timeRes === 'Month') {
      dateRangeInQuestion = 'Last Exposure Month';
    }
    DATES_OF_INTEREST = _.uniq(
      this.props.stats.monitoree_counts.filter(x => x.category_type === dateRangeInQuestion && x.category).map(x => x.category)
    ).sort();
    let fd = mapToChartFormat(DATES_OF_INTEREST, parseOutFields(this.props.stats.monitoree_counts, DATES_OF_INTEREST, dateRangeInQuestion, WORKFLOWS));
    // The formattedData from this function needs to be slightly split up by workflow for this use-case
    let graphData = WORKFLOWS.map(workflow =>
      fd.map(y => ({
        name: formatDate(y.name),
        [`${workflow}`]: y[`${workflow}`],
      }))
    );
    this.setState({
      graphData,
    });
  };

  render() {
    return (
      <Card>
        <Card.Header as="h4" className="text-center">
          Monitorees by Event Date ​(Active Records Only)
        </Card.Header>
        <Card.Body className="text-center">
          <Form.Row className="justify-content-center">
            <Form.Group as={Col} md="8" onChange={val => this.setTimeResolution(val.target.value)}>
              <Form.Label htmlFor="time-resolution-select">Time Resolution</Form.Label>
              <Form.Control id="time-resolution-select" as="select" size="md">
                <option>Day</option>
                <option>Week</option>
                <option>Month</option>
              </Form.Control>
            </Form.Group>
          </Form.Row>
          <Row className="mx-2 px-0">
            {GRAPH_CONFIGS.map((val, index) => (
              <Col xs="12" key={index}>
                <div className="font-weight-bold h5 ml-5"> {val.dataKey} Workflow </div>
                <ResponsiveContainer width="100%" height={400}>
                  <BarChart width={500} height={300} data={this.state.graphData[Number(index)]} margin={{ top: 0, right: 0, left: 0, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey={val.dataKey} stackId="a" fill={val.fill} />
                  </BarChart>
                </ResponsiveContainer>
                <div className="font-weight-bold h6 ml-5 mb-2"> {val.legendText} </div>
              </Col>
            ))}
          </Row>
        </Card.Body>
      </Card>
    );
  }
}

MonitoreesByEventDate.propTypes = {
  stats: PropTypes.object,
};

export default MonitoreesByEventDate;
