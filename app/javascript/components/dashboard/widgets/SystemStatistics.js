import React from "react"
import { Row, Col, Card } from 'react-bootstrap';

class SystemStatistics extends React.Component {

  constructor(props) {
    super(props);
  }

  render () {
    return (
      <React.Fragment>
        <Card className="card-square">
          <Card.Header as="h5">System Statistics</Card.Header>
          <Card.Body>
            <Row className="mx-4 mt-3 g-border-bottom-2">
              <Col>
                <Row>
                  <h5>TOTAL SUBJECTS</h5>
                </Row>
                <Row>
                  <h1 className="display-1">{this.props.stats.system_subjects}</h1>
                </Row>
              </Col>
              <Col>
                <Row>
                  <h5>NEW LAST 24 HOURS</h5>
                </Row>
                <Row>
                  <h1 className="display-1">{this.props.stats.system_subjects_last_24}</h1>
                </Row>
              </Col>
            </Row>
            <Row className="mx-4 mt-4">
              <Col>
                <Row>
                  <h5>TOTAL ASSESSMENTS</h5>
                </Row>
                <Row>
                  <h1 className="display-1">{this.props.stats.system_assessmets}</h1>
                </Row>
              </Col>
              <Col>
                <Row>
                  <h5>NEW LAST 24 HOURS</h5>
                </Row>
                <Row>
                  <h1 className="display-1">{this.props.stats.system_assessmets_last_24}</h1>
                </Row>
              </Col>
            </Row>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

export default SystemStatistics