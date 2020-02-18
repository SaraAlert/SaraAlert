import React from 'react';
import { Row, Col } from 'react-bootstrap';
import SystemStatistics from './widgets/SystemStatistics';
import YourStatistics from './widgets/YourStatistics';
import { PropTypes } from 'prop-types';

class EnrollerDashboard extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <React.Fragment>
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

EnrollerDashboard.propTypes = {
  current_user: PropTypes.object,
  stats: PropTypes.object,
};

export default EnrollerDashboard;
