import React from 'react';
import { Card, Collapse } from 'react-bootstrap';
import Patient from './Patient';
import { PropTypes } from 'prop-types';

class PatientPage extends React.Component {
  constructor(props) {
    super(props);
    this.state = { showAddAssessment: false, showBody: true };
    this.reloadHook = this.reloadHook.bind(this);
  }

  reloadHook() {
    // Optional reload, specifically for assessments
    location.href = '/patients/' + this.props.patient.id;
  }

  render() {
    return (
      <React.Fragment>
        <Card className="mx-2 card-square">
          <Card.Header
            as="h5"
            onClick={() => {
              this.setState({ showBody: !this.state.showBody });
            }}>
            Monitoree Details {this.props.patient.user_defined_id ? `(ID: ${this.props.patient.user_defined_id})` : ''}{' '}
            {this.props.patient.id && <a href={'/patients/' + this.props.patient.id + '/edit'}>(edit details)</a>}
          </Card.Header>
          <Collapse in={this.state.showBody}>
            <Card.Body>
              <Patient details={this.props.patient || {}} groupMembers={this.props.group_members || []} />
            </Card.Body>
          </Collapse>
        </Card>
      </React.Fragment>
    );
  }
}

PatientPage.propTypes = {
  patient_id: PropTypes.string,
  current_user: PropTypes.object,
  patient: PropTypes.object,
  group_members: PropTypes.array,
  dashboardUrl: PropTypes.string,
  authenticity_token: PropTypes.string,
  patient_submission_token: PropTypes.string,
  canAddAssessments: PropTypes.bool,
};

export default PatientPage;
