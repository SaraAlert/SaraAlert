import React from 'react';
import { Button, Modal, Form } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import reportError from '../util/ReportError';

class CaseStatus extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showModal: false,
      patients: [],
      case_status: '',
      message: '',
      confirmed: '',
      isolation: undefined,
      apply_to_group: false,
      monitoring: false,
      monitoring_reason: '',
      public_health_action: '',
      loading: false,
    };
    this.submit = this.submit.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.toggleCaseStatusModal = this.toggleCaseStatusModal.bind(this);

    window.bulkEditCaseStatusComponent = this;
  }

  activate(patients) {
    if (!patients || !patients.length) {
      return;
    }

    this.getCommonAttributes(patients);

    this.setState({
      showModal: true,
      patients: patients,
    });
  }

  toggleCaseStatusModal() {
    let current = this.state.showModal;
    this.setState({
      showModal: !current,
    });
  }

  // Creates a dictionary, tracking the count of common attributes. This list is used to pre-populate
  // the form fields and can be displayed to the user for knowledge of the selection.
  getCommonAttributes(patients) {
    if (patients.length == 0) return '';
    var dict = {
      case_status: {},
      monitoring: {},
      isolation: {},
    };
    for (var i = 0; i < patients.length; i++) {
      const patient = patients[parseInt(i)];

      let case_status = patient.case_status;
      if (case_status == null) case_status = '';
      if (dict.case_status[`${case_status}`] == null) dict.case_status[`${case_status}`] = 1;
      else dict.case_status[`${case_status}`]++;

      let monitoring = patient.monitoring;
      if (monitoring == null) monitoring = 'unknown';
      else monitoring = monitoring.toString();
      if (dict.monitoring[`${monitoring}`] == null) dict.monitoring[`${monitoring}`] = 1;
      else dict.monitoring[`${monitoring}`]++;

      let isolation = patient.isolation;
      if (isolation == null) isolation = 'unknown';
      else isolation = isolation.toString();
      if (dict.isolation[`${isolation}`] == null) dict.isolation[`${isolation}`] = 1;
      else dict.isolation[`${isolation}`]++;
    }

    if (Object.keys(dict.case_status).length === 1) {
      this.setState({
        case_status: Object.keys(dict.case_status)[0],
      });
    }
  }

  handleChange(event) {
    event.persist();
    this.setState({ [event.target.id]: event.target.type === 'checkbox' ? event.target.checked : event.target.value, showModal: true }, () => {
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
    });
  }

  submit() {
    let idArray = this.state.patients.map(x => x['id']);

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
        });
    });
  }

  renderFollowUp() {
    if (this.state.case_status === 'Confirmed' || this.state.case_status === 'Probable') {
      return (
        <div>
          <p>Please select what you would like to do:</p>
          <Form.Control as="select" className="form-control-lg" id="confirmed" onChange={this.handleChange} value={this.state.confirmed}>
            <option></option>
            <option>End Monitoring</option>
            <option>Continue Monitoring in Isolation Workflow</option>
          </Form.Control>
          {this.state.confirmed === 'End Monitoring' && (
            <p className="pt-4">The monitoree will be moved into the &quot;Closed&quot; line list, and will no longer be monitored.</p>
          )}
          {this.state.confirmed === 'Continue Monitoring in Isolation Workflow' && (
            <p className="pt-4">The monitoree will be moved to the isolation workflow.</p>
          )}
          <Form.Group className="mt-2">
            <Form.Check
              type="switch"
              id="apply_to_group"
              label="Apply this change to the entire household that this monitoree is responsible for, if it applies"
              onChange={this.handleChange}
              checked={this.state.apply_to_group === true || false}
            />
          </Form.Group>
        </div>
      );
    } else {
      return (
        <div>
          <p>This case will be moved from the PUI to symptomatic, non-reporting, or asymptomatic line list as appropriate to continue exposure monitoring.</p>
          <Form.Group className="mt-2">
            <Form.Check
              type="switch"
              id="apply_to_group"
              label="Apply this change to the entire household that this monitoree is responsible for, if it applies"
              onChange={this.handleChange}
              checked={this.state.apply_to_group === true || false}
            />
          </Form.Group>
        </div>
      );
    }
  }

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>Please select the desired case status to be assigned to a all selected patients:</p>
          <Form.Control as="select" className="form-control-lg" id="case_status" onChange={this.handleChange} value={this.state.case_status}>
            <option></option>
            <option>Confirmed</option>
            <option>Probable</option>
            <option>Suspect</option>
            <option>Unknown</option>
            <option>Not a Case</option>
          </Form.Control>
          {this.state.case_status !== '' && this.renderFollowUp()}
        </Modal.Body>
        <Modal.Footer>
          <Button
            variant="primary btn-square"
            onClick={submit}
            disabled={
              this.state.case_status === '' ||
              ((this.state.case_status === 'Confirmed' || this.state.case_status === 'Probable') && this.state.confirmed === '') ||
              this.state.loading
            }>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Submit
          </Button>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return <React.Fragment>{this.state.showModal && this.createModal('Case Status', this.toggleCaseStatusModal, this.submit)}</React.Fragment>;
  }
}

CaseStatus.propTypes = {
  authenticity_token: PropTypes.string,
};

export default CaseStatus;
