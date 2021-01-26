import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Modal, Form } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';

import InfoTooltip from '../../util/InfoTooltip';
import reportError from '../../util/ReportError';

class UpdateAssignedUser extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      assigned_user: '',
      initial_assigned_user: undefined,
      apply_to_household: false,
      loading: false,
    };
  }

  componentDidMount() {
    const distinctAssignedUser = [...new Set(this.props.patients.map(x => x.assigned_user))];

    var state_updates = {};
    if (distinctAssignedUser.length === 1 && distinctAssignedUser[0] !== null) {
      state_updates.initial_assigned_user = distinctAssignedUser[0];
      state_updates.assigned_user = distinctAssignedUser[0];
    }

    if (Object.keys(state_updates).length) {
      this.setState(state_updates);
    }
  }

  handleChange = event => {
    event.persist();
    if (
      event.target.id === 'assigned_user_input' &&
      (event.target.value === '' ||
        (event.target.value && !isNaN(event.target.value) && parseInt(event.target.value) > 0 && parseInt(event.target.value) <= 999999))
    ) {
      this.setState({ assigned_user: event.target.value ? parseInt(event.target.value) : '' });
    } else if (event.target.id === 'apply_to_household') {
      this.setState({ apply_to_household: event.target.checked });
    }
  };

  submit = () => {
    let idArray = this.props.patients.map(x => x['id']);
    let diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));

    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/bulk_edit', {
          ids: idArray,
          assigned_user: this.state.assigned_user,
          apply_to_household: this.state.apply_to_household,
          diffState: diffState,
        })
        .then(() => {
          location.href = window.BASE_PATH;
        })
        .catch(error => {
          reportError(error);
          this.setState({ loading: false });
        });
    });
  };

  render() {
    return (
      <React.Fragment>
        <Modal.Body>
          <div className="mt-1 mb-3">
            Please input the desired Assigned User to be associated with all selected monitorees:
            <InfoTooltip tooltipTextKey="assignedUser" location="right"></InfoTooltip>
          </div>
          <Form.Control
            as="input"
            id="assigned_user_input"
            list="assigned_users"
            autoComplete="off"
            className="form-control-lg"
            aria-label="Assigned User Select"
            onChange={this.handleChange}
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
          <React.Fragment>
            <Form.Group className="my-2">
              <Form.Check
                type="switch"
                id="apply_to_household"
                label="Apply this change to the entire household that these monitorees are responsible for, if it applies."
                checked={this.state.apply_to_household}
                onChange={this.handleChange}
              />
            </Form.Group>
          </React.Fragment>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.close}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={this.submit} disabled={this.state.loading}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Submit
          </Button>
        </Modal.Footer>
      </React.Fragment>
    );
  }
}

UpdateAssignedUser.propTypes = {
  authenticity_token: PropTypes.string,
  patients: PropTypes.array,
  close: PropTypes.func,
  assigned_users: PropTypes.array,
};

export default UpdateAssignedUser;
