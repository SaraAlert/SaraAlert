import React from 'react';
import { PropTypes } from 'prop-types';
import { Row, Col, Card } from 'react-bootstrap';

class YourStatistics extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square">
          <Card.Header className="h5">Your Statistics</Card.Header>
          <Card.Body>
            <Row className="mx-4 mt-3 g-border-bottom-2">
              <Col>
                <Row>
                  <div className="h5">TOTAL MONITOREES</div>
                </Row>
                <Row>
                  <div className="display-1">{this.props.stats.user_subjects}</div>
                </Row>
              </Col>
              <Col>
                <Row>
                  <div className="h5">NEW LAST 24 HOURS</div>
                </Row>
                <Row>
                  <div className="display-1">{this.props.stats.user_subjects_last_24}</div>
                </Row>
              </Col>
            </Row>
            <Row className="mx-4 mt-4">
              <Col>
                <Row>
                  <div className="h5">TOTAL REPORTS</div>
                </Row>
                <Row>
                  <div className="display-1">{this.props.stats.user_assessments}</div>
                </Row>
              </Col>
              <Col>
                <Row>
                  <div className="h5">NEW LAST 24 HOURS</div>
                </Row>
                <Row>
                  <div className="display-1">{this.props.stats.user_assessments_last_24}</div>
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
