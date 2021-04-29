import React from 'react';
import { PropTypes } from 'prop-types';
import _ from 'lodash';
import { Card, Col, Row } from 'react-bootstrap';

const WORKFLOWS = ['Exposure', 'Isolation'];

// Provide a separate array, as object-iteration order is not guaranteed in JS
const MONITOREE_FLOW_HEADERS = ['Last 24 Hours', 'Last 7 Days', 'Last 14 Days', 'Total'];

class MonitoreeFlow extends React.Component {
  constructor(props) {
    super(props);
    this.tableData = WORKFLOWS.map(workflow => {
      return MONITOREE_FLOW_HEADERS.map(time_frame => {
        let thisTimeFrameData = props.stats.monitoree_snapshots.find(
          monitoree_snapshot => monitoree_snapshot.status === workflow && monitoree_snapshot.time_frame === time_frame
        );
        return {
          time_frame,
          new_enrollments: thisTimeFrameData?.new_enrollments || 0,
          transferred_in: thisTimeFrameData?.transferred_in || 0,
          closed: thisTimeFrameData?.closed || 0,
          transferred_out: thisTimeFrameData?.transferred_out || 0,
          exposure_to_isolation: thisTimeFrameData?.exposure_to_isolation || 0,
          isolation_to_exposure: thisTimeFrameData?.isolation_to_exposure || 0,
        };
      });
    });
  }

  renderWorkflowTable(data, index) {
    let oppositeWorkflow = _.upperCase(WORKFLOWS[Number(index == 0 ? 1 : 0)]);
    return (
      <Col lg="12" key={index} className="pb-3">
        <table className="analytics-table">
          <thead>
            <tr>
              <th className="py-0"></th>
              {MONITOREE_FLOW_HEADERS.map((monitoreeFlowHeader, index) => (
                <th key={index}>{monitoreeFlowHeader}</th>
              ))}
            </tr>
          </thead>
          <tbody key={index}>
            <tr style={{ height: '25px' }}>
              <td className="font-weight-bold text-left p-0">
                <u>{_.upperCase(WORKFLOWS[Number(index)])} WORKFLOW</u>
              </td>
            </tr>
            <tr style={{ height: '25px' }}>
              <td className="font-weight-bold text-left analytics-mf-subheader align-bottom">
                <u>INCOMING</u>
              </td>
            </tr>
            <tr className="analytics-zebra-bg">
              <td className="text-right">NEW ENROLLMENTS</td>
              {data.map((x, index) => (
                <td key={index}>{x.new_enrollments}</td>
              ))}
            </tr>
            <tr>
              <td className="text-right">TRANSFERRED IN</td>
              {data.map((x, index) => (
                <td key={index}>{x.transferred_in}</td>
              ))}
            </tr>
            <tr className="analytics-zebra-bg">
              <td className="text-right">FROM {oppositeWorkflow} WORKFLOW</td>
              {data.map((x, index) => (
                <td key={index}>{oppositeWorkflow === 'ISOLATION' ? x.isolation_to_exposure : x.exposure_to_isolation}</td>
              ))}
            </tr>
            <tr style={{ height: '25px' }}>
              <td className="font-weight-bold text-left analytics-mf-subheader align-bottom">
                <u>OUTGOING</u>
              </td>
            </tr>
            <tr className="analytics-zebra-bg">
              <td className="text-right">CLOSED</td>
              {data.map((x, index) => (
                <td key={index}>{x.closed}</td>
              ))}
            </tr>
            <tr>
              <td className="text-right">TRANSFERRED OUT</td>
              {data.map((x, index) => (
                <td key={index}>{x.transferred_out}</td>
              ))}
            </tr>
            <tr className="analytics-zebra-bg">
              <td className="text-right">TO {oppositeWorkflow} WORKFLOW</td>
              {data.map((x, index) => (
                <td key={index}>{oppositeWorkflow === 'ISOLATION' ? x.exposure_to_isolation : x.isolation_to_exposure}</td>
              ))}
            </tr>
          </tbody>
        </table>
      </Col>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <div className="analytics-card-header font-weight-bold h5">Monitoree Flow Over Time (All Records)</div>
          <Card.Body className="mt-4">
            <Row>{this.tableData.map((data, index) => this.renderWorkflowTable(data, index))}</Row>
            <div className="text-secondary fake-demographic-text mb-1">
              <i className="fas fa-info-circle mr-1"></i>
              Total includes all incoming and outgoing counts ever recorded for this jurisdiction
            </div>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

MonitoreeFlow.propTypes = {
  stats: PropTypes.object,
};

export default MonitoreeFlow;
