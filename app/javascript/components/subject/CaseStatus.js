import React from 'react';
import { Button, Modal, Form } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import reportError from '../util/ReportError';
import InfoTooltip from '../util/InfoTooltip';
import _ from 'lodash';

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
      loading: false,
    };
    this.origState = Object.assign({}, this.state);
    this.toggleCaseStatusModal = this.toggleCaseStatusModal.bind(this);
    this.submit = this.submit.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(event) {
    event.persist();

    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let hideModal = this.state.isolation && (value === 'Confirmed' || value === 'Probable');

    this.setState({ [event.target.id]: value, showCaseStatusModal: !hideModal }, () => {
      // specific case where case status is just changed with no modal
      if (hideModal) {
        this.setState({ message: 'case status to "' + this.state.case_status + '".' });
        this.submit();
      }

      // all other cases
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
    let diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    diffState.push('public_health_action'); // force last public health action to update

    this.setState({ loading: true }, () => {
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
          diffState: diffState,
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  }

  createModal(title, toggle, submit) {
    if (
      this.props.patient.isolation &&
      (this.props.patient.case_status === 'Confirmed' || this.props.patient.case_status === 'Probable') &&
      (this.state.case_status === 'Suspect' || this.state.case_status === 'Unknown' || this.state.case_status === 'Not a Case' || this.state.case_status === '')
    ) {
      return (
        <Modal size="lg" show centered onHide={toggle}>
          <Modal.Header>
            <Modal.Title>{title}</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <p>
              This case will be moved to the exposure workflow and will be placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate to
              continue exposure monitoring.
            </p>
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
    } else if (this.state.case_status === 'Confirmed' || this.state.case_status === 'Probable') {
      return (
        <Modal size="lg" show centered onHide={toggle}>
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
            <Button variant="secondary btn-square" onClick={toggle}>
              Cancel
            </Button>
            <Button variant="primary btn-square" onClick={submit} disabled={this.state.confirmed === '' || this.state.loading}>
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
    } else if (
      this.state.case_status === 'Suspect' ||
      this.state.case_status === 'Unknown' ||
      this.state.case_status === 'Not a Case' ||
      this.state.case_status === ''
    ) {
      return (
        <Modal size="lg" show centered onHide={toggle}>
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
  }

  render() {
    return (
      <React.Fragment>
        <div className="disabled">
          <Form.Label className="nav-input-label">
            CASE STATUS
            <InfoTooltip tooltipTextKey="caseStatus" location="right"></InfoTooltip>
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
