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
      <Card id="patient-page" className="mx-2 my-4 card-square">
        <Card.Header as="h1" className="patient-card-header" id="patient-info-header">
          Monitoree Details {this.props.patient.user_defined_id ? `(ID: ${this.props.patient.user_defined_id})` : ''}{' '}
        </Card.Header>
        <Card.Body>
          <Patient
            current_user={this.props.current_user}
            jurisdiction_paths={this.props.jurisdiction_paths}
            details={{ ...this.props.patient, blocked_sms: this.props.blocked_sms }}
            hoh={this.props.other_household_members.find(patient => patient.head_of_household)}
            collapse={this.props.can_modify_subject_status}
            edit_mode={false}
            other_household_members={this.props.other_household_members}
            can_modify_subject_status={this.props.can_modify_subject_status}
            authenticity_token={this.props.authenticity_token}
            workflow={this.props.workflow}
            headingLevel={2}
          />
          <div className="household-info">
            {!this.props.patient.head_of_household && this.props?.other_household_members?.length > 0 && (
              <Dependent
                patient={this.props.patient}
                other_household_members={this.props.other_household_members}
                current_user={this.props.current_user}
                jurisdiction_paths={this.props.jurisdiction_paths}
                authenticity_token={this.props.authenticity_token}
                workflow={this.props.workflow}
              />
            )}
            {this.props.patient.head_of_household && (
              <HeadOfHousehold
                patient={this.props.patient}
                other_household_members={this.props.other_household_members}
                can_add_group={this.props.can_add_group}
                current_user={this.props.current_user}
                jurisdiction_paths={this.props.jurisdiction_paths}
                authenticity_token={this.props.authenticity_token}
                workflow={this.props.workflow}
                continuous_exposure_enabled={this.props.continuous_exposure_enabled}
              />
            )}
            {!this.props.patient.head_of_household && this.props?.other_household_members?.length === 0 && (
              <Individual
                patient={this.props.patient}
                can_add_group={this.props.can_add_group}
                authenticity_token={this.props.authenticity_token}
                workflow={this.props.workflow}
              />
            )}
          </div>
        </Card.Body>
      </Card>
    );
  }
}

PatientPage.propTypes = {
  current_user: PropTypes.object,
  can_add_group: PropTypes.bool,
  can_modify_subject_status: PropTypes.bool,
  patient: PropTypes.object,
  other_household_members: PropTypes.array,
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  blocked_sms: PropTypes.bool,
  workflow: PropTypes.string,
  continuous_exposure_enabled: PropTypes.bool,
};

export default PatientPage;
