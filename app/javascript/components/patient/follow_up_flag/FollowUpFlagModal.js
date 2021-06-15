import React from 'react';
import { PropTypes } from 'prop-types';
import { Modal } from 'react-bootstrap';

import FollowUpFlag from './FollowUpFlag';

class FollowUpFlagModal extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <Modal id="follow-up-flag-modal" size="lg" centered show={this.props.show} onHide={this.props.close}>
        <Modal.Header closeButton>
          <Modal.Title>
            {!this.props.clear_flag && 'Flag for Follow-Up'}
            {this.props.clear_flag && 'Clear Flag'}
          </Modal.Title>
        </Modal.Header>
        <FollowUpFlag
          patients={[this.props.patient]}
          current_user={this.props.current_user}
          jurisdiction_paths={this.props.jurisdiction_paths}
          authenticity_token={this.props.authenticity_token}
          other_household_members={this.props.other_household_members}
          close={this.props.close}
          bulkAction={false}
          clear_flag={this.props.clear_flag}
        />
      </Modal>
    );
  }
}

FollowUpFlagModal.propTypes = {
  show: PropTypes.bool,
  patient: PropTypes.object,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  authenticity_token: PropTypes.string,
  other_household_members: PropTypes.array,
  close: PropTypes.func,
  clear_flag: PropTypes.bool,
};

export default FollowUpFlagModal;
