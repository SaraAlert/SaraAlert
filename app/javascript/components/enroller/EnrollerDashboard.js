import React from 'react';
import { PropTypes } from 'prop-types';
import { Button } from 'react-bootstrap';
import PatientsTable from '../patient/PatientsTable';

class EnrollerDashboard extends React.Component {
  render() {
    return (
      <React.Fragment>
        <h1 className="sr-only">Enrolled Monitorees</h1>
        <Button variant="primary" className="ml-2 mb-3" href={`${window.BASE_PATH}/patients/new`}>
          <span>
            <i className="fas fa-user-plus"></i> Enroll New Monitoree
          </span>
        </Button>
        <PatientsTable
          enroller={true}
          authenticity_token={this.props.authenticity_token}
          jurisdiction_paths={this.props.jurisdiction_paths}
          all_assigned_users={this.props.all_assigned_users}
          jurisdiction={this.props.jurisdiction}
        />
      </React.Fragment>
    );
  }
}

EnrollerDashboard.propTypes = {
  authenticity_token: PropTypes.string,
  jurisdiction: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  all_assigned_users: PropTypes.array,
};

export default EnrollerDashboard;
