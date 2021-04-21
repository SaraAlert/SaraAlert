import React from 'react';
import { PropTypes } from 'prop-types';
import { Row } from 'react-bootstrap';
import RemoveFromHousehold from './actions/RemoveFromHousehold';
import { formatName } from '../../../utils/Patient';

class Dependent extends React.Component {
  render() {
    return (
      <React.Fragment>
        <Row>
          The reporting responsibility for this monitoree is handled by&nbsp;
          <a href={`${window.BASE_PATH}/patients/${this.props.hoh.id}`}>{formatName(this.props.hoh)}</a>.
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
  hoh: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default Dependent;
