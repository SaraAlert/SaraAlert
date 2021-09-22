import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Form, Modal } from 'react-bootstrap';
import axios from 'axios';
import ReactTooltip from 'react-tooltip';

import ApplyToHousehold from '../household/actions/ApplyToHousehold';
import reportError from '../../util/ReportError';

const MAX_NOTES_LENGTH = 2000;

class FollowUpFlag extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      apply_to_household: false,
      apply_to_household_ids: [],
      bulk_action_apply_to_household: false,
      cancelToken: axios.CancelToken.source(),
      clear_flag_disabled: true,
      clear_flag: false,
      clear_flag_reason: '',
      follow_up_reason: '',
      follow_up_note: '',
      initial_follow_up_reason: '',
      loading: false,
    };
  }

  componentDidMount() {
    var state_updates = {};
    if (this.props.bulkAction) {
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
      if (this.props.patients[0].follow_up_reason) {
        state_updates.clear_flag = this.props.clear_flag;
        state_updates.initial_follow_up_reason = this.props.patients[0].follow_up_reason;
        state_updates.follow_up_reason = this.props.patients[0].follow_up_reason;
        state_updates.follow_up_note = this.props.patients[0].follow_up_note;
        this.setState(state_updates);
      }
    }
  }

  handleChange = event => {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    if (event.target.id == 'set_flag_for_follow_up') {
      this.setState({ clear_flag: false });
    } else if (event.target.id == 'clear_flag_for_follow_up') {
      this.setState({ clear_flag: true });
    } else {
      this.setState({ [event.target.id]: value });
    }
  };

  handleApplyHouseholdChange = apply_to_household => {
    this.setState({ apply_to_household, apply_to_household_ids: [] });
  };

  handleApplyHouseholdIdsChange = apply_to_household_ids => {
    this.setState({ apply_to_household_ids });
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

  // Makes a POST to update the follow-up flag for the current patient.
  submit = () => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;

      // Different POST requests are used depending on whether this action is triggered via the dashboard or monitoree page
      if (this.props.bulkAction) {
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
            reportError('Failed to bulk update Follow-up Flag.');
            console.log(error);
          });
      } else {
        axios
          .post(window.BASE_PATH + '/patients/' + this.props.patients[0].id + '/follow_up_flag', {
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
          .catch(error => {
            reportError(error?.response?.data?.error ? error.response.data.error : error, false);
            console.log(error);
          });
      }
    });
  };

  render() {
    return (
      <React.Fragment>
        <Modal.Body>
          {this.props.bulkAction && (
            <Form.Group style={{ display: 'inline-flex' }}>
              <Form.Check
                type="radio"
                name="flag_for_follow_up_option"
                className="pr-5"
                id="set_flag_for_follow_up"
                label="Set Follow-up Flag"
                onChange={this.handleChange}
                checked={!this.state.clear_flag}
              />
              <span data-for="clear_flag_disable_reason" data-tip="">
                <Form.Check
                  type="radio"
                  name="flag_for_follow_up_option"
                  id="clear_flag_for_follow_up"
                  label="Clear Follow-up Flag"
                  disabled={this.state.clear_flag_disabled}
                  onChange={this.handleChange}
                  checked={this.state.clear_flag}
                />
              </span>
              {this.state.clear_flag_disabled && (
                <ReactTooltip id="clear_flag_disable_reason" multiline={true} place="bottom" type="dark" effect="solid" className="tooltip-container">
                  <div>None of the selected monitorees have a flag set</div>
                </ReactTooltip>
              )}
            </Form.Group>
          )}
          {!this.state.clear_flag && (
            <React.Fragment>
              <Form.Group controlId="follow_up_reason">
                <Form.Label>
                  Please select a reason for being flagged for follow-up. If a monitoree is already flagged, this reason will replace any previously selected
                  reason.
                </Form.Label>
                <Form.Control as="select" size="lg" className="form-square mb-3" value={this.state.follow_up_reason} onChange={this.handleChange}>
                  <option></option>
                  <option>Deceased</option>
                  <option>Duplicate</option>
                  <option>High-Risk</option>
                  <option>Hospitalized</option>
                  <option>In Need of Follow-up</option>
                  <option>Lost to Follow-up</option>
                  <option>Needs Interpretation</option>
                  <option>Quality Assurance</option>
                  <option>Refused Active Monitoring</option>
                  <option>Other</option>
                </Form.Control>
              </Form.Group>
              <Form.Group controlId="follow_up_note">
                <Form.Label>Please include any additional details:</Form.Label>
                <Form.Control as="textarea" rows="4" maxLength={MAX_NOTES_LENGTH} value={this.state.follow_up_note || ''} onChange={this.handleChange} />
                <div className="character-limit-text">{MAX_NOTES_LENGTH - (this.state.follow_up_note || '').length} characters remaining</div>
              </Form.Group>
            </React.Fragment>
          )}
          {this.props.other_household_members.length > 0 && !this.props.bulkAction && (
            <ApplyToHousehold
              household_members={this.props.other_household_members}
              current_user={this.props.current_user}
              jurisdiction_paths={this.props.jurisdiction_paths}
              handleApplyHouseholdChange={this.handleApplyHouseholdChange}
              handleApplyHouseholdIdsChange={this.handleApplyHouseholdIdsChange}
            />
          )}
          {this.props.bulkAction && (
            <React.Fragment>
              <Form.Group>
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
            <Form.Group controlId="clear_flag_reason">
              <Form.Label>Please include any additional details for clearing the follow-up flag:</Form.Label>
              <Form.Control as="textarea" rows="2" value={this.state.clear_flag_reason} onChange={this.handleChange} />
              {this.props.bulkAction && (
                <p className="mt-3">
                  If any selected monitorees do not currently have a flag set, their records will not be updated as a result of this action.
                </p>
              )}
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
            disabled={
              (!this.state.clear_flag && this.state.follow_up_reason === '') ||
              this.state.loading ||
              (this.state.apply_to_household && this.state.apply_to_household_ids.length === 0)
            }>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            <span data-for="follow-up-submit" data-tip="">
              {(this.props.bulkAction || this.state.initial_follow_up_reason === '') && 'Submit'}
              {!this.props.bulkAction && this.state.initial_follow_up_reason !== '' && !this.state.clear_flag && 'Update'}
              {!this.props.bulkAction && this.state.clear_flag && 'Clear'}
            </span>
            {this.state.apply_to_household && this.state.apply_to_household_ids.length === 0 && (
              <ReactTooltip id="follow-up-submit" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
                <div>Please select at least one household member or change your selection to apply to this monitoree only</div>
              </ReactTooltip>
            )}
            {!(this.state.apply_to_household && this.state.apply_to_household_ids.length === 0) &&
              !this.state.clear_flag &&
              this.state.follow_up_reason === '' && (
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
  patients: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  authenticity_token: PropTypes.string,
  other_household_members: PropTypes.array,
  close: PropTypes.func,
  bulkAction: PropTypes.bool,
  clear_flag: PropTypes.bool,
};

export default FollowUpFlag;
