import React from 'react';
import { PropTypes } from 'prop-types';
import { Button } from 'react-bootstrap';

import FollowUpFlagModal from './FollowUpFlagModal';

class FollowUpFlagPanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      show_modal: false,
    };
  }

  render() {
    return (
      <React.Fragment>
        {!this.props.patient.follow_up_reason && (
          <Button
            id="set-follow-up-flag-link"
            size="sm"
            className="my-2 mr-2"
            aria-label="Set Flag for Follow-up"
            onClick={() => this.setState({ show_modal: true })}>
            <span>
              {' '}
              <i className="fas fa-flag pr-1"></i> Flag for Follow-up
            </span>
          </Button>
        )}
        {this.props.patient.follow_up_reason && (
          <React.Fragment>
            <div className="follow-up-flag-box w-100">
              <i className="fas fa-flag"></i>
              <span className="pl-2">
                <b>Flagged for Follow-up</b>
                <div className="edit-link">
                  <Button
                    id="edit-follow-up-flag-link"
                    variant="link"
                    className="py-0"
                    onClick={() => this.setState({ show_modal: true })}
                    aria-label="Edit Flag for Follow-up">
                    <span className="pl-2">Edit Flag</span>
                  </Button>
                </div>
              </span>
              <div className="flag-note">
                <b>{this.props.patient.follow_up_reason}</b>
                {this.props.patient.follow_up_note && this.props.patient.follow_up_note.length < 150 && (
                  <span className="wrap-words">{' - ' + this.props.patient.follow_up_note}</span>
                )}
                {this.props.patient.follow_up_note && this.props.patient.follow_up_note.length >= 150 && (
                  <React.Fragment>
                    <span className="wrap-words">
                      {this.state.expandFollowUpNotes
                        ? ' - ' + this.props.patient.follow_up_note
                        : ' - ' + this.props.patient.follow_up_note.slice(0, 150) + ' ...'}
                    </span>
                    <Button variant="link" className="notes-button p-0" onClick={() => this.setState({ expandFollowUpNotes: !this.state.expandFollowUpNotes })}>
                      {this.state.expandFollowUpNotes ? '(Collapse)' : '(View all)'}
                    </Button>
                  </React.Fragment>
                )}
              </div>
            </div>
          </React.Fragment>
        )}
        {this.state.show_modal && (
          <FollowUpFlagModal
            show={this.state.show_modal}
            patient={this.props.patient}
            current_user={this.props.current_user}
            jurisdiction_paths={this.props.jurisdiction_paths}
            authenticity_token={this.props.authenticity_token}
            other_household_members={this.props.other_household_members}
            close={() => this.setState({ show_modal: false })}
            bulk_action={false}
          />
        )}
      </React.Fragment>
    );
  }
}

FollowUpFlagPanel.propTypes = {
  patient: PropTypes.object,
  patients: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  authenticity_token: PropTypes.string,
  other_household_members: PropTypes.array,
  bulk_action: PropTypes.bool,
};

export default FollowUpFlagPanel;
