import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Modal, Form } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';

import reportError from '../../util/ReportError';

class UpdateCaseStatus extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      case_status: '',
      follow_up: '',
      isolation: undefined,
      initialCaseStatus: undefined,
      initialIsolation: undefined,
      initialMonitoring: undefined,
      apply_to_household: false,
      monitoring: false,
      monitoring_reason: '',
      loading: false,
    };
    this.handleChange = this.handleChange.bind(this);
    this.submit = this.submit.bind(this);
  }

  componentDidMount() {
    axios
      .post('/patients/current_case_status/', {
        patient_ids: this.props.patients.map(x => x.id),
      })
      .then(response => {
        const distinctCaseStatus = [...new Set(response.data.case_status)];
        const distinctIsolation = [...new Set(response.data.isolation)];
        const distinctMonitoring = [...new Set(response.data.monitoring)];

        const state_updates = {};
        if (distinctCaseStatus.length === 1 && distinctCaseStatus[0] !== null) {
          state_updates.initialCaseStatus = distinctCaseStatus[0];
          state_updates.case_status = distinctCaseStatus[0];
        }
        if (distinctIsolation.length === 1 && distinctIsolation[0] !== null) {
          state_updates.initialIsolation = distinctIsolation[0];
          state_updates.isolation = distinctIsolation[0];
        }
        if (distinctMonitoring.length === 1 && distinctMonitoring[0] !== null) {
          state_updates.initialMonitoring = distinctMonitoring[0];
          state_updates.monitoring = distinctMonitoring[0];
        }

        if (Object.keys(state_updates).length) {
          this.setState(state_updates);
        }
      })
      .catch(error => {
        reportError(error);
      });
  }

  handleChange(event) {
    event.persist();
    this.setState({ [event.target.id]: event.target.type === 'checkbox' ? event.target.checked : event.target.value }, () => {
      if (event.target.id === 'follow_up') {
        if (event.target.value === 'End Monitoring') {
          this.setState({
            monitoring: false,
            isolation: undefined, // Make sure not to alter the existing isolation
            monitoring_reason: 'Meets Case Definition',
          });
        }
        if (event.target.value === 'Continue Monitoring in Isolation Workflow') {
          this.setState({
            monitoring: true,
            isolation: true,
            monitoring_reason: 'Meets Case Definition',
          });
        }
      } else if (event.target.value === 'Suspect' || event.target.value === 'Unknown' || event.target.value === 'Not a Case' || event.target.value === '') {
        this.setState({ monitoring: true, isolation: false });
      }

      // If in isolation the follow up will not be displayed, ensure changed properties do not carry over
      if ((event.target.value === 'Confirmed' || event.target.value === 'Probable') && this.state.initialIsolation) {
        this.setState({
          monitoring: this.state.initialMonitoring,
          isolation: this.state.initialIsolation,
          monitoring_reason: 'Meets Case Definition',
        });
      }
    });
  }

  submit() {
    let idArray = this.props.patients.map(x => x['id']);
    let diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));

    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/bulk_edit', {
          ids: idArray,
          case_status: this.state.case_status,
          isolation: this.state.isolation,
          monitoring: this.state.monitoring,
          monitoring_reason: this.state.monitoring_reason,
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
  }

  render() {
    return (
      <React.Fragment>
        <Modal.Body>
          <p>Please select the desired case status to be assigned to all selected patients:</p>
          <Form.Control
            as="select"
            className="form-control-lg mb-3"
            id="case_status"
            onChange={this.handleChange}
            value={this.state.case_status}
            aria-label="Case Status Select">
            <option></option>
            <option>Confirmed</option>
            <option>Probable</option>
            <option>Suspect</option>
            <option>Unknown</option>
            <option>Not a Case</option>
          </Form.Control>
          {this.state.case_status !== '' && (
            <React.Fragment>
              {['Confirmed', 'Probable'].includes(this.state.case_status) && !this.state.initialIsolation && (
                <React.Fragment>
                  <p>Please select what you would like to do:</p>
                  <Form.Control
                    as="select"
                    className="form-control-lg mb-3"
                    id="follow_up"
                    onChange={this.handleChange}
                    value={this.state.follow_up}
                    aria-label="Case Status Follow Up Select">
                    <option></option>
                    <option>End Monitoring</option>
                    <option>Continue Monitoring in Isolation Workflow</option>
                  </Form.Control>
                </React.Fragment>
              )}
              {['Confirmed', 'Probable'].includes(this.state.case_status) ? (
                <React.Fragment>
                  {this.state.follow_up === 'Continue Monitoring in Isolation Workflow' && [undefined, false].includes(this.state.initialIsolation) && (
                    <p>
                      The selected monitorees will be moved to the isolation workflow and placed in the requiring review, non-reporting, or reporting line list
                      as appropriate.
                    </p>
                  )}
                  {this.state.follow_up === 'Continue Monitoring in Isolation Workflow' && this.state.initialIsolation === true && (
                    <p>The selected monitorees will remain in the isolation workflow.</p>
                  )}
                  {this.state.follow_up === 'End Monitoring' && (
                    <p>The selected monitorees will be moved into the &quot;Closed&quot; line list, and will no longer be monitored.</p>
                  )}
                </React.Fragment>
              ) : (
                <React.Fragment>
                  {[undefined, true].includes(this.state.initialIsolation) && (
                    <p>
                      The selected cases will be moved from the isolation workflow to the exposure workflow and placed in the symptomatic, non-reporting, or
                      asymptomatic line list as appropriate.
                    </p>
                  )}
                  {this.state.initialIsolation === false && <p>The selected cases will remain in the exposure workflow.</p>}
                </React.Fragment>
              )}
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
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.close}>
            Cancel
          </Button>
          <Button
            variant="primary btn-square"
            onClick={this.submit}
            disabled={
              ((this.state.case_status === 'Confirmed' || this.state.case_status === 'Probable') &&
                !this.state.initialIsolation &&
                this.state.confirmed === '') ||
              this.state.loading ||
              (this.state.initialCaseStatus === this.state.case_status && // checks if no changes have been made
                this.state.initialIsolation === this.state.isolation &&
                this.state.initialMonitoring === this.state.monitoring)
            }>
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

UpdateCaseStatus.propTypes = {
  authenticity_token: PropTypes.string,
  patients: PropTypes.array,
  close: PropTypes.func,
};

export default UpdateCaseStatus;
