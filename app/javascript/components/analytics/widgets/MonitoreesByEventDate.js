import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Form, Col, Row } from 'react-bootstrap';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip } from 'recharts';
import _ from 'lodash';

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

  parseOutFields = (masterList, categoryTypeName) =>
    masterList
      .map(ml =>
        WORKFLOWS.map(
          wf => this.props.stats.monitoree_counts.find(x => x.status === wf && x.category_type === categoryTypeName && x.category === ml)?.total || 0
        )
      )
      .map(x => x.concat(_.sum(x)));

  // This instance of mapToChartFormat is slightly different from its neighbor components due to this unique use case
  mapToChartFormat = (masterList, values, workflow) =>
    masterList.map((ml, index0) => {
      let retVal = {};
      retVal['name'] = ml;
      retVal[`${workflow}`] = values[Number(index0)][WORKFLOWS.findIndex(x => x === workflow)];
      return retVal;
    });

  setTimeResolution(timeRes) {
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
    this.setState({
      graphData: WORKFLOWS.map(workflow => this.mapToChartFormat(DATES_OF_INTEREST, this.parseOutFields(DATES_OF_INTEREST, dateRangeInQuestion), workflow)),
    });
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <div className="analytics-card-header font-weight-bold h5"> Monitorees by Event Date ​(Active Records Only) ​</div>
          <Card.Body className="mt-4">
            <Form.Row className="justify-content-md-center">
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
      </React.Fragment>
    );
  }
}

MonitoreesByEventDate.propTypes = {
  stats: PropTypes.object,
};

export default MonitoreesByEventDate;
