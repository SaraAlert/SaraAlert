import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Modal, Form } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';

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
      loading: false,
      reasoning: '',
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

  handleApplyHouseholdChange = event => {
    const applyToHousehold = event.target.id === 'apply_to_household_yes';
    this.setState({ apply_to_household: applyToHousehold });
  };

  handleReasoningChange = event => {
    let value = event?.target?.value;
    this.setState({ [event.target.id]: value || '' });
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
      reasoning: '',
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
          diffState: diffState,
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
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
          {this.props.has_dependents && (
            <React.Fragment>
              <p className="mb-2">Please select the records that you would like to apply this change to:</p>
              <Form.Group className="px-4">
                <Form.Check
                  type="radio"
                  className="mb-1"
                  name="apply_to_household"
                  id="apply_to_household_no"
                  label="This monitoree only"
                  onChange={this.handleApplyHouseholdChange}
                  checked={!this.state.apply_to_household}
                />
                <Form.Check
                  type="radio"
                  className="mb-3"
                  name="apply_to_household"
                  id="apply_to_household_yes"
                  label="This monitoree and all household members"
                  onChange={this.handleApplyHouseholdChange}
                  checked={this.state.apply_to_household}
                />
              </Form.Group>
            </React.Fragment>
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
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.loading}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Submit
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <div className="disabled">
          <Form.Label htmlFor="assigned_user" className="nav-input-label">
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
  has_dependents: PropTypes.bool,
  assigned_users: PropTypes.array,
};

export default AssignedUser;
