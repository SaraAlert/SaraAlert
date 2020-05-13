import React from 'react';
import { Button, Modal, Form } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import reportError from '../util/ReportError';
import InfoTooltip from '../util/InfoTooltip';

class CaseStatus extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showCaseStatusModal: false,
      case_status: this.props.patient.case_status || '',
      message: '',
      confirmed: '',
      isolation: this.props.patient.isolation,
      monitoring: this.props.patient.monitoring,
      monitoring_reason: this.props.patient.monitoring_reason,
      public_health_action: this.props.patient.public_health_action,
      apply_to_group: false,
    };
    this.toggleCaseStatusModal = this.toggleCaseStatusModal.bind(this);
    this.submit = this.submit.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  caseStatusTooltip() {
    return (
      <div>
        Used to move records into the appropriate workflow after investigating a report of symptoms. If an individual meets the <i>confirmed</i> or{' '}
        <i>probable</i> case definition, a user can choose to move the record to the isolation workflow or to end monitoring in Sara Alert. If the individual
        meets another case definition, the record will be returned to the appropriate exposure monitoring line list.
      </div>
    );
  }

  handleChange(event) {
    event.persist();
    this.setState({ [event.target.id]: event.target.type === 'checkbox' ? event.target.checked : event.target.value, showCaseStatusModal: true }, () => {
      if (event.target.id === 'confirmed') {
        if (event.target.value === 'End Monitoring') {
          this.setState({
            monitoring: false,
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

  toggleCaseStatusModal() {
    let current = this.state.showCaseStatusModal;
    this.setState({
      showCaseStatusModal: !current,
      case_status: this.props.patient.case_status || '',
    });
  }

  submit() {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
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
        location.href = window.BASE_PATH + '/patients/' + this.props.patient.id;
      })
      .catch(error => {
        reportError(error);
      });
  }

  createModal(title, toggle, submit) {
    if (this.state.case_status === 'Confirmed' || this.state.case_status === 'Probable') {
      return (
        <Modal size="lg" show centered>
          <Modal.Header>
            <Modal.Title>{title}</Modal.Title>
          </Modal.Header>
          <Modal.Body>
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
            {this.props.has_group_members && (
              <Form.Group className="mt-2">
                <Form.Check
                  type="switch"
                  id="apply_to_group"
                  label="Apply this change to the entire household that this monitoree is responsible for"
                  onChange={this.handleChange}
                  checked={this.state.apply_to_group === true || false}
                />
              </Form.Group>
            )}
          </Modal.Body>
          <Modal.Footer>
            <Button variant="primary btn-square" onClick={submit} disabled={this.state.confirmed === ''}>
              Submit
            </Button>
            <Button variant="secondary btn-square" onClick={toggle}>
              Cancel
            </Button>
          </Modal.Footer>
        </Modal>
      );
    } else if (
      this.state.case_status === 'Suspect' ||
      this.state.case_status === 'Unknown' ||
      this.state.case_status === 'Not a Case' ||
      this.state.case_status === ''
    ) {
      return (
        <Modal size="lg" show centered>
          <Modal.Header>
            <Modal.Title>{title}</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <p>This case will be moved from the PUI to symptomatic, non-reporting, or asymptomatic line list as appropriate to continue exposure monitoring.</p>
            {this.props.has_group_members && (
              <Form.Group className="mt-2">
                <Form.Check
                  type="switch"
                  id="apply_to_group"
                  label="Apply this change to the entire household that this monitoree is responsible for"
                  onChange={this.handleChange}
                  checked={this.state.apply_to_group === true || false}
                />
              </Form.Group>
            )}
          </Modal.Body>
          <Modal.Footer>
            <Button variant="primary btn-square" onClick={submit}>
              Submit
            </Button>
            <Button variant="secondary btn-square" onClick={toggle}>
              Cancel
            </Button>
          </Modal.Footer>
        </Modal>
      );
    }
  }

  render() {
    return (
      <React.Fragment>
        <div className="disabled">
          <Form.Label className="nav-input-label">
            CASE STATUS
            <InfoTooltip tooltipText={this.caseStatusTooltip()} location="right"></InfoTooltip>
          </Form.Label>
          <Form.Control as="select" className="form-control-lg" id="case_status" onChange={this.handleChange} value={this.state.case_status}>
            <option></option>
            <option>Confirmed</option>
            <option>Probable</option>
            <option>Suspect</option>
            <option>Unknown</option>
            <option>Not a Case</option>
          </Form.Control>
        </div>
        {this.state.showCaseStatusModal && this.createModal('Case Status', this.toggleCaseStatusModal, this.submit)}
      </React.Fragment>
    );
  }
}

CaseStatus.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  has_group_members: PropTypes.bool,
};

export default CaseStatus;
