import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Col, Row } from 'react-bootstrap';
import { formatPercentage } from '../../../../utils/Analytics';

const RELEASE_DATE = '10/5/2021';
const WORKFLOWS = ['Exposure', 'Isolation'];
const MONITOREE_FLOW_HEADERS = ['Last 24 Hours', 'Last 7 Days', 'Last 14 Days', 'Total'];

class MonitoreeFlow extends React.Component {
  constructor(props) {
    super(props);
    this.workflowTableData = WORKFLOWS.map(workflow => {
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

    this.exposureToCaseTableData = MONITOREE_FLOW_HEADERS.map(time_frame => {
      let thisTimeFrameData = props.stats.monitoree_snapshots.find(
        monitoree_snapshot => monitoree_snapshot.status === 'Isolation' && monitoree_snapshot.time_frame === time_frame
      );
      return {
        time_frame,
        exposure_to_isolation_active: {
          value: thisTimeFrameData?.exposure_to_isolation_active || 0,
          percentage: null, // ADD ME
        },
        exposure_to_isolation_not_active: {
          value: thisTimeFrameData?.exposure_to_isolation_not_active || 0,
          percentage: null, // ADD ME
        },
        exposure_to_isolation_closed_in_exposure: {
          value: thisTimeFrameData?.exposure_to_isolation_closed_in_exposure || 0,
          percentage: null, // ADD ME
        },
        exposure_to_isolation_total: {
          value: thisTimeFrameData?.exposure_to_isolation_total || 0,
          percentage: null, // ADD ME
        },
      };
    });

    this.isolationToExposureTableData = MONITOREE_FLOW_HEADERS.map(time_frame => {
      let thisTimeFrameData = props.stats.monitoree_snapshots.find(
        monitoree_snapshot => monitoree_snapshot.status === 'Exposure' && monitoree_snapshot.time_frame === time_frame
      );
      return {
        time_frame,
        isolation_to_exposure_total: {
          value: thisTimeFrameData?.isolation_to_exposure_total || 0,
          percentage: null, // add me
        },
      };
    });
  }

  renderWorkflowTable(data, index) {
    return (
      <Col xl="12" key={index}>
        <div className="analytics-table-header">{WORKFLOWS[Number(index)]} Workflow</div>
        <div className="table-responsive">
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
        </div>
      </Col>
    );
  }

  renderExposureToCaseTable(data) {
    return (
      <Col xl="12">
        <div className="analytics-table-header">Exposure to Case Development</div>
        <div className="table-responsive">
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
                  Moved from Exposure to Isolation Workflow
                </td>
              </tr>
              <tr>
                <td className="sub-header indent">Currently Active</td>
                {data.map((x, i) => (
                  <td key={i}>
                    <div className="count-percent-container">
                      <span className="number">{x.exposure_to_isolation_active.value}</span>
                      <span className="percentage align-bottom">({x.exposure_to_isolation_active.percentage})</span>
                    </div>
                  </td>
                ))}
              </tr>
              <tr className="g-border-bottom">
                <td className="sub-header indent">Closed or Purged</td>
                {data.map((x, i) => (
                  <td key={i}>
                    <div className="count-percent-container">
                      <span className="number">{x.exposure_to_isolation_not_active.value}</span>
                      <span className="percentage">({x.exposure_to_isolation_not_active.percentage})</span>
                    </div>
                  </td>
                ))}
              </tr>
              <tr className="b-border-bottom">
                <td className="header">Cases that were closed in Exposure Workflow</td>
                {data.map((x, i) => (
                  <td key={i}>
                    <div className="count-percent-container">
                      <span className="number">{x.exposure_to_isolation_closed_in_exposure.value}</span>
                      <span className="percentage">({x.exposure_to_isolation_closed_in_exposure.percentage})</span>
                    </div>
                  </td>
                ))}
              </tr>
              <tr className="g-border-bottom">
                <td className="header">Total Contacts that became Cases</td>
                {data.map((x, i) => (
                  <td key={i}>
                    <div className="count-percent-container">
                      <span className="number">{x.exposure_to_isolation_total.value}</span>
                      <span className="percentage"></span>
                    </div>
                  </td>
                ))}
              </tr>
            </tbody>
          </table>
        </div>
      </Col>
    );
  }

  renderIsolationToExposureTable(data) {
    return (
      <Col xl="12">
        <div className="analytics-table-header">Moved from Isolation to Exposure</div>
        <div className="table-responsive">
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
              <tr className="g-border-bottom">
                <td className="header">Moved from Isolation to Exposure Workflow</td>
                {data.map((x, i) => (
                  <td key={i}>
                    <div className="count-percent-container">
                      <span className="number">{x.isolation_to_exposure_total.value}</span>
                      <span className="percentage align-bottom">({x.isolation_to_exposure_total.percentage})</span>
                    </div>
                  </td>
                ))}
              </tr>
            </tbody>
          </table>
        </div>
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
          <Row>{this.workflowTableData.map((data, index) => this.renderWorkflowTable(data, index))}</Row>
          <div className="text-center text-secondary info-text mb-4">
            <i className="fas fa-info-circle mr-1"></i>
            Cumulative includes all incoming and outgoing counts ever recorded for this jurisdiction
          </div>
          <Row>
            {this.renderExposureToCaseTable(this.exposureToCaseTableData)}
            {this.renderIsolationToExposureTable(this.isolationToExposureTableData)}
          </Row>
          <div className="text-center text-secondary info-text mb-1">
            <i className="fas fa-info-circle mr-1"></i>
            Cumulative includes only monitorees that were enrolled in the system after {RELEASE_DATE}
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
