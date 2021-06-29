import React from 'react';
import { PropTypes } from 'prop-types';
import _ from 'lodash';
import { Card, Col, Row } from 'react-bootstrap';
import { formatPercentage } from '../../../../utils/Analytics';

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
        let inTotal = thisTimeFrameData?.new_enrollments + thisTimeFrameData?.transferred_in;
        let outTotal = thisTimeFrameData?.closed + thisTimeFrameData?.transferred_out;
        return {
          time_frame,
          new_enrollments: {
            value: thisTimeFrameData?.new_enrollments || 0,
            percentage: formatPercentage(thisTimeFrameData?.new_enrollments, inTotal),
          },
          transferred_in: {
            value: thisTimeFrameData?.transferred_in || 0,
            percentage: formatPercentage(thisTimeFrameData?.transferred_in, inTotal),
          },
          closed: {
            value: thisTimeFrameData?.closed || 0,
            percentage: formatPercentage(thisTimeFrameData?.closed, outTotal),
          },
          transferred_out: {
            value: thisTimeFrameData?.transferred_out || 0,
            percentage: formatPercentage(thisTimeFrameData?.transferred_out, outTotal),
          },
        };
      });
    });
  }

  renderWorkflowTable(data, index) {
    return (
      <Col lg="12" key={index} className="pb-3">
        <table className="analytics-table">
          <thead>
            <tr>
              <th className="py-0"></th>
              {MONITOREE_FLOW_HEADERS.map((monitoreeFlowHeader, index) => (
                <th key={index}>
                  <div> {monitoreeFlowHeader} </div>
                  <div className="text-secondary"> n (col %) </div>
                </th>
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
                <td key={index}>
                  <div>{x.new_enrollments.value}</div>
                  <span className="analytics-percentage"> {`(${x.new_enrollments.percentage})`}</span>
                </td>
              ))}
            </tr>
            <tr>
              <td className="text-right">TRANSFERRED IN</td>
              {data.map((x, index) => (
                <td key={index}>
                  <div>{x.transferred_in.value}</div>
                  <span className="analytics-percentage"> {`(${x.transferred_in.percentage})`}</span>
                </td>
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
                <td key={index}>
                  <div>{x.closed.value}</div>
                  <span className="analytics-percentage"> {`(${x.closed.percentage})`}</span>
                </td>
              ))}
            </tr>
            <tr>
              <td className="text-right">TRANSFERRED OUT</td>
              {data.map((x, index) => (
                <td key={index}>
                  <div>{x.transferred_out.value}</div>
                  <span className="analytics-percentage"> {`(${x.transferred_out.percentage})`}</span>
                </td>
              ))}
            </tr>
          </tbody>
        </table>
      </Col>
    );
  }

  render() {
    return (
      <Card>
        <Card.Header as="h4" className="text-center">
          Monitoree Flow Over Time (All Records)
        </Card.Header>
        <Card.Body>
          <Row>{this.tableData.map((data, index) => this.renderWorkflowTable(data, index))}</Row>
          <div className="text-secondary fake-demographic-text mb-1">
            <i className="fas fa-info-circle mr-1"></i>
            Total includes all incoming and outgoing counts ever recorded for this jurisdiction
          </div>
        </Card.Body>
      </Card>
    );
  }
}

MonitoreeFlow.propTypes = {
  stats: PropTypes.object,
};

export default MonitoreeFlow;
