import React from 'react';
import { PropTypes } from 'prop-types';
import { Row, Col } from 'react-bootstrap';

import SystemStatistics from './widgets/SystemStatistics';
import YourStatistics from './widgets/YourStatistics';

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
            <Col md="12">
              <SystemStatistics stats={this.props.stats} />
            </Col>
            <Col md="12">
              <YourStatistics stats={this.props.stats} />
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
