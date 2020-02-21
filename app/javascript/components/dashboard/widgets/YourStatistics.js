import React from 'react';
import { Row, Col, Card } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class YourStatistics extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square">
          <Card.Header as="h5">Your Statistics</Card.Header>
          <Card.Body>
            <Row className="mx-4 mt-3 g-border-bottom-2">
              <Col>
                <Row>
                  <h5>TOTAL MONITOREES</h5>
                </Row>
                <Row>
                  <h1 className="display-1">{this.props.stats.user_subjects}</h1>
                </Row>
              </Col>
              <Col>
                <Row>
                  <h5>NEW LAST 24 HOURS</h5>
                </Row>
                <Row>
                  <h1 className="display-1">{this.props.stats.user_subjects_last_24}</h1>
                </Row>
              </Col>
            </Row>
            <Row className="mx-4 mt-4">
              <Col>
                <Row>
                  <h5>TOTAL REPORTS</h5>
                </Row>
                <Row>
                  <h1 className="display-1">{this.props.stats.user_assessments}</h1>
                </Row>
              </Col>
              <Col>
                <Row>
                  <h5>NEW LAST 24 HOURS</h5>
                </Row>
                <Row>
                  <h1 className="display-1">{this.props.stats.user_assessments_last_24}</h1>
                </Row>
              </Col>
            </Row>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

YourStatistics.propTypes = {
  stats: PropTypes.object,
};

export default YourStatistics;
