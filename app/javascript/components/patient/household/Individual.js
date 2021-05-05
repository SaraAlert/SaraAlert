import React from 'react';
import { PropTypes } from 'prop-types';
import { Row } from 'react-bootstrap';
import EnrollHouseholdMember from './actions/EnrollHouseholdMember';
import MoveToHousehold from './actions/MoveToHousehold';

class Individual extends React.Component {
  render() {
    return (
      <div id="no-household">
        <Row>This monitoree is not a member of a household.</Row>
        <Row>
          <MoveToHousehold patient={this.props.patient} authenticity_token={this.props.authenticity_token} />
          {this.props.can_add_group && <EnrollHouseholdMember responderId={this.props.patient.id} isHoh={false} />}
        </Row>
      </div>
    );
  }
}

Individual.propTypes = {
  can_add_group: PropTypes.bool,
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default Individual;
