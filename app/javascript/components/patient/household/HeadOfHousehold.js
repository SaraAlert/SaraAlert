import React from 'react';
import { PropTypes } from 'prop-types';
import { Row } from 'react-bootstrap';
import ChangeHoH from './actions/ChangeHoH';
import HouseholdMemberTable from './utils/HouseholdMemberTable';
import EnrollHouseholdMember from './actions/EnrollHouseholdMember';

class HeadOfHousehold extends React.Component {
  render() {
    return (
      <div id="head-of-household">
        <Row>This monitoree is responsible for handling the reporting of the following other monitorees:</Row>
        <Row className="pt-2">
          <HouseholdMemberTable
            household_members={this.props.other_household_members}
            current_user={this.props.current_user}
            jurisdiction_paths={this.props.jurisdiction_paths}
            isSelectable={false}
          />
        </Row>
        <Row>
          <ChangeHoH patient={this.props.patient} dependents={this.props.other_household_members} authenticity_token={this.props.authenticity_token} />
          {this.props.can_add_group && <EnrollHouseholdMember responderId={this.props.patient.id} isHoh={true} />}
        </Row>
      </div>
    );
  }
}

HeadOfHousehold.propTypes = {
  can_add_group: PropTypes.bool,
  patient: PropTypes.object,
  other_household_members: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default HeadOfHousehold;
