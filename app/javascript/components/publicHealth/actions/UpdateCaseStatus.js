import React from 'react';
import { Button, Modal, Form } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import reportError from '../../util/ReportError';

class UpdateCaseStatus extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      caseStatus: '',
      message: '',
      followUp: '',
      isolation: undefined,
      initialCaseStatus: undefined,
      initialIsolation: undefined,
      initialMonitoring: undefined,
      applyToGroup: false,
      monitoring: false,
      monitoringReason: '',
      loading: false,
    };
    this.handleChange = this.handleChange.bind(this);
    this.submit = this.submit.bind(this);
  }

  componentDidMount() {
    const distinctCaseStatus = [...new Set(this.props.patients.map(x => x.case_status))];
    const distinctIsolation = [...new Set(this.props.patients.map(x => x.isolation))];
    const distinctMonitoring = [...new Set(this.props.patients.map(x => x.monitoring))];

    var state_updates = {};
    if (distinctCaseStatus.length === 1 && distinctCaseStatus[0] !== null) {
      state_updates.initialCaseStatus = distinctCaseStatus[0];
      state_updates.caseStatus = distinctCaseStatus[0];
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
  }

  handleChange(event) {
    event.persist();
    this.setState({ [event.target.id]: event.target.type === 'checkbox' ? event.target.checked : event.target.value }, () => {
      if (event.target.id === 'followUp') {
        if (event.target.value === 'End Monitoring') {
          this.setState({
            monitoring: false,
            isolation: undefined, // Make sure not to alter the existing isolation
            monitoringReason: 'Meets Case Definition',
            message: 'case status to "' + this.state.caseStatus + '", and chose to "' + event.target.value + '".',
          });
        }
        if (event.target.value === 'Continue Monitoring in Isolation Workflow') {
          this.setState({
            monitoring: true,
            isolation: true,
            monitoringReason: 'Meets Case Definition',
            message: 'case status to "' + this.state.caseStatus + '", and chose to "' + event.target.value + '".',
          });
        }
      } else if (event.target.value === 'Suspect' || event.target.value === 'Unknown' || event.target.value === 'Not a Case' || event.target.value === '') {
        this.setState({ monitoring: true, isolation: false, message: 'case status to "' + this.state.caseStatus + '".' });
      }

      // If in isolation the follow up will not be displayed, ensure changed properties do not carry over
      if ((event.target.value === 'Confirmed' || event.target.value === 'Probable') && this.state.initialIsolation) {
        this.setState({
          monitoring: this.state.initialMonitoring,
          isolation: this.state.initialIsolation,
          monitoringReason: 'Meets Case Definition',
          message: 'case status to "' + this.state.caseStatus + '", and chose to "' + event.target.value + '".',
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
          case_status: this.state.caseStatus,
          isolation: this.state.isolation,
          monitoring: this.state.monitoring,
          monitoring_reason: this.state.monitoringReason,
          apply_to_group: this.state.applyToGroup,
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
          <Form.Control as="select" className="form-control-lg mb-3" id="caseStatus" onChange={this.handleChange} value={this.state.caseStatus}>
            <option></option>
            <option>Confirmed</option>
            <option>Probable</option>
            <option>Suspect</option>
            <option>Unknown</option>
            <option>Not a Case</option>
          </Form.Control>
          {this.state.caseStatus !== '' && (
            <React.Fragment>
              {['Confirmed', 'Probable'].includes(this.state.caseStatus) && !this.state.initialIsolation && (
                <React.Fragment>
                  <p>Please select what you would like to do:</p>
                  <Form.Control as="select" className="form-control-lg mb-3" id="followUp" onChange={this.handleChange} value={this.state.followUp}>
                    <option></option>
                    <option>End Monitoring</option>
                    <option>Continue Monitoring in Isolation Workflow</option>
                  </Form.Control>
                </React.Fragment>
              )}
              {['Confirmed', 'Probable'].includes(this.state.caseStatus) ? (
                <React.Fragment>
                  {this.state.followUp === 'Continue Monitoring in Isolation Workflow' && [undefined, false].includes(this.state.initialIsolation) && (
                    <p>
                      The selected monitorees will be moved to the isolation workflow and placed in the requiring review, non-reporting, or reporting line list
                      as appropriate.
                    </p>
                  )}
                  {this.state.followUp === 'Continue Monitoring in Isolation Workflow' && this.state.initialIsolation === true && (
                    <p>The selected monitorees will remain in the isolation workflow.</p>
                  )}
                  {this.state.followUp === 'End Monitoring' && (
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
                  id="applyToGroup"
                  label="Apply this change to the entire household that these monitorees are responsible for, if it applies"
                  checked={this.state.applyToGroup === true || false}
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
              ((this.state.caseStatus === 'Confirmed' || this.state.caseStatus === 'Probable') &&
                !this.state.initialIsolation &&
                this.state.confirmed === '') ||
              this.state.loading ||
              (this.state.initialCaseStatus === this.state.caseStatus && // checks if no changes have been made
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
