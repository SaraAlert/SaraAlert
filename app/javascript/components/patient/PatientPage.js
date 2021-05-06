import React from 'react';
import { PropTypes } from 'prop-types';
import { Card } from 'react-bootstrap';
import Patient from './Patient';
import Dependent from './household/Dependent';
import HeadOfHousehold from './household/HeadOfHousehold';
import Individual from './household/Individual';

class PatientPage extends React.Component {
  render() {
    return (
      <React.Fragment>
        <Card id="patient-page" className="mx-2 card-square">
          <Card.Header className="h5" id="patient-info-header">
            Monitoree Details {this.props.patient.user_defined_id ? `(ID: ${this.props.patient.user_defined_id})` : ''}{' '}
          </Card.Header>
          <Card.Body>
            <Patient
              jurisdiction_path={this.props.jurisdiction_path}
              details={{ ...this.props.patient, blocked_sms: this.props.blocked_sms }}
              collapse={this.props.can_modify_subject_status}
              edit_mode={false}
              authenticity_token={this.props.authenticity_token}
            />
            <div className="household-info">
              {!this.props.patient.head_of_household && this.props?.other_household_members?.length > 0 && (
                <Dependent
                  patient={this.props.patient}
                  hoh={this.props.other_household_members.find(patient => patient.head_of_household)}
                  authenticity_token={this.props.authenticity_token}
                />
              )}
              {this.props.patient.head_of_household && (
                <HeadOfHousehold
                  patient={this.props.patient}
                  dependents={this.props.other_household_members}
                  can_add_group={this.props.can_add_group}
                  authenticity_token={this.props.authenticity_token}
                />
              )}
              {!this.props.patient.head_of_household && this.props?.other_household_members?.length === 0 && (
                <Individual patient={this.props.patient} can_add_group={this.props.can_add_group} authenticity_token={this.props.authenticity_token} />
              )}
            </div>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

PatientPage.propTypes = {
  can_add_group: PropTypes.bool,
  can_modify_subject_status: PropTypes.bool,
  patient: PropTypes.object,
  other_household_members: PropTypes.array,
  authenticity_token: PropTypes.string,
  jurisdiction_path: PropTypes.string,
  blocked_sms: PropTypes.bool,
};

export default PatientPage;
