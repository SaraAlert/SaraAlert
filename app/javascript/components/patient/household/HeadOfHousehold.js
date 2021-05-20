import React from 'react';
import { PropTypes } from 'prop-types';
import { Row } from 'react-bootstrap';
import ChangeHoH from './actions/ChangeHoH';
import HouseholdMemberTable from './HouseholdMemberTable';
import EnrollHouseholdMember from './actions/EnrollHouseholdMember';

class HeadOfHousehold extends React.Component {
  render() {
    return (
      <div id="head-of-household">
        <Row>
          <div className="pb-2">This monitoree is responsible for handling the reporting of the following other monitorees:</div>
          <HouseholdMemberTable
            household_members={this.props.other_household_members}
            current_user={this.props.current_user}
            jurisdiction_paths={this.props.jurisdiction_paths}
            isSelectable={false}
            workflow={this.props.workflow}
            continuous_exposure_enabled={this.props.continuous_exposure_enabled}
          />
        </Row>
        <Row>
          <ChangeHoH patient={this.props.patient} dependents={this.props.other_household_members} authenticity_token={this.props.authenticity_token} />
          {this.props.can_add_group && <EnrollHouseholdMember responderId={this.props.patient.id} isHoh={true} workflow={this.props.workflow} />}
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
  workflow: PropTypes.string,
  continuous_exposure_enabled: PropTypes.bool,
};

export default HeadOfHousehold;
