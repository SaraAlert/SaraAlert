import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Button, Modal } from 'react-bootstrap';
import axios from 'axios';
import ReactTooltip from 'react-tooltip';

import ApplyToHousehold from './household/actions/ApplyToHousehold';
import reportError from '../util/ReportError';

class FollowUpFlag extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      apply_to_household: false,
      apply_to_household_ids: [],
      cancelToken: axios.CancelToken.source(),
      clear_flag: this.props.clear_flag,
      clear_flag_reason: '',
      follow_up_reason: this.props.patient.follow_up_reason || '',
      follow_up_note: this.props.patient.follow_up_note || '',
      loading: false,
      showModal: false,
      noMembersSelected: false,
    };
  }

  handleChange = event => {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    if (event.target.id === 'follow_up_reason') {
      this.setState({ follow_up_reason: value });
    } else if (event.target.id === 'follow_up_note') {
      this.setState({ follow_up_note: value });
    } else if (event.target.id === 'apply_to_household') {
      this.setState({ apply_to_household: value });
    } else if (event.target.id == 'clear_flag') {
      this.setState({ clear_flag: value });
    } else if (event.target.id == 'clear_flag_reason') {
      this.setState({ clear_flag_reason: value });
    }
  };

  handleApplyHouseholdChange = apply_to_household => {
    const noMembersSelected = apply_to_household && this.state.apply_to_household_ids.length === 0;
    this.setState({ apply_to_household, noMembersSelected });
  };

  handleApplyHouseholdIdsChange = apply_to_household_ids => {
    const noMembersSelected = this.state.apply_to_household && apply_to_household_ids.length === 0;
    this.setState({ apply_to_household_ids, noMembersSelected });
  };

  // Makes a POST to update the follow-up flag for the current patient.
  submit = () => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
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
          {this.props.patient.follow_up_reason && (
            <Form.Group>
              <Form.Label>Option to clear the flagged status:</Form.Label>
              <Form.Check
                size="lg"
                label={`Clear Follow-up Flag`}
                id="clear_flag"
                className="ml-1 d-inline"
                checked={this.state.clear_flag}
                onChange={this.handleChange}
              />
              {!this.state.clear_flag && <Form.Label>Please update the reason and/or note for being flagged for follow-up.</Form.Label>}
            </Form.Group>
          )}
          {!this.state.clear_flag && (
            <Form.Group>
              {!this.props.patient.follow_up_reason && (
                <Form.Label>
                  Please select a reason for being flagged for follow-up. If a monitoree is already flagged, this reason will replace any previously selected
                  reason.
                </Form.Label>
              )}
              <Form.Control
                as="select"
                size="lg"
                className="form-square"
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
              <Form.Label>Please include any additional details:</Form.Label>
              <Form.Control as="textarea" rows="2" id="follow_up_note" value={this.state.follow_up_note} onChange={this.handleChange} />
            </Form.Group>
          )}
          {this.state.clear_flag && (
            <Form.Group>
              <Form.Label>Please include any additional details:</Form.Label>
              <Form.Control as="textarea" rows="2" id="clear_flag_reason" value={this.state.clear_flag_reason} onChange={this.handleChange} />
            </Form.Group>
          )}
          {this.props.other_household_members.length > 0 && (
            <ApplyToHousehold
              household_members={this.props.other_household_members}
              current_user={this.props.current_user}
              jurisdiction_paths={this.props.jurisdiction_paths}
              handleApplyHouseholdChange={this.handleApplyHouseholdChange}
              handleApplyHouseholdIdsChange={this.handleApplyHouseholdIdsChange}
            />
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button
            id="follow-up-flag-cancel-button"
            variant="secondary btn-square"
            aria-label="Cancel button for Follow-up Flag modal"
            onClick={this.props.close}>
            Cancel
          </Button>
          <Button
            variant="primary btn-square"
            onClick={this.submit}
            disabled={this.state.follow_up_reason === '' || this.state.loading || this.state.noMembersSelected}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
              </React.Fragment>
            )}
            Submit
            {this.state.noMembersSelected && (
              <ReactTooltip id="case-status-submit" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
                <div>Please select at least one household member or change your selection to apply to this monitoree only</div>
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
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  authenticity_token: PropTypes.string,
  follow_up_reasons: PropTypes.array,
  other_household_members: PropTypes.array,
  clear_flag: PropTypes.bool,
  close: PropTypes.func,
};

export default FollowUpFlag;
