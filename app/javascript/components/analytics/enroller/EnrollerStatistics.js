import React from 'react';
import { PropTypes } from 'prop-types';
import { Row, Col, Card } from 'react-bootstrap';

class EnrollerStatistics extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <Card>
        <Card.Header as="h4" className="text-center">{this.props.title}</Card.Header>
        <Card.Body>
          <Row id="monitoree-analytics" className="g-border-bottom-2 mt-4">
            <Col className="my-3">
              <h4>TOTAL MONITOREES</h4>
              <h3 className="display-3"> {this.props.total_monitorees}</h3>
            </Col>
            <Col className="my-3">
              <h4>NEW LAST 24 HOURS</h4>
              <h3 className="display-3">{this.props.new_monitorees}</h3>
            </Col>
          </Row>
          <Row id="report-analytics" className="mt-4">
            <Col>
              <h4>TOTAL REPORTS</h4>
              <h3 className="display-3">{this.props.total_reports}</h3>
            </Col>
            <Col>
              <h4>NEW LAST 24 HOURS</h4>
              <h3 className="display-3">{this.props.new_reports}</h3>
            </Col>
          </Row>
        </Card.Body>
      </Card>
    );
  }
}

EnrollerStatistics.propTypes = {
  title: PropTypes.string,
  total_monitorees: PropTypes.number,
  new_monitorees: PropTypes.number,
  total_reports: PropTypes.number,
  new_reports: PropTypes.number,
};

export default EnrollerStatistics;
