import React from "react"
import { Card } from 'react-bootstrap';
import Patient from './Patient';

class PatientPage extends React.Component {

  constructor(props) {
    super(props);
  }

  render () {
    return (
      <React.Fragment>
        <Card className="mx-4 card-square">
          <Card.Header as="h5">Patient Details</Card.Header>
          <Card.Body>
            <Patient details={this.props.patient || {}} />
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

export default PatientPage