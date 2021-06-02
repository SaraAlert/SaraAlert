import React from 'react';
import { PropTypes } from 'prop-types';
import { Modal } from 'react-bootstrap';

import FollowUpFlag from './FollowUpFlag';

class FollowUpFlagModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      initial_follow_up_reason: '',
    };
  }

  componentDidMount() {
    if (this.props.patient.follow_up_reason) {
      this.setState({ initial_follow_up_reason: this.props.patient.follow_up_reason });
    }
  }

  render() {
    return (
      <Modal id="follow-up-flag-modal" size="lg" centered show={this.props.show} onHide={this.props.close}>
        <Modal.Header closeButton>
          <Modal.Title>
            {!this.props.bulk_action && this.state.initial_follow_up_reason !== '' && !this.props.clear_flag && 'Update '}
            {!this.props.bulk_action && this.props.clear_flag && 'Clear '}
            Flag for Follow-Up
          </Modal.Title>
        </Modal.Header>
        <FollowUpFlag
          patient={this.props.patient}
          current_user={this.props.current_user}
          jurisdiction_paths={this.props.jurisdiction_paths}
          authenticity_token={this.props.authenticity_token}
          other_household_members={this.props.other_household_members}
          close={this.props.close}
          bulk_action={this.props.bulk_action}
          clear_flag={this.props.clear_flag}
        />
      </Modal>
    );
  }
}

FollowUpFlagModal.propTypes = {
  show: PropTypes.bool,
  patient: PropTypes.object,
  patients: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  authenticity_token: PropTypes.string,
  other_household_members: PropTypes.array,
  close: PropTypes.func,
  bulk_action: PropTypes.bool,
  clear_flag: PropTypes.bool,
};

export default FollowUpFlagModal;
