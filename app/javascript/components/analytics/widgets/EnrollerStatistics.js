import React from 'react';
import { PropTypes } from 'prop-types';
import { Row, Col, Card } from 'react-bootstrap';

class EnrollerStatistics extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <div className="analytics-card-header font-weight-bold h5">{this.props.title}</div>
          <Card.Body className="mt-4">
            <Row id="monitoreeAnalytics" className="mx-4 mt-3 g-border-bottom-2">
              <Col>
                <Row>
                  <div className="h4">TOTAL MONITOREES</div>
                </Row>
                <Row>
                  <div className="display-3 h3">{this.props.total_monitorees}</div>
                </Row>
              </Col>
              <Col>
                <Row>
                  <div className="h4">NEW LAST 24 HOURS</div>
                </Row>
                <Row>
                  <div className="display-3 h3">{this.props.new_monitorees}</div>
                </Row>
              </Col>
            </Row>
            <Row id="reportAnalytics" className="mx-4 mt-4">
              <Col>
                <Row>
                  <div className="h4">TOTAL REPORTS</div>
                </Row>
                <Row>
                  <div className="display-3 h3">{this.props.total_reports}</div>
                </Row>
              </Col>
              <Col>
                <Row>
                  <div className="h4">NEW LAST 24 HOURS</div>
                </Row>
                <Row>
                  <div className="display-3 h3">{this.props.new_reports}</div>
                </Row>
              </Col>
            </Row>
          </Card.Body>
        </Card>
      </React.Fragment>
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
