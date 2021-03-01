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
                <h4 className="text-left"> TOTAL MONITOREES </h4>
                <h3 className="display-3 text-left"> {this.props.total_monitorees} </h3>
              </Col>
              <Col>
                <h4 className="text-left"> NEW LAST 24 HOURS </h4>
                <h3 className="display-3 text-left"> {this.props.new_monitorees} </h3>
              </Col>
            </Row>
            <Row id="reportAnalytics" className="mx-4 mt-4">
              <Col>
                <h4 className="text-left"> TOTAL REPORTS </h4>
                <h3 className="display-3 text-left"> {this.props.total_reports} </h3>
              </Col>
              <Col>
                <h4 className="text-left"> NEW LAST 24 HOURS </h4>
                <h3 className="display-3 text-left"> {this.props.new_reports} </h3>
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
