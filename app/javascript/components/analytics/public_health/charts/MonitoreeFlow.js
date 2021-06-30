import React from 'react';
import { PropTypes } from 'prop-types';
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
      <Col xl="12" key={index}>
        <div className="analytics-table-header">{WORKFLOWS[Number(index)]} Workflow</div>
        <table className="analytics-table">
          <thead>
            <tr className="g-border-bottom text-center header">
              <th></th>
              <th>Last 24h</th>
              <th>Last 7d</th>
              <th>Last 14d</th>
              <th>Cumulative</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td className="header" colSpan="5">
                Incoming
              </td>
            </tr>
            <tr>
              <td className="sub-header indent">New Enrollments</td>
              {data.map((x, i) => (
                <td key={i}>
                  <div className="count-percent-container">
                    <span className="number">{x.new_enrollments.value}</span>
                    <span className="percentage align-bottom">({x.new_enrollments.percentage})</span>
                  </div>
                </td>
              ))}
            </tr>
            <tr className="g-border-bottom">
              <td className="sub-header indent">Transferred In</td>
              {data.map((x, i) => (
                <td key={i}>
                  <div className="count-percent-container">
                    <span className="number">{x.transferred_in.value}</span>
                    <span className="percentage">({x.transferred_in.percentage})</span>
                  </div>
                </td>
              ))}
            </tr>
            <tr>
              <td className="header" colSpan="5">
                Outgoing
              </td>
            </tr>
            <tr>
              <td className="sub-header indent">Closed</td>
              {data.map((x, i) => (
                <td key={i}>
                  <div className="count-percent-container">
                    <span className="number">{x.closed.value}</span>
                    <span className="percentage">({x.closed.percentage})</span>
                  </div>
                </td>
              ))}
            </tr>
            <tr className="g-border-bottom">
              <td className="sub-header indent">Transferred Out</td>
              {data.map((x, i) => (
                <td key={i}>
                  <div className="count-percent-container">
                    <span className="number">{x.transferred_out.value}</span>
                    <span className="percentage">({x.transferred_out.percentage})</span>
                  </div>
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
          <div className="text-center text-secondary info-text my-1">
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
