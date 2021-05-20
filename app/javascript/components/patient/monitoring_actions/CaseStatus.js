import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Modal, Form } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';
import ReactTooltip from 'react-tooltip';

import ApplyToHousehold from '../household/actions/ApplyToHousehold';
import InfoTooltip from '../../util/InfoTooltip';
import reportError from '../../util/ReportError';

const MAX_NOTES_LENGTH = 2000;

class CaseStatus extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showCaseStatusModal: false,
      showMonitoringDropdown: false,
      confirmedOrProbable: this.props.patient.case_status === 'Confirmed' || this.props.patient.case_status === 'Probable',
      case_status: this.props.patient.case_status || '',
      isolation: this.props.patient.isolation,
      modal_text: '',
      monitoring: this.props.patient.monitoring,
      monitoring_reason: this.props.patient.monitoring_reason,
      monitoring_option: '',
      apply_to_household: false,
      apply_to_household_ids: [],
      reasoning: '',
      loading: false,
      disabled: false,
      noMembersSelected: false,
      isolationWorkflowAvailable:
        -1 <
        props.available_workflows.findIndex(w => {
          if (w.name.toLowerCase() == 'isolation') return true;
        }),
    };
    this.origState = Object.assign({}, this.state);
  }

  handleCaseStatusChange = event => {
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    const confirmedOrProbable = value === 'Confirmed' || value === 'Probable';
    if (this.state.monitoring && !confirmedOrProbable) {
      this.setState({ monitoring_reason: '', reasoning: '' });
    }

    this.setState({ [event.target.id]: value, showCaseStatusModal: true, confirmedOrProbable }, () => {
      // changing case status of monitoree in the closed line list (either workflow)
      if (!this.props.patient.monitoring) {
        this.setState({
          modal_text: `Are you sure you want to change case status from ${this.props.patient.case_status || 'blank'} to ${
            value || 'blank'
          }? Since this record is on the Closed line list, updating this value will not move this record to another line list. If this individual should be actively monitored, please update the record’s Monitoring Status.`,
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
          modal_text: `Are you sure you want to change the case status from ${this.props.patient.case_status || 'blank'} to ${
            value || 'blank'
          }? The record will remain in the isolation workflow.`,
        });

        // changing case status to Confirmed or Probable (excluding case directly above)
      } else if (confirmedOrProbable) {
        this.setState({ disabled: true, showMonitoringDropdown: true });

        // changing case status to Unknown, Suspect or Not a Case in the isolation workflow (excluding changing from Confirmed or Probable)
      } else if (!confirmedOrProbable && this.state.isolation) {
        this.setState({
          isolation: false,
          modal_text: `The case status for the selected record will be updated to ${
            value || 'blank'
          } and moved to the appropriate line list in the Exposure Workflow.`,
        });

        // changing case status to Unknown, Suspect or Not a Case while on the PUI line list in the exposure workflow
      } else if (!confirmedOrProbable && !this.state.isolation && this.props.patient.public_health_action != 'None') {
        this.setState({
          isolation: false,
          modal_text: `Are you sure you want to change case status to "${
            value || 'blank'
          }"? The monitoree will be placed in the symptomatic, non-reporting, or asymptomatic line list as appropriate to continue exposure monitoring and the Latest Public Health Action will be set to "None".`,
        });
        // changing case status to Unknown, Suspect or Not a Case while not on the PUI line list in the exposure workflow
      } else if (!confirmedOrProbable && !this.state.isolation) {
        this.setState({
          isolation: false,
          modal_text: `The case status for the selected record will be updated to ${value || 'blank'}.`,
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

  handleApplyHouseholdChange = apply_to_household => {
    const noMembersSelected = apply_to_household && this.state.apply_to_household_ids.length === 0;
    this.setState({ apply_to_household, noMembersSelected });
  };

  handleApplyHouseholdIdsChange = apply_to_household_ids => {
    const noMembersSelected = this.state.apply_to_household && apply_to_household_ids.length === 0;
    this.setState({ apply_to_household_ids, noMembersSelected });
  };

  toggleCaseStatusModal = () => {
    const current = this.state.showCaseStatusModal;
    this.setState({
      showCaseStatusModal: !current,
      showMonitoringDropdown: false,
      confirmedOrProbable: this.props.patient.case_status === 'Confirmed' || this.props.patient.case_status === 'Probable',
      apply_to_household: false,
      apply_to_household_ids: [],
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
      // Per feedback, include the monitoring_reason in the reasoning text, as the user might not inlude any text
      let alreadyClosed = !this.props.patient.monitoring && !this.state.monitoring;
      let reasoning = this.state.isolation || alreadyClosed ? '' : [this.state.monitoring_reason, this.state.reasoning].filter(x => x).join(', ');
      // Add a period at the end of the Reasoning (if it's not already included)
      if (reasoning && !['.', '!', '?'].includes(_.last(reasoning))) {
        reasoning += '.';
      }
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          case_status: this.state.case_status,
          isolation: this.state.isolation,
          monitoring: this.state.monitoring,
          monitoring_reason: this.state.monitoring_reason,
          reasoning,
          apply_to_household: this.state.apply_to_household,
          apply_to_household_ids: this.state.apply_to_household_ids,
          diffState: diffState,
        })
        .then(() => {
          location.reload();
        })
        .catch(err => {
          reportError(err?.response?.data?.error ? err.response.data.error : err, false);
        });
    });
  };

  handleChange = event => {
    event.persist();
    this.setState({ [`${event.target.id}`]: event.target.value });
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
                {this.state.isolationWorkflowAvailable && <option>Continue Monitoring in Isolation Workflow</option>}
              </Form.Control>
            </React.Fragment>
          )}
          {this.state.modal_text !== '' && <p>{this.state.modal_text}</p>}
          {this.state.monitoring_option === 'End Monitoring' && (
            <div>
              <Form.Group controlId="monitoring_reason">
                <Form.Label>Please select reason for status change:</Form.Label>
                <Form.Control as="select" size="lg" className="form-square" onChange={this.handleChange} defaultValue={'Meets Case Definition'}>
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
          )}
          {this.props.household_members.length > 0 && (
            <ApplyToHousehold
              household_members={this.props.household_members}
              current_user={this.props.current_user}
              jurisdiction_paths={this.props.jurisdiction_paths}
              handleApplyHouseholdChange={this.handleApplyHouseholdChange}
              handleApplyHouseholdIdsChange={this.handleApplyHouseholdIdsChange}
              workflow={this.props.workflow}
              continuous_exposure_enabled={this.props.continuous_exposure_enabled}
            />
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.disabled || this.state.loading || this.state.noMembersSelected}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            <span data-for="case-status-submit" data-tip="">
              Submit
            </span>
            {this.state.noMembersSelected && (
              <ReactTooltip id="case-status-submit" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
                <div>Please select at least one household member or change your selection to apply to this monitoree only</div>
              </ReactTooltip>
            )}
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <div className="disabled">
          <Form.Label htmlFor="case_status" className="input-label">
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
  household_members: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  monitoring_reasons: PropTypes.array,
  workflow: PropTypes.string,
  continuous_exposure_enabled: PropTypes.bool,
  available_workflows: PropTypes.array,
};

export default CaseStatus;
