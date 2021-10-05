import React from 'react';
import { PropTypes } from 'prop-types';
import { Button } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';

import FollowUpFlagModal from './FollowUpFlagModal';

class FollowUpFlagPanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showUpdateFlagModal: false,
      showClearFlagModal: false,
      expandFollowUpNotes: false,
    };
  }

  renderActionButtons() {
    return (
      <div className="flag-edit-icons float-right" style={{ width: '45px' }}>
        <span data-for={'update-follow-up-flag'} data-tip="">
          <Button
            id="update-follow-up-flag-btn"
            variant="link"
            className="icon-btn-dark p-0 mr-1"
            onClick={() => this.setState({ showUpdateFlagModal: true })}
            aria-label="Update Follow-up Flag">
            <i className="fas fa-edit"></i>
          </Button>
        </span>
        <ReactTooltip id={'update-follow-up-flag'} place="top" type="dark" effect="solid">
          <span>Update Follow-up Flag</span>
        </ReactTooltip>
        <span data-for={'clear-follow-up-flag-link'} data-tip="">
          <Button
            id="clear-follow-up-flag-btn"
            variant="link"
            className="icon-btn-dark p-0"
            onClick={() => this.setState({ showClearFlagModal: true })}
            aria-label="Clear Follow-up Flag">
            <i className="fas fa-trash"></i>
          </Button>
        </span>
        <ReactTooltip id={'clear-follow-up-flag-link'} place="top" type="dark" effect="solid">
          <span>Clear Follow-up Flag</span>
        </ReactTooltip>
      </div>
    );
  }

  render() {
    return (
      <React.Fragment>
        <div className="follow-up-flag-box w-100 mx-3 mb-3 p-2">
          <div>
            <i className="fas fa-flag"></i>
            <b className="pl-2">Flagged for Follow-up</b>
            {this.renderActionButtons()}
          </div>
          <div className="flag-note pt-1 pl-4">
            <b>{this.props.patient.follow_up_reason}</b>
            {this.props.patient.follow_up_note && this.props.patient.follow_up_note.length < 150 && (
              <span className="wrap-words">{': ' + this.props.patient.follow_up_note}</span>
            )}
            {this.props.patient.follow_up_note && this.props.patient.follow_up_note.length >= 150 && (
              <React.Fragment>
                <span className="wrap-words">
                  {this.state.expandFollowUpNotes ? ': ' + this.props.patient.follow_up_note : ': ' + this.props.patient.follow_up_note.slice(0, 150) + ' ...'}
                </span>
                <Button variant="link" className="notes-button p-0" onClick={() => this.setState({ expandFollowUpNotes: !this.state.expandFollowUpNotes })}>
                  {this.state.expandFollowUpNotes ? '(Collapse)' : '(View all)'}
                </Button>
              </React.Fragment>
            )}
          </div>
        </div>
        {this.state.showUpdateFlagModal && (
          <FollowUpFlagModal
            show={this.state.showUpdateFlagModal}
            patient={this.props.patient}
            current_user={this.props.current_user}
            jurisdiction_paths={this.props.jurisdiction_paths}
            authenticity_token={this.props.authenticity_token}
            other_household_members={this.props.other_household_members}
            close={() => this.setState({ showUpdateFlagModal: false })}
            clear_flag={false}
          />
        )}
        {this.state.showClearFlagModal && (
          <FollowUpFlagModal
            show={this.state.showClearFlagModal}
            patient={this.props.patient}
            current_user={this.props.current_user}
            jurisdiction_paths={this.props.jurisdiction_paths}
            authenticity_token={this.props.authenticity_token}
            other_household_members={this.props.other_household_members}
            close={() => this.setState({ showClearFlagModal: false })}
            clear_flag={true}
          />
        )}
      </React.Fragment>
    );
  }
}

FollowUpFlagPanel.propTypes = {
  patient: PropTypes.object,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  authenticity_token: PropTypes.string,
  other_household_members: PropTypes.array,
  bulkAction: PropTypes.bool,
};

export default FollowUpFlagPanel;
