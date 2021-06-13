import React from 'react';
import { PropTypes } from 'prop-types';
import { Row } from 'react-bootstrap';
import HouseholdMemberTable from './utils/HouseholdMemberTable';
import RemoveFromHousehold from './actions/RemoveFromHousehold';

class Dependent extends React.Component {
  render() {
    return (
      <div id="household-member-not-hoh">
        <Row>
          <div className="pb-2">
            This monitoree is a member of the following Household where the reporting responsibility is handled by the designated Head of Household:
          </div>
          <HouseholdMemberTable
            household_members={this.props.other_household_members}
            current_user={this.props.current_user}
            jurisdiction_paths={this.props.jurisdiction_paths}
            isSelectable={false}
            workflow={this.props.workflow}
          />
        </Row>
        <Row>
          <RemoveFromHousehold patient={this.props.patient} authenticity_token={this.props.authenticity_token} />
        </Row>
      </div>
    );
  }
}

Dependent.propTypes = {
  patient: PropTypes.object,
  other_household_members: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  authenticity_token: PropTypes.string,
  workflow: PropTypes.string,
};

export default Dependent;
