import React from 'react';
import { PropTypes } from 'prop-types';
import { Button } from 'react-bootstrap';

class EnrollHouseholdMember extends React.Component {
  render() {
    return (
      <React.Fragment>
        <Button href={window.BASE_PATH + '/patients/' + this.props.responderId + '/group'} size="sm" className="my-2">
          <i className="fas fa-user-plus"></i> Enroll Household Member
        </Button>
      </React.Fragment>
    );
  }
}

EnrollHouseholdMember.propTypes = {
  responderId: PropTypes.number,
};

export default EnrollHouseholdMember;
