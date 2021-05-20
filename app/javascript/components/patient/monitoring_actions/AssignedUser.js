import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Modal, Form } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';
import ReactTooltip from 'react-tooltip';

import ApplyToHousehold from '../household/actions/ApplyToHousehold';
import InfoTooltip from '../../util/InfoTooltip';
import reportError from '../../util/ReportError';

class AssignedUser extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showAssignedUserModal: false,
      assigned_user: props.patient.assigned_user || '',
      original_assigned_user: props.patient.assigned_user || '',
      apply_to_household: false,
      apply_to_household_ids: [],
      reasoning: '',
      loading: false,
      noMembersSelected: false,
    };
    this.origState = Object.assign({}, this.state);
  }

  handleAssignedUserChange = event => {
    if (
      event?.target?.value === '' ||
      (event?.target?.value && !isNaN(event.target.value) && parseInt(event.target.value) > 0 && parseInt(event.target.value) <= 999999)
    ) {
      this.setState({ assigned_user: event?.target?.value ? parseInt(event.target.value) : '' });
    }
  };

  handleReasoningChange = event => {
    let value = event?.target?.value;
    this.setState({ [event.target.id]: value || '' });
  };

  handleApplyHouseholdChange = apply_to_household => {
    const noMembersSelected = apply_to_household && this.state.apply_to_household_ids.length === 0;
    this.setState({ apply_to_household, noMembersSelected });
  };

  handleApplyHouseholdIdsChange = apply_to_household_ids => {
    const noMembersSelected = this.state.apply_to_household && apply_to_household_ids.length === 0;
    this.setState({ apply_to_household_ids, noMembersSelected });
  };

  // if user hits the Enter key after changing the Assigned User value, shows the modal (in leu of clicking the button)
  handleKeyPress = event => {
    if (event.which === 13 && this.state.assigned_user !== this.state.original_assigned_user) {
      event.preventDefault();
      this.toggleAssignedUserModal();
    }
  };

  toggleAssignedUserModal = () => {
    const current = this.state.showAssignedUserModal;
    this.setState({
      showAssignedUserModal: !current,
      assigned_user: current ? this.state.original_assigned_user : this.state.assigned_user,
      apply_to_household: false,
      apply_to_household_ids: [],
      reasoning: '',
      noMembersSelected: false,
    });
  };

  submit = () => {
    const diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          assigned_user: this.state.assigned_user,
          reasoning: this.state.reasoning,
          apply_to_household: this.state.apply_to_household,
          apply_to_household_ids: this.state.apply_to_household_ids,
          diffState: diffState,
        })
        .then(() => {
          location.reload();
        })
        .catch(err => {
          reportError(err?.response?.data?.error ? err.response.data.error : err, false);
        });
    });
  };

  createModal(toggle, submit) {
    return (
      <Modal size="lg" show centered onHide={toggle}>
        <Modal.Header>
          <Modal.Title>Assigned User</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            Are you sure you want to change assigned user from &quot;{this.state.original_assigned_user}&quot; to &quot;{this.state.assigned_user}&quot;?
          </p>
          {this.props.household_members.length > 0 && (
            <ApplyToHousehold
              household_members={this.props.household_members}
              current_user={this.props.current_user}
              jurisdiction_paths={this.props.jurisdiction_paths}
              handleApplyHouseholdChange={this.handleApplyHouseholdChange}
              handleApplyHouseholdIdsChange={this.handleApplyHouseholdIdsChange}
              workflow={this.props.workflow}
              continuous_exposure_enabled={this.props.continuous_exposure_enabled}
            />
          )}
          <Form.Group>
            <Form.Label>Please include any additional details:</Form.Label>
            <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleReasoningChange} aria-label="Additional Details Text Area" />
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.loading || this.state.noMembersSelected}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            <span data-for="assigned-user-submit" data-tip="">
              Submit
            </span>
            {this.state.noMembersSelected && (
              <ReactTooltip id="assigned-user-submit" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
                <div>Please select at least one household member or change your selection to apply to this monitoree only</div>
              </ReactTooltip>
            )}
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <div className="disabled">
          <Form.Label htmlFor="assigned_user" className="input-label">
            ASSIGNED USER
            <InfoTooltip tooltipTextKey="assignedUser" location="right"></InfoTooltip>
          </Form.Label>
          <Form.Group className="d-flex mb-0">
            <Form.Control
              as="input"
              id="assigned_user"
              list="assigned_users"
              autoComplete="off"
              className="form-control-lg"
              onChange={this.handleAssignedUserChange}
              onKeyPress={this.handleKeyPress}
              value={this.state.assigned_user}
            />
            <datalist id="assigned_users">
              {this.props.assigned_users.map(num => {
                return (
                  <option value={num} key={num}>
                    {num}
                  </option>
                );
              })}
            </datalist>
            <Button
              className="btn-lg btn-square text-nowrap ml-2"
              onClick={this.toggleAssignedUserModal}
              disabled={this.state.assigned_user === this.state.original_assigned_user}>
              <i className="fas fa-users"></i> Change User
            </Button>
          </Form.Group>
        </div>
        {this.state.showAssignedUserModal && this.createModal(this.toggleAssignedUserModal, this.submit)}
      </React.Fragment>
    );
  }
}

AssignedUser.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  household_members: PropTypes.array,
  assigned_users: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  workflow: PropTypes.string,
  continuous_exposure_enabled: PropTypes.bool,
};

export default AssignedUser;
