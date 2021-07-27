import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Modal, Form } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';

import reportError from '../../util/ReportError';

const MAX_NOTES_LENGTH = 2000;

class UpdateCaseStatus extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      // The behavior for this modal changes if everyone that is selected is already `closed`
      allSelectedAreClosed: _.every(this.props.patients, p => !_.isNil(p.closed_at) || p.status === 'closed'),
      someSelectedAreClosed: _.some(this.props.patients, p => !_.isNil(p.closed_at) || p.status === 'closed'),
      case_status: '',
      follow_up: '',
      isolation: undefined,
      initialCaseStatus: undefined,
      initialIsolation: undefined,
      initialMonitoringReason: undefined,
      initialMonitoring: undefined,
      apply_to_household: false,
      reasoning: '',
      monitoring: null,
      monitoring_reason: '',
      loading: false,
      isolationWorkflowAvailable: props.available_workflows.some(w => w.name.toLowerCase() == 'isolation'),
    };
    this.origState = Object.assign({}, this.state);
  }

  componentDidMount() {
    axios
      .post(window.BASE_PATH + '/patients/current_case_status/', {
        patient_ids: this.props.patients.map(x => x.id),
      })
      .then(response => {
        const distinctCaseStatus = [...new Set(response.data.case_status)];
        const distinctIsolation = [...new Set(response.data.isolation)];
        const distinctMonitoring = [...new Set(response.data.monitoring)];
        const distinctMonitoringReason = [...new Set(response.data.monitoring_reason)];

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
        if (distinctMonitoringReason.length === 1 && distinctMonitoringReason[0] !== null) {
          state_updates.initialMonitoringReason = distinctMonitoringReason[0];
          state_updates.monitoring_reason = distinctMonitoringReason[0];
        }

        if (Object.keys(state_updates).length) {
          this.setState(state_updates);
        }
      })
      .catch(error => {
        reportError(error);
      });
  }

  handleChange = event => {
    event.persist();
    this.setState({ [event.target.id]: event.target.type === 'checkbox' ? event.target.checked : event.target.value }, () => {
      if (event.target.id === 'follow_up') {
        if (event.target.value === 'End Monitoring') {
          this.setState({
            monitoring: false,
            isolation: undefined, // Make sure not to alter the existing isolation
            monitoring_reason: 'Meets Case Definition', // Default to `Meets Case Definition`
          });
        }
        if (event.target.value === 'Continue Monitoring in Isolation Workflow') {
          this.setState({
            monitoring: true,
            isolation: true,
            monitoring_reason: '',
          });
        }
      } else if (event.target.id === 'monitoring_reason') {
        this.setState({ monitoring_reason: event.target.value });
      } else if (event.target.id === 'reasoning') {
        this.setState({ reasoning: event.target.value });
      } else if (event.target.value === 'Suspect' || event.target.value === 'Unknown' || event.target.value === 'Not a Case' || event.target.value === '') {
        this.setState({ monitoring: true, isolation: false, monitoring_reason: this.state.initialMonitoringReason || '', reasoning: '' });
      }

      // If in isolation the follow up will not be displayed, ensure changed properties do not carry over
      if ((event.target.value === 'Confirmed' || event.target.value === 'Probable') && this.state.initialIsolation) {
        this.setState({
          monitoring: this.state.initialMonitoring,
          isolation: this.state.initialIsolation,
          monitoring_reason: this.state.monitoring_reason,
        });
      }
    });
  };

  submit = () => {
    let idArray = this.props.patients.map(x => x['id']);
    let diffState = [];
    if (this.state.case_status !== this.state.initialCaseStatus) {
      diffState.push('case_status');
    }
    if (this.state.monitoring_reason !== this.state.initialMonitoringReason) {
      diffState.push('monitoring_reason');
    }
    if (this.state.monitoring !== this.state.initialMonitoring) {
      diffState.push('monitoring');
    }
    if (this.state.isolation !== this.state.initialIsolation) {
      diffState.push('isolation');
    }
    if (this.state.follow_up !== this.origState.follow_up) {
      diffState.push('follow_up');
    }
    if (this.state.reasoning !== this.origState.reasoning) {
      diffState.push('reasoning');
    }

    this.setState({ loading: true }, () => {
      // Per feedback, include the monitoring_reason in the reasoning text, as the user might not inlude any text
      let reasoning;
      // We want to include the monitoring_reason in the reasoning text ONLY if case_status was also updated
      if (diffState.includes('monitoring_reason') && !diffState.includes('case_status')) {
        reasoning = this.state.isolation ? '' : this.state.reasoning;
      } else {
        reasoning = this.state.isolation ? '' : [this.state.monitoring_reason, this.state.reasoning].filter(x => x).join(', ');
      }
      // Add a period at the end of the Reasoning (if it's not already included)
      if (reasoning && !['.', '!', '?'].includes(_.last(reasoning))) {
        reasoning += '.';
      }
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/bulk_edit', {
          ids: idArray,
          case_status: this.state.case_status,
          isolation: this.state.isolation,
          monitoring: this.state.monitoring,
          monitoring_reason: this.state.monitoring_reason || this.state.initialMonitoringReason,
          reasoning,
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

  // The logic for disabling the submit button is pretty complex
  // Breaking it out into its own function makes it easier to read
  disableSubmitButton = () => {
    if (this.state.loading) {
      return true;
    }
    if (this.state.allSelectedAreClosed) {
      return false;
    }
    if (
      this.state.initialCaseStatus === this.state.case_status &&
      this.state.initialIsolation === this.state.isolation &&
      this.state.initialMonitoring === this.state.monitoring
    ) {
      return true;
    }
    if (['Confirmed', 'Probable'].includes(this.state.case_status) && !this.state.initialIsolation) {
      if (this.state.confirmed === '' || (this.state.follow_up === '' && !this.state.allSelectedAreClosed)) {
        return true;
      }
    }
    return false;
  };

  renderReasonsSection = () => {
    return (
      <div>
        <Form.Group controlId="monitoring_reason">
          <Form.Label>Please select reason for closure:</Form.Label>
          <Form.Control as="select" size="lg" className="form-square" onChange={this.handleChange} value={this.state.monitoring_reason}>
            <option></option>
            {this.props.monitoring_reasons.map((option, index) => (
              <option key={`option-${index}`} value={option}>
                {option}
              </option>
            ))}
          </Form.Control>
        </Form.Group>
        <Form.Group controlId="reasoning">
          <Form.Label>Please include any additional details:</Form.Label>
          <Form.Control as="textarea" maxLength={MAX_NOTES_LENGTH} rows="2" onChange={this.handleChange} />
          <div className="character-limit-text"> {MAX_NOTES_LENGTH - this.state.reasoning.length} characters remaining </div>
        </Form.Group>
      </div>
    );
  };

  renderClosedStatement = () => {
    return (
      this.state.someSelectedAreClosed && <span>For records on the Closed line list, updating this value will not move the record to another line list.</span>
    );
  };

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
          <React.Fragment>
            {['Confirmed', 'Probable'].includes(this.state.case_status) && !this.state.allSelectedAreClosed && !this.state.initialIsolation && (
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
                  {this.state.isolationWorkflowAvailable && <option>Continue Monitoring in Isolation Workflow</option>}
                </Form.Control>
              </React.Fragment>
            )}
            {this.state.initialIsolation ? (
              // In the Isolation workflow, only show certain explanation statements
              <React.Fragment>
                {!this.state.allSelectedAreClosed && (
                  <p>
                    {['Confirmed', 'Probable'].includes(this.state.case_status) && 'The selected cases will remain in the isolation workflow.'}
                    {['', 'Suspect', 'Not a Case', 'Unknown'].includes(this.state.case_status) &&
                      'The selected cases will be moved from the isolation workflow to the exposure workflow and placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate.'}
                  </p>
                )}
                {this.renderClosedStatement()}
              </React.Fragment>
            ) : (
              // In the Exposure workflow, show other explanation statements
              <React.Fragment>
                {['Confirmed', 'Probable'].includes(this.state.case_status) && (
                  <div>
                    {this.state.follow_up === 'Continue Monitoring in Isolation Workflow' && (
                      <p>
                        The selected monitorees will be moved to the isolation workflow and placed in the requiring review, non-reporting, or reporting line
                        list as appropriate. {this.renderClosedStatement()}
                      </p>
                    )}
                    {this.state.follow_up === 'End Monitoring' && (
                      <div>
                        <p>The selected monitorees will be moved into the Closed line list, and will no longer be monitored.</p>
                        {this.renderReasonsSection()}
                      </div>
                    )}
                  </div>
                )}
                {['', 'Suspect', 'Not a Case', 'Unknown'].includes(this.state.case_status) && (
                  <p>The selected cases will remain in the exposure workflow. {this.renderClosedStatement()}</p>
                )}
                {this.state.allSelectedAreClosed && this.renderReasonsSection()}
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
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.close}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={this.submit} disabled={this.disableSubmitButton()}>
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
  monitoring_reasons: PropTypes.array,
  available_workflows: PropTypes.array,
};

export default UpdateCaseStatus;
