import React from 'react';
import { PropTypes } from 'prop-types';
import { Row } from 'react-bootstrap';
import RemoveFromHousehold from './actions/RemoveFromHousehold';

class Dependent extends React.Component {
  render() {
    return (
      <React.Fragment>
        <Row>
          The reporting responsibility for this monitoree is handled by another monitoree.&nbsp;
          <a href={`${window.BASE_PATH}/patients/${this.props.patient.responder_id}`}>Click here to view that monitoree</a>.
        </Row>
        <Row>
          <RemoveFromHousehold patient={this.props.patient} authenticity_token={this.props.authenticity_token} />
        </Row>
      </React.Fragment>
    );
  }
}

Dependent.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default Dependent;