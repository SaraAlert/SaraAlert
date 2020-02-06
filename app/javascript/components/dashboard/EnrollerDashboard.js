import React from "react";
import { Button, Row, Col, Card } from 'react-bootstrap';
import BreadcrumbPath from '../BreadcrumbPath';
import SystemStatistics from './widgets/SystemStatistics';
import YourStatistics from './widgets/YourStatistics';
import { PropTypes } from 'prop-types';

class EnrollerDashboard extends React.Component {

  constructor(props) {
    super(props);
  }

  render () {
    return (
      <React.Fragment>
        <BreadcrumbPath crumbs={[new Object({ value: "Dashboard", href: null })]} />
        <div className="mx-2">
          <Button variant="primary" size="lg" className="py-2 btn-square px-4" onClick={() => {window.location.href = '/patients/new'}}>Register New Subject</Button>
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
  stats: PropTypes.object
};

export default EnrollerDashboard
