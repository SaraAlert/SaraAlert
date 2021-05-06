import React from 'react';
import { PropTypes } from 'prop-types';
import { Row } from 'react-bootstrap';
import RemoveFromHousehold from './actions/RemoveFromHousehold';
import { formatName } from '../../../utils/Patient';

class Dependent extends React.Component {
  render() {
    return (
      <div id="household-member-not-hoh">
        <Row>
          The reporting responsibility for this monitoree is handled by&nbsp;
          <a id="dependent-hoh-link" href={`${window.BASE_PATH}/patients/${this.props.patient.responder_id}`}>
            {this.props.hoh ? formatName(this.props.hoh) : 'this monitoree'}
          </a>
          .
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
  hoh: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default Dependent;
