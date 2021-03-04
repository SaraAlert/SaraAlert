import React from 'react';
import { PropTypes } from 'prop-types';
import { Button } from 'react-bootstrap';

class AddHouseholdMember extends React.Component {
  render() {
    return (
      <React.Fragment>
        <Button href={window.BASE_PATH + '/patients/' + this.props.responderId + '/group'} size="sm" className="my-2">
          <i className="fas fa-plus"></i> Add New Household Member
        </Button>
      </React.Fragment>
    );
  }
}

AddHouseholdMember.propTypes = {
  responderId: PropTypes.number,
};

export default AddHouseholdMember;
