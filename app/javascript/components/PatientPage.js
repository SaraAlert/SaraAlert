import React from "react"
import { Card } from 'react-bootstrap';
import Patient from './Patient';
import BreadcrumbPath from './BreadcrumbPath';

class PatientPage extends React.Component {

  constructor(props) {
    super(props);
  }

  render () {
    return (
      <React.Fragment>
        <BreadcrumbPath crumbs={[new Object({ value: "Dashboard", href: this.props.dashboardUrl ? this.props.dashboardUrl : null }), new Object({ value: "Subject View", href: null })]} />
        <Card className="mx-4 card-square">
          <Card.Header as="h5">Subject Details</Card.Header>
          <Card.Body>
            <Patient details={this.props.patient || {}} />
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

export default PatientPage