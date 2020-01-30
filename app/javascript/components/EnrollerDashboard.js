import React from "react";
import { Button, Row, Col, Card } from 'react-bootstrap';
import BreadcrumbPath from './BreadcrumbPath';

class EnrollerDashboard extends React.Component {

  constructor(props) {
    super(props);
  }

  render () {
    return (
      <React.Fragment>
        <BreadcrumbPath crumbs={[new Object({ value: "Dashboard", href: null })]} />
        <div className="mx-4">
          <Button variant="primary" size="lg" className="py-2 btn-square px-4" onClick={() => {window.location.href = '/patients/new'}}>Register New Subject</Button>
          <Row className="pt-4">
            <Col md="12">
              <Card className="card-square">
                <Card.Header as="h5">System Statistics</Card.Header>
                <Card.Body>
                  <Row className="mx-4 mt-3">
                    <Col>
                      <Row>
                        <h5>PATIENTS</h5>
                      </Row>
                      <Row>
                        <h1 className="display-1">{this.props.stats.system_subjects}</h1>
                      </Row>
                    </Col>
                    <Col>
                      <Row>
                        <h5>ASSESSMENTS</h5>
                      </Row>
                      <Row>
                        <h1 className="display-1">{this.props.stats.system_assessmets}</h1>
                      </Row>
                    </Col>
                  </Row>
                  <Row className="mx-4 mt-4">
                    <Col>
                      <Row>
                        <h5>PATIENTS LAST 24H</h5>
                      </Row>
                      <Row>
                        <h1 className="display-1">{this.props.stats.system_subjects_last_24}</h1>
                      </Row>
                    </Col>
                    <Col>
                      <Row>
                        <h5>ASSESSMENTS LAST 24H</h5>
                      </Row>
                      <Row>
                        <h1 className="display-1">{this.props.stats.system_assessmets_last_24}</h1>
                      </Row>
                    </Col>
                  </Row>
                </Card.Body>
              </Card>
            </Col>
            <Col md="12">
              <Card className="card-square">
                <Card.Header as="h5">Your Statistics</Card.Header>
                <Card.Body>
                  <Row className="mx-4 mt-3">
                    <Col>
                      <Row>
                        <h5>PATIENTS</h5>
                      </Row>
                      <Row>
                        <h1 className="display-1">{this.props.stats.user_subjects}</h1>
                      </Row>
                    </Col>
                    <Col>
                      <Row>
                        <h5>ASSESSMENTS</h5>
                      </Row>
                      <Row>
                        <h1 className="display-1">{this.props.stats.user_assessments}</h1>
                      </Row>
                    </Col>
                  </Row>
                  <Row className="mx-4 mt-4">
                    <Col>
                      <Row>
                        <h5>PATIENTS LAST 24H</h5>
                      </Row>
                      <Row>
                        <h1 className="display-1">{this.props.stats.user_subjects_last_24}</h1>
                      </Row>
                    </Col>
                    <Col>
                      <Row>
                        <h5>ASSESSMENTS LAST 24H</h5>
                      </Row>
                      <Row>
                        <h1 className="display-1">{this.props.stats.user_assessments_last_24}</h1>
                      </Row>
                    </Col>
                  </Row>
                </Card.Body>
              </Card>
            </Col>
          </Row>
        </div>
      </React.Fragment>
    );
  }
}

export default EnrollerDashboard
