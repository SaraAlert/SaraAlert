import React from 'react';
import { PropTypes } from 'prop-types';
import { Row, Col, Card } from 'react-bootstrap';

class SystemStatistics extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square">
          <Card.Header className="h5">System Statistics</Card.Header>
          <Card.Body>
            <Row className="mx-4 mt-3 g-border-bottom-2">
              <Col>
                <Row>
                  <div className="h5">TOTAL SUBJECTS</div>
                </Row>
                <Row>
                  <div className="display-1 h1">{this.props.stats.system_subjects}</div>
                </Row>
              </Col>
              <Col>
                <Row>
                  <div className="h5">NEW LAST 24 HOURS</div>
                </Row>
                <Row>
                  <div className="display-1 h1">{this.props.stats.system_subjects_last_24}</div>
                </Row>
              </Col>
            </Row>
            <Row className="mx-4 mt-4">
              <Col>
                <Row>
                  <div className="h5">TOTAL REPORTS</div>
                </Row>
                <Row>
                  <div className="display-1 h1">{this.props.stats.system_assessments}</div>
                </Row>
              </Col>
              <Col>
                <Row>
                  <div className="h5">NEW LAST 24 HOURS</div>
                </Row>
                <Row>
                  <div className="display-1 h1">{this.props.stats.system_assessments_last_24}</div>
                </Row>
              </Col>
            </Row>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

SystemStatistics.propTypes = {
  stats: PropTypes.object,
};

export default SystemStatistics;
