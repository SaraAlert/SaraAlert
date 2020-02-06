import React from "react";
import { Row, Col } from 'react-bootstrap';
import SystemStatistics from './widgets/SystemStatistics';
import SubjectStatus from './widgets/SubjectStatus';
import ReportingSummary from './widgets/ReportingSummary';
import MonitoringDistributionDay from './widgets/MonitoringDistributionDay';
import AssessmentsDay from './widgets/AssessmentsDay';
import { PropTypes } from 'prop-types';

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
              <Row>
                <Col md="24">
                  <SystemStatistics stats={this.props.stats} />
                </Col>
              </Row>
              <Row className="mt-4">
                <Col md="24">
                  <SubjectStatus stats={this.props.stats} />
                </Col>
              </Row>
              <Row className="mt-4">
                <Col md="24">
                  <AssessmentsDay stats={this.props.stats} />
                </Col>
              </Row>
            </Col>
            <Col md="12">
              <Row>
                <Col md="24">
                  <ReportingSummary stats={this.props.stats} />
                </Col>
              </Row>
              <Row className="mt-4">
                <Col md="24">
                  <MonitoringDistributionDay stats={this.props.stats} />
                </Col>
              </Row>
              <Row className="mt-4">
                <Col md="24">

                </Col>
              </Row>
            </Col>
          </Row>
        </div>
        <div className="pb-2"></div>
      </React.Fragment>
    );
  }
}

MonitorDashboard.propTypes = {
  stats: PropTypes.object
};

export default MonitorDashboard
