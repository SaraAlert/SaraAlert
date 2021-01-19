import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Modal, Form } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';

import InfoTooltip from '../../util/InfoTooltip';
import reportError from '../../util/ReportError';

class CaseStatus extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showCaseStatusModal: false,
      showMonitoringDropdown: false,
      confirmedOrProbable: this.props.patient.case_status === 'Confirmed' || this.props.patient.case_status === 'Probable',
      case_status: this.props.patient.case_status || '',
      disabled: false,
      isolation: this.props.patient.isolation,
      modal_text: '',
      monitoring: this.props.patient.monitoring,
      monitoring_reason: this.props.patient.monitoring_reason,
      monitoring_option: '',
      apply_to_household: false,
      loading: false,
    };
    this.origState = Object.assign({}, this.state);
  }

  handleCaseStatusChange = event => {
    event.persist();
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    const confirmedOrProbable = value === 'Confirmed' || value === 'Probable';

    this.setState({ [event.target.id]: value, showCaseStatusModal: true, confirmedOrProbable }, () => {
      // changing case status of monitoree in the closed line list (either workflow)
      if (!this.props.patient.monitoring) {
        this.setState({
          modal_text: `Are you sure you want to change case status from ${this.props.patient.case_status} to ${value ||
            'blank'}? Since this record is on the Closed line list, updating this value will not move this record to another line list. If this individual should be actively monitored, please update the record’s Monitoring Status.`,
        });

        // changing case status to blank from any other case status and either workflow
      } else if (value === '') {
        this.setState({
          modal_text: `Are you sure you want to change case status from ${this.props.patient.case_status} to blank? The monitoree will remain in the same workflow.`,
        });

        // changing case status to Unknown, Suspect or Not a Case from Confirmed or Probable in the isolation workflow
      } else if (
        this.state.isolation &&
        !confirmedOrProbable &&
        (this.props.patient.case_status === 'Confirmed' || this.props.patient.case_status === 'Probable')
      ) {
        this.setState({
          isolation: false,
          modal_text: `This case will be moved to the exposure workflow and will be placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate to continue exposure monitoring.`,
        });

        // changing case status to Confirmed from Probable or vice versa in the isolation workflow
      } else if (
        confirmedOrProbable &&
        (this.props.patient.case_status === 'Confirmed' || this.props.patient.case_status === 'Probable') &&
        this.state.isolation
      ) {
        this.setState({
          isolation: true,
          modal_text: `Are you sure you want to change the case status from ${this.props.patient.case_status} to ${value}? The record will remain in the isolation workflow.`,
        });

        // changing case status to Confirmed or Probable (excluding case directly above)
      } else if (confirmedOrProbable) {
        this.setState({ disabled: true, showMonitoringDropdown: true });

        // changing case status to Unknown, Suspect or Not a Case in the isolation workflow (excluding changing from Confirmed or Probable)
      } else if (!confirmedOrProbable && this.state.isolation) {
        this.setState({
          isolation: false,
          modal_text: `The case status for the selected record will be updated to ${value} and moved to the appropriate line list in the Exposure Workflow.`,
        });

        // changing case status to Unknown, Suspect or Not a Case while on the PUI line list in the exposure workflow
      } else if (!confirmedOrProbable && !this.state.isolation && this.props.patient.public_health_action != 'None') {
        this.setState({
          isolation: false,
          modal_text: `Are you sure you want to change case status to "${value}"? The monitoree will be placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate to continue exposure monitoring and the Latest Public Health Action will be set to "None".`,
        });
        // changing case status to Unknown, Suspect or Not a Case while not on the PUI line list in the exposure workflow
      } else if (!confirmedOrProbable && !this.state.isolation) {
        this.setState({
          isolation: false,
          modal_text: `The case status for the selected record will be updated to ${value}.`,
        });
      }
    });
  };

  handleMonitoringChange = event => {
    event.persist();
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;

    if (value === 'End Monitoring') {
      this.setState({
        disabled: false,
        isolation: this.props.patient.isolation,
        monitoring: false,
        monitoring_option: value,
        monitoring_reason: 'Meets Case Definition',
        modal_text: `The case status for the selected record will be updated to ${this.state.case_status} and moved to the closed line list in the current workflow.`,
      });
    } else if (event.target.value === 'Continue Monitoring in Isolation Workflow') {
      this.setState({
        disabled: false,
        isolation: true,
        monitoring: true,
        monitoring_option: value,
        monitoring_reason: 'Meets Case Definition',
        modal_text: `The case status for the selected record will be updated to ${this.state.case_status} and moved to the appropriate line list in the Isolation Workflow.`,
      });
    } else if (event.target.value === '') {
      this.setState({ monitoring_option: value, disabled: true, modal_text: '' });
    }
  };

  handleApplyHouseholdChange = event => {
    const applyToHousehold = event.target.id === 'apply_to_household_yes';
    this.setState({ apply_to_household: applyToHousehold });
  };

  toggleCaseStatusModal = () => {
    const current = this.state.showCaseStatusModal;
    this.setState({
      showCaseStatusModal: !current,
      showMonitoringDropdown: false,
      confirmedOrProbable: this.props.patient.case_status === 'Confirmed' || this.props.patient.case_status === 'Probable',
      apply_to_household: false,
      case_status: this.props.patient.case_status || '',
      disabled: false,
      isolation: this.props.patient.isolation,
      modal_text: '',
      monitoring: this.props.patient.monitoring,
      monitoring_reason: this.props.patient.monitoring_reason,
      monitoring_option: '',
    });
  };

  submit = () => {
    const diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          case_status: this.state.case_status,
          isolation: this.state.isolation,
          monitoring: this.state.monitoring,
          monitoring_reason: this.state.monitoring_reason,
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
          <Modal.Title>Case Status</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {this.state.showMonitoringDropdown && (
            <React.Fragment>
              <p>Please select what you would like to do:</p>
              <Form.Control
                as="select"
                className="form-control-lg mb-3"
                id="monitoring_option"
                onChange={this.handleMonitoringChange}
                value={this.state.monitoring_option}>
                <option></option>
                <option>End Monitoring</option>
                <option>Continue Monitoring in Isolation Workflow</option>
              </Form.Control>
            </React.Fragment>
          )}
          {this.state.modal_text !== '' && <p>{this.state.modal_text}</p>}
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
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.disabled || this.state.loading}>
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
          <Form.Label htmlFor="case_status" className="nav-input-label">
            CASE STATUS
            <InfoTooltip tooltipTextKey="caseStatus" location="right"></InfoTooltip>
          </Form.Label>
          <Form.Control
            as="select"
            className="form-control-lg"
            id="case_status"
            aria-label="Case Status Select"
            onChange={this.handleCaseStatusChange}
            value={this.state.case_status}>
            <option></option>
            <option>Confirmed</option>
            <option>Probable</option>
            <option>Suspect</option>
            <option>Unknown</option>
            <option>Not a Case</option>
          </Form.Control>
        </div>
        {this.state.showCaseStatusModal && this.createModal(this.toggleCaseStatusModal, this.submit)}
      </React.Fragment>
    );
  }
}

CaseStatus.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  has_dependents: PropTypes.bool,
};

export default CaseStatus;
