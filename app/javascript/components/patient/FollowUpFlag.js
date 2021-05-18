import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Form, Modal } from 'react-bootstrap';
import axios from 'axios';
import ReactTooltip from 'react-tooltip';

import ApplyToHousehold from './household/actions/ApplyToHousehold';
import reportError from '../util/ReportError';

const MAX_NOTES_LENGTH = 2000;

class FollowUpFlag extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      apply_to_household: false,
      apply_to_household_ids: [],
      no_members_selected: false,
      bulk_action_apply_to_household: false,
      cancelToken: axios.CancelToken.source(),
      clear_flag_disabled: true,
      clear_flag: false,
      clear_flag_reason: '',
      follow_up_reason: '',
      follow_up_note: '',
      initial_follow_up_reason: '',
      initial_follow_up_note: '',
      loading: false,
    };
  }

  componentDidMount() {
    var state_updates = {};
    if (this.props.bulk_action) {
      // When the selected monitorees share the same follow up reason/note, pre-populate the modal with those values
      const distinctFollowUpReason = [...new Set(this.props.patients.map(x => x.flagged_for_follow_up.follow_up_reason))];
      const distinctFollowUpNote = [...new Set(this.props.patients.map(x => x.flagged_for_follow_up.follow_up_note))];

      // If at least one monitoree has a follow up flag set, enable the clear flag option
      if (!(distinctFollowUpReason.length === 1 && distinctFollowUpReason[0] === null)) {
        state_updates.clear_flag_disabled = false;
      }
      if (distinctFollowUpReason.length === 1 && distinctFollowUpReason[0] !== null) {
        state_updates.follow_up_reason = distinctFollowUpReason[0];
      }
      if (distinctFollowUpNote.length === 1 && distinctFollowUpNote[0] !== null) {
        state_updates.follow_up_note = distinctFollowUpNote[0];
      }

      if (Object.keys(state_updates).length) {
        this.setState(state_updates);
      }
    } else {
      if (this.props.patient.follow_up_reason) {
        // If the monitoree has a follow up flag set, enable the clear flag option
        state_updates.clear_flag_disabled = false;
        state_updates.follow_up_reason = this.props.patient.follow_up_reason;
        state_updates.follow_up_note = this.props.patient.follow_up_note;
        this.setState(state_updates);
      }
    }
  }

  handleChange = event => {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    if (event.target.id === 'follow_up_reason') {
      this.setState({ follow_up_reason: value });
    } else if (event.target.id === 'follow_up_note') {
      this.setState({ follow_up_note: value });
    } else if (event.target.id === 'apply_to_household') {
      this.setState({ apply_to_household: value });
    } else if (event.target.id === 'bulk_action_apply_to_household') {
      this.setState({ bulk_action_apply_to_household: value });
    } else if (event.target.id == 'set_flag_for_follow_up') {
      this.setState({ clear_flag: false });
    } else if (event.target.id == 'clear_flag_for_follow_up') {
      this.setState({ clear_flag: true });
    } else if (event.target.id == 'clear_flag_reason') {
      this.setState({ clear_flag_reason: value });
    }
  };

  handleApplyHouseholdChange = apply_to_household => {
    const no_members_selected = apply_to_household && this.state.apply_to_household_ids.length === 0;
    this.setState({ apply_to_household, no_members_selected });
  };

  handleApplyHouseholdIdsChange = apply_to_household_ids => {
    const no_members_selected = this.state.apply_to_household && apply_to_household_ids.length === 0;
    this.setState({ apply_to_household_ids, no_members_selected });
  };

  // Makes a POST to update the follow-up flag for the current patient.
  submit = () => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;

      // Different POST requests are used depending on whether this action is triggered via the dashboard or monitoree page
      if (this.props.bulk_action) {
        let idArray = this.props.patients.map(x => x['id']);
        axios
          .post(window.BASE_PATH + '/patients/bulk_edit', {
            ids: idArray,
            bulk_edit_type: 'follow-up',
            follow_up_reason: this.state.follow_up_reason,
            follow_up_note: this.state.follow_up_note,
            clear_flag: this.state.clear_flag,
            clear_flag_reason: this.state.clear_flag_reason,
            apply_to_household: this.state.bulk_action_apply_to_household,
          })
          .then(() => {
            location.href = window.BASE_PATH;
          })
          .catch(error => {
            reportError(error);
            this.setState({ loading: false });
          });
      } else {
        axios
          .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/follow_up_flag', {
            follow_up_reason: this.state.follow_up_reason,
            follow_up_note: this.state.follow_up_note,
            clear_flag: this.state.clear_flag,
            clear_flag_reason: this.state.clear_flag_reason,
            apply_to_household: this.state.apply_to_household,
            apply_to_household_ids: this.state.apply_to_household_ids,
          })
          .then(() => {
            // Reload the page to see the flag on the monitoree's page
            location.reload();
          })
          .catch(err => {
            reportError(err?.response?.data?.error ? err.response.data.error : err, false);
          });
      }
    });
  };

  /**
   * Handles a key press event on the search form control.
   * Checks for enter button press and prevents submisson event.
   * @param {Object} event
   */
  handleKeyPress = event => {
    if (event.which === 13) {
      event.preventDefault();
    }
  };

  render() {
    return (
      <React.Fragment>
        <Modal.Body className="modal-follow-up-flag-body">
          <Form.Group className="flag-radio-buttons">
            <Form.Check
              type="radio"
              name="flag_for_follow_up_option"
              className="pr-50"
              id="set_flag_for_follow_up"
              label="Set Follow-up Flag"
              onChange={this.handleChange}
              checked={!this.state.clear_flag}
            />
            <Form.Check
              type="radio"
              name="flag_for_follow_up_option"
              id="clear_flag_for_follow_up"
              label="Clear Follow-up Flag"
              disabled={this.state.clear_flag_disabled}
              onChange={this.handleChange}
              checked={this.state.clear_flag}
            />
          </Form.Group>
          {!this.state.clear_flag && (
            <Form.Group>
              <Form.Label>
                Please select a reason for being flagged for follow-up. If a monitoree is already flagged, this reason will replace any previously selected
                reason.
              </Form.Label>
              <Form.Control
                as="select"
                size="lg"
                className="form-square mb-25"
                id="follow_up_reason"
                value={this.state.follow_up_reason}
                onChange={this.handleChange}>
                <option></option>
                {this.props.follow_up_reasons.map((option, index) => (
                  <option key={`option-${index}`} value={option}>
                    {option}
                  </option>
                ))}
              </Form.Control>
              <Form.Group>
                <Form.Label>Please include any additional details:</Form.Label>
                <Form.Control
                  as="textarea"
                  rows="4"
                  id="follow_up_note"
                  maxLength={MAX_NOTES_LENGTH}
                  value={this.state.follow_up_note}
                  onChange={this.handleChange}
                />
                <div className="character-limit-text">{MAX_NOTES_LENGTH - this.state.follow_up_note.length} characters remaining</div>
              </Form.Group>
            </Form.Group>
          )}
          {this.props.other_household_members.length > 0 && !this.props.bulk_action && (
            <ApplyToHousehold
              household_members={this.props.other_household_members}
              current_user={this.props.current_user}
              jurisdiction_paths={this.props.jurisdiction_paths}
              handleApplyHouseholdChange={this.handleApplyHouseholdChange}
              handleApplyHouseholdIdsChange={this.handleApplyHouseholdIdsChange}
            />
          )}
          {this.props.bulk_action && (
            <React.Fragment>
              <Form.Group className="mb-25 mt-25">
                <Form.Check
                  type="switch"
                  id="bulk_action_apply_to_household"
                  label="Apply this change to the entire household that these monitorees are responsible for, if it applies."
                  checked={this.state.bulk_action_apply_to_household}
                  onChange={this.handleChange}
                />
              </Form.Group>
            </React.Fragment>
          )}
          {this.state.clear_flag && (
            <Form.Group>
              <Form.Label>Please include any additional details for clearing the follow-up flag:</Form.Label>
              <Form.Control as="textarea" rows="2" id="clear_flag_reason" value={this.state.clear_flag_reason} onChange={this.handleChange} />
            </Form.Group>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button id="follow_up_flag_cancel_button" variant="secondary btn-square" onClick={this.props.close}>
            Cancel
          </Button>
          <Button
            id="follow_up_flag_submit_button"
            variant="primary btn-square"
            onClick={this.submit}
            disabled={(!this.state.clear_flag && this.state.follow_up_reason === '') || this.state.loading || this.state.no_members_selected}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            <span data-for="follow-up-submit" data-tip="">
              Submit
            </span>
            {this.state.no_members_selected && (
              <ReactTooltip id="follow-up-submit" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
                <div>Please select at least one household member or change your selection to apply to this monitoree only</div>
              </ReactTooltip>
            )}
            {!this.state.no_members_selected && !this.state.clear_flag && this.state.follow_up_reason === '' && (
              <ReactTooltip id="follow-up-submit" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
                <div>Please select a reason for follow-up</div>
              </ReactTooltip>
            )}
          </Button>
        </Modal.Footer>
      </React.Fragment>
    );
  }
}

FollowUpFlag.propTypes = {
  patient: PropTypes.object,
  patients: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  authenticity_token: PropTypes.string,
  follow_up_reasons: PropTypes.array,
  other_household_members: PropTypes.array,
  close: PropTypes.func,
  bulk_action: PropTypes.bool,
};

export default FollowUpFlag;
