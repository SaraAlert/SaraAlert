import React from 'react';
import { Button, Modal, Form } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import reportError from '../../util/ReportError';

class UpdateCaseStatus extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      case_status: '',
      message: '',
      confirmed: '',
      isolation: undefined,
      initial_case_status: undefined,
      initial_isolation: undefined,
      initial_monitoring: undefined,
      apply_to_group: false,
      monitoring: false,
      monitoring_reason: '',
      public_health_action: '',
      loading: false,
    };
    this.submit = this.submit.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  activate(patients) {
    if (!patients || !patients.length) {
      return;
    }

    this.getCommonAttributes(patients);
  }

  getCommonAttributes(patients) {
    const distinctCaseStatus = [...new Set(patients.map(x => x.case_status))];
    const distinctIsolation = [...new Set(patients.map(x => x.isolation))];
    const distinctMonitoring = [...new Set(patients.map(x => x.monitoring))];

    var state_updates = {};
    if (distinctCaseStatus.length === 1 && distinctCaseStatus[0] !== null) {
      state_updates.initial_case_status = distinctCaseStatus[0];
      state_updates.case_status = distinctCaseStatus[0];
    }
    if (distinctIsolation.length === 1 && distinctIsolation[0] !== null) {
      state_updates.initial_isolation = distinctIsolation[0];
      state_updates.isolation = distinctIsolation[0];
    }
    if (distinctMonitoring.length === 1 && distinctMonitoring[0] !== null) {
      state_updates.initial_monitoring = distinctMonitoring[0];
      state_updates.monitoring = distinctMonitoring[0];
    }

    if (Object.keys(state_updates).length) {
      this.setState(state_updates);
    }
  }

  handleChange(event) {
    event.persist();
    this.setState({ [event.target.id]: event.target.type === 'checkbox' ? event.target.checked : event.target.value }, () => {
      if (event.target.id === 'confirmed') {
        if (event.target.value === 'End Monitoring') {
          this.setState({
            monitoring: false,
            isolation: undefined, // Make sure not to alter the existing isolation
            monitoring_reason: 'Meets Case Definition',
            message: 'case status to "' + this.state.case_status + '", and chose to "' + event.target.value + '".',
          });
        }
        if (event.target.value === 'Continue Monitoring in Isolation Workflow') {
          this.setState({
            monitoring: true,
            isolation: true,
            monitoring_reason: 'Meets Case Definition',
            message: 'case status to "' + this.state.case_status + '", and chose to "' + event.target.value + '".',
          });
        }
      } else if (event.target.value === 'Suspect' || event.target.value === 'Unknown' || event.target.value === 'Not a Case' || event.target.value === '') {
        this.setState({ monitoring: true, isolation: false, message: 'case status to "' + this.state.case_status + '".' });
      }

      // If in isolation the follow up will not be displayed, ensure changed properties do not carry over
      if ((event.target.value === 'Confirmed' || event.target.value === 'Probable') && this.state.initial_isolation) {
        this.setState({
          monitoring: this.state.initial_monitoring,
          isolation: this.state.initial_isolation,
          monitoring_reason: 'Meets Case Definition',
          message: 'case status to "' + this.state.case_status + '", and chose to "' + event.target.value + '".',
        });
      }
    });
  }

  submit() {
    let idArray = this.props.patients.map(x => x['id']);

    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/bulk_edit/status', {
          ids: idArray,
          comment: true,
          message: this.state.message,
          case_status: this.state.case_status,
          isolation: this.state.isolation,
          monitoring: this.state.monitoring,
          monitoring_reason: this.state.monitoring_reason,
          apply_to_group: this.state.apply_to_group,
          public_health_action:
            this.state.case_status === 'Suspect' || this.state.case_status === 'Unknown' || this.state.case_status == 'Not a Case'
              ? 'None'
              : this.state.public_health_action,
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

  renderFollowUp() {
    // Exposure -> Isolation: Follow up question required
    if ((this.state.case_status === 'Confirmed' || this.state.case_status === 'Probable') && !this.state.initial_isolation) {
      return (
        <div>
          <p>Please select what you would like to do:</p>
          <Form.Control as="select" className="form-control-lg" id="confirmed" onChange={this.handleChange} value={this.state.confirmed}>
            <option></option>
            <option>End Monitoring</option>
            <option>Continue Monitoring in Isolation Workflow</option>
          </Form.Control>
          {this.state.confirmed === 'End Monitoring' && (
            <p className="pt-4">The selected cases will be moved into the &quot;Closed&quot; line list, and will no longer be monitored.</p>
          )}
          {this.state.confirmed === 'Continue Monitoring in Isolation Workflow' && (
            <p className="pt-4">The selected cases will be moved to the isolation workflow.</p>
          )}
          {this.renderApplyToGroup()}
        </div>
      );
    }

    let follow_up_text;

    // Selection -> Confirmed or Probable -> Result is Isolation or Closed
    if ((this.state.case_status === 'Confirmed' || this.state.case_status === 'Probable') && this.state.initial_isolation) {
      // Isolation -> Isolation
      if (this.state.initial_isolation) {
        // Open Monitoring
        if (this.state.initial_monitoring) {
          follow_up_text = (
            <p>
              The selected cases will remain in the isolation workflow and placed in the requires review, non-reporting, or reporting line list as appropriate.
            </p>
          );
        } else {
          // Closed Monitoring
          follow_up_text = <p>The selected cases will remain in the isolation workflow as closed.</p>;
        }
      }
    } else {
      // Selected -> Suspect, Unknown, Not a case -> Result is Exposure
      if (this.state.initial_isolation) {
        // Isolation -> Exposure
        follow_up_text = (
          <p>
            The selected cases will be moved from the isolation workflow to the exposure workflow and placed in the symptomatic, non-reporting, or asymptomatic
            line list as appropriate.
          </p>
        );
      } else {
        // Exposure -> Exposure
        follow_up_text = (
          <p>The selected cases will remain in the exposure workflow and placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate.</p>
        );
      }
    }

    return (
      <div>
        {follow_up_text}
        {this.renderApplyToGroup()}
      </div>
    );
  }

  renderApplyToGroup() {
    return (
      <Form.Group className="mt-2">
        <Form.Check
          type="switch"
          id="apply_to_group"
          label="Apply this change to the entire household that these monitorees are responsible for, if it applies"
          onChange={this.handleChange}
          checked={this.state.apply_to_group === true || false}
        />
      </Form.Group>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Modal.Body>
          <p>Please select the desired case status to be assigned to all selected patients:</p>
          <Form.Control as="select" className="form-control-lg" id="case_status" onChange={this.handleChange} value={this.state.case_status}>
            <option></option>
            <option>Confirmed</option>
            <option>Probable</option>
            <option>Suspect</option>
            <option>Unknown</option>
            <option>Not a Case</option>
          </Form.Control>
          <br />
          {this.state.case_status !== '' && this.renderFollowUp()}
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
                !this.state.initial_isolation &&
                this.state.confirmed === '') ||
              this.state.loading ||
              (this.state.initial_case_status === this.state.case_status && // checks if no changes have been made
                this.state.initial_isolation === this.state.isolation &&
                this.state.initial_monitoring === this.state.monitoring)
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
  close: PropTypes.function,
};

export default UpdateCaseStatus;
