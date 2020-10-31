import React from 'react';
import { PropTypes } from 'prop-types';
import { Card } from 'react-bootstrap';

import Patient from './Patient';

class PatientPage extends React.Component {
  constructor(props) {
    super(props);
    this.state = { showAddAssessment: false, hideBody: props.hideBody };
  }

  reloadHook = () => {
    // Optional reload, specifically for assessments
    location.href = '/patients/' + this.props.patient.id;
  };

  render() {
    return (
      <React.Fragment>
        <Card className="mx-2 card-square">
          <Card.Header
            as="h5"
            id="patient-info-header"
            onClick={() => {
              this.setState({ hideBody: !this.state.hideBody });
            }}>
            Monitoree Details {this.props.patient.user_defined_id ? `(ID: ${this.props.patient.user_defined_id})` : ''}{' '}
            {this.props.patient.id && <a href={window.BASE_PATH + '/patients/' + this.props.patient.id + '/edit'}>(edit details)</a>}
            <span className="float-right collapse-hover">
              <i className="fas fa-bars"></i>
            </span>
          </Card.Header>
          <Card.Body>
            <Patient
              details={{ ...this.props.patient }}
              jurisdiction_path={this.props.jurisdiction_path}
              dependents={this.props.dependents || []}
              hideBody={this.state.hideBody}
              authenticity_token={this.props.authenticity_token}
            />
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

PatientPage.propTypes = {
  patient_id: PropTypes.string,
  current_user: PropTypes.object,
  patient: PropTypes.object,
  dependents: PropTypes.array,
  dashboardUrl: PropTypes.string,
  authenticity_token: PropTypes.string,
  patient_submission_token: PropTypes.string,
  canAddAssessments: PropTypes.bool,
  hideBody: PropTypes.bool,
  jurisdiction_path: PropTypes.string,
};

export default PatientPage;
