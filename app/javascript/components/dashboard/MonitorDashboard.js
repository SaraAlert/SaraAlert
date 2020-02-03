import React from "react";
import { Row, Col } from 'react-bootstrap';
import SystemStatistics from './widgets/SystemStatistics';
import SubjectStatus from './widgets/SubjectStatus';
import ReportingSummary from './widgets/ReportingSummary';
import MonitoringDistributionDay from './widgets/MonitoringDistributionDay';
import MonitoringDistributionState from './widgets/MonitoringDistributionState';

class MonitorDashboard extends React.Component {

  constructor(props) {
    super(props);
  }

  render () {
    return (
      <React.Fragment>
        <div className="mx-2 pb-4">
          <Row>
            <Col md="12">
              <SystemStatistics stats={this.props.stats} />
            </Col>
            <Col md="12">
              <SubjectStatus stats={this.props.stats} />
            </Col>
          </Row>
          <Row className="pt-4">
            <Col md="12">
              <ReportingSummary stats={this.props.stats} />
            </Col>
            <Col md="12">
              <MonitoringDistributionDay stats={this.props.stats} />
            </Col>
          </Row>
          <Row className="pt-4">
            <Col md="12">
              {/* <MonitoringDistributionState stats={this.props.stats} /> */}
            </Col>
            <Col md="12">

            </Col>
          </Row>
        </div>
      </React.Fragment>
    );
  }
}

export default MonitorDashboard
