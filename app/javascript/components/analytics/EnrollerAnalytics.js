import React from 'react';
import { PropTypes } from 'prop-types';
import { Row, Col } from 'react-bootstrap';

import EnrollerStatistics from './widgets/EnrollerStatistics';

class EnrollerAnalytics extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <React.Fragment>
        <h1 className="sr-only">Analytics</h1>
        <div className="mx-2">
          <Row className="pt-4">
            <Col lg="12">
              <EnrollerStatistics
                title="System Statistics"
                total_monitorees={this.props.stats.system_subjects}
                new_monitorees={this.props.stats.system_subjects_last_24}
                total_reports={this.props.stats.system_assessments}
                new_reports={this.props.stats.system_assessments_last_24}
              />
            </Col>
            <Col lg="12" className="my-4 my-lg-0">
              <EnrollerStatistics
                title="Your Statistics"
                total_monitorees={this.props.stats.user_subjects}
                new_monitorees={this.props.stats.user_subjects_last_24}
                total_reports={this.props.stats.user_assessments}
                new_reports={this.props.stats.user_assessments_last_24}
              />
            </Col>
          </Row>
        </div>
      </React.Fragment>
    );
  }
}

EnrollerAnalytics.propTypes = {
  current_user: PropTypes.object,
  stats: PropTypes.object,
};

export default EnrollerAnalytics;
