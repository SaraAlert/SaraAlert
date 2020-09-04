import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Row, Col, Button, Modal, Tooltip } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';
import moment from 'moment';

import CaseStatus from './CaseStatus';
import DateInput from '../util/DateInput';
import InfoTooltip from '../util/InfoTooltip';
import reportError from '../util/ReportError';

class MonitoringStatus extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      patient: props.patient,
      showExposureRiskAssessmentModal: false,
      showMonitoringPlanModal: false,
      showMonitoringStatusModal: false,
      showJurisdictionModal: false,
      showassignedUserModal: false,
      showPublicHealthActionModal: false,
      showIsolationModal: false,
      showNotificationsModal: false,
      message: '',
      reasoning: '',
      monitoring_status: props.patient.monitoring ? 'Actively Monitoring' : 'Not Monitoring',
      monitoring_plan: props.patient.monitoring_plan ? props.patient.monitoring_plan : '',
      exposure_risk_assessment: props.patient.exposure_risk_assessment ? props.patient.exposure_risk_assessment : '',
      jurisdiction_path: this.props.jurisdictionPaths[this.props.patient.jurisdiction_id],
      original_jurisdiction_id: this.props.patient.jurisdiction_id,
      validJurisdiction: true,
      assigned_user: props.patient.assigned_user ? props.patient.assigned_user : '',
      original_assigned_user: props.patient.assigned_user ? props.patient.assigned_user : '',
      monitoring_reasons: null,
      monitoring_reason: props.patient.monitoring_reason ? props.patient.monitoring_reason : '',
      public_health_action: props.patient.public_health_action ? props.patient.public_health_action : '',
      apply_to_group: false,
      isolation: props.patient.isolation,
      isolation_status: props.patient.isolation ? 'Isolation' : 'Exposure',
      pause_notifications: props.patient.pause_notifications,
      loading: false,
      apply_to_group_cm_only: false,
      apply_to_group_cm_only_date: moment(new Date()).format('YYYY-MM-DD'),
    };
    this.origState = Object.assign({}, this.state);
    this.handleChange = this.handleChange.bind(this);
    this.handleKeyPress = this.handleKeyPress.bind(this);
    this.submit = this.submit.bind(this);
    this.toggleMonitoringStatusModal = this.toggleMonitoringStatusModal.bind(this);
    this.toggleMonitoringPlanModal = this.toggleMonitoringPlanModal.bind(this);
    this.toggleExposureRiskAssessmentModal = this.toggleExposureRiskAssessmentModal.bind(this);
    this.toggleJurisdictionModal = this.toggleJurisdictionModal.bind(this);
    this.toggleAssignedUserModal = this.toggleAssignedUserModal.bind(this);
    this.togglePublicHealthAction = this.togglePublicHealthAction.bind(this);
    this.toggleIsolation = this.toggleIsolation.bind(this);
    this.toggleNotifications = this.toggleNotifications.bind(this);
  }

  handleChange(event) {
    if (event?.target?.name && event.target.name === 'jurisdictionId') {
      // Jurisdiction is a weird case; the datalist and input work differently together
      this.setState({
        message: 'jurisdiction from "' + this.props.jurisdictionPaths[this.state.original_jurisdiction_id] + '" to "' + event.target.value + '".',
        message_warning: this.state.assigned_user === '' ? '' : 'Please also consider removing or updating the assigned user if it is no longer applicable.',
        jurisdiction_path: event?.target?.value ? event.target.value : '',
        monitoring_reasons: null,
        validJurisdiction: Object.values(this.props.jurisdictionPaths).includes(event.target.value),
      });
    } else if (event?.target?.name && event.target.name === 'assignedUser') {
      if (
        event?.target?.value === '' ||
        (event?.target?.value && !isNaN(event.target.value) && parseInt(event.target.value) > 0 && parseInt(event.target.value) <= 9999)
      ) {
        this.setState({
          message: 'assigned user from "' + this.state.original_assigned_user + '"to"' + event.target.value + '".',
          message_warning: '',
          assigned_user: event?.target?.value ? parseInt(event.target.value) : '',
          monitoring_reasons: null,
        });
      }
    } else if (event?.target?.id && event.target.id === 'exposure_risk_assessment') {
      this.setState({
        showExposureRiskAssessmentModal: true,
        message: 'exposure risk assessment to "' + event.target.value + '".',
        message_warning: '',
        exposure_risk_assessment: event?.target?.value ? event.target.value : '',
        monitoring_reasons: null,
      });
    } else if (event?.target?.id && event.target.id === 'monitoring_plan') {
      this.setState({
        showMonitoringPlanModal: true,
        message: 'monitoring plan to "' + event.target.value + '".',
        message_warning: '',
        monitoring_plan: event?.target?.value ? event.target.value : '',
        monitoring_reasons: null,
      });
    } else if (event?.target?.id && event.target.id === 'pause_notifications') {
      this.setState({
        showNotificationsModal: true,
        message: 'notification status to ' + (!this.state.pause_notifications ? 'paused.' : 'resumed.'),
        message_warning: '',
        pause_notifications: !this.state.pause_notifications,
        monitoring_reasons: null,
      });
    } else if (event?.target?.id && event.target.id === 'public_health_action') {
      if (this.state.patient.isolation) {
        this.setState({
          showPublicHealthActionModal: true,
          message: 'latest public health action to "' + event.target.value + '".',
          message_warning:
            'The monitoree will be moved to the "Records Requiring Review" line list if they meet a recovery definition or will remain on the "Reporting" or "Non-Reporting" line list as appropriate until a recovery definition is met.',
          public_health_action: event?.target?.value ? event.target.value : '',
          monitoring_reasons: null,
        });
      } else {
        this.setState({
          showPublicHealthActionModal: true,
          message: 'latest public health action to "' + event.target.value + '".',
          message_warning:
            event.target.value === 'None'
              ? 'The monitoree will be moved back into the primary status line lists.'
              : 'The monitoree will be moved into the PUI line list.',
          public_health_action: event?.target?.value ? event.target.value : '',
          monitoring_reasons: null,
        });
      }
    } else if (event?.target?.id && event.target.id === 'isolation_status') {
      this.setState({
        showIsolationModal: true,
        message: 'workflow from the "' + this.state.isolation_status + '" workflow to the "' + event.target.value + '" workflow.',
        message_warning:
          event.target.value === 'Isolation'
            ? 'This should only be done for cases you wish to monitor with Sara Alert to determine when they meet the recovery definition to discontinue isolation. The monitoree will be moved onto the Isolation workflow dashboard.'
            : 'The monitoree will be moved into the Exposure workflow.',
        isolation: event.target.value === 'Isolation',
        isolation_status: event.target.value,
        monitoring_reasons: null,
      });
    } else if (event?.target?.id && event.target.id === 'monitoring_status') {
      this.setState({
        showMonitoringStatusModal: true,
        message: 'monitoring status to "' + event.target.value + '".',
        message_warning: event.target.value === 'Not Monitoring' ? 'This record will be moved to the closed line list.' : '',
        monitoring: event.target.value === 'Actively Monitoring' ? true : false,
        monitoring_status: event?.target?.value ? event.target.value : '',
        monitoring_reasons:
          event.target.value === 'Not Monitoring'
            ? [
                'Completed Monitoring',
                'Meets Case Definition',
                'Lost to follow-up during monitoring period',
                'Lost to follow-up (contact never established)',
                'Transferred to another jurisdiction',
                'Person Under Investigation (PUI)',
                'Case confirmed',
                'Meets criteria to discontinue isolation',
                'Deceased',
                'Duplicate',
                'Other',
              ]
            : null,
      });
    } else if (event?.target?.id) {
      let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
      this.setState({ [event.target.id]: event?.target?.value ? value : '' });
    }
  }

  handleKeyPress() {
    if (event.which === 13) {
      if (event?.target?.name && event.target.name === 'jurisdictionId') {
        event.preventDefault();
        this.toggleJurisdictionModal();
      } else if (event?.target?.name && event.target.name === 'assignedUser') {
        event.preventDefault();
        this.toggleAssignedUserModal();
      }
    }
  }

  toggleMonitoringStatusModal() {
    let current = this.state.showMonitoringStatusModal;
    this.setState({
      showMonitoringStatusModal: !current,
      monitoring_status: this.props.patient.monitoring ? 'Actively Monitoring' : 'Not Monitoring',
      apply_to_group: false,
      reasoning: '',
    });
  }

  toggleNotifications() {
    let current = this.state.showNotificationsModal;
    this.setState({
      showNotificationsModal: !current,
      pause_notifications: this.props.patient.pause_notifications,
      apply_to_group: false,
      reasoning: '',
    });
  }

  toggleMonitoringPlanModal() {
    let current = this.state.showMonitoringPlanModal;
    this.setState({
      showMonitoringPlanModal: !current,
      monitoring_plan: this.props.patient.monitoring_plan ? this.props.patient.monitoring_plan : '',
      apply_to_group: false,
      reasoning: '',
    });
  }

  toggleExposureRiskAssessmentModal() {
    let current = this.state.showExposureRiskAssessmentModal;
    this.setState({
      showExposureRiskAssessmentModal: !current,
      exposure_risk_assessment: this.props.patient.exposure_risk_assessment ? this.props.patient.exposure_risk_assessment : '',
      apply_to_group: false,
      reasoning: '',
    });
  }

  toggleJurisdictionModal() {
    let current = this.state.showJurisdictionModal;
    this.setState({
      message: 'jurisdiction from "' + this.props.jurisdictionPaths[this.state.original_jurisdiction_id] + '" to "' + this.state.jurisdiction_path + '".',
      showJurisdictionModal: !current,
      jurisdiction_path: current ? this.props.jurisdictionPaths[this.state.original_jurisdiction_id] : this.state.jurisdiction_path,
      apply_to_group: false,
      reasoning: '',
    });
  }

  toggleAssignedUserModal() {
    let current = this.state.showassignedUserModal;
    this.setState({
      message: 'assigned user from "' + this.state.original_assigned_user + '" to "' + this.state.assigned_user + '".',
      showassignedUserModal: !current,
      assigned_user: current ? this.state.original_assigned_user : this.state.assigned_user,
      apply_to_group: false,
      reasoning: '',
    });
  }

  togglePublicHealthAction() {
    let current = this.state.showPublicHealthActionModal;
    this.setState({
      showPublicHealthActionModal: !current,
      public_health_action: this.props.patient.public_health_action ? this.props.patient.public_health_action : '',
      apply_to_group: false,
      reasoning: '',
    });
  }

  toggleIsolation() {
    let current = this.state.showIsolationModal;
    this.setState({
      showIsolationModal: !current,
      isolation: this.props.patient.isolation ? this.props.patient.isolation : false,
      isolation_status: this.props.patient.isolation ? 'Isolation' : 'Exposure',
      apply_to_group: false,
      reasoning: '',
    });
  }

  submit() {
    let diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          comment: true,
          monitoring: this.state.monitoring_status === 'Actively Monitoring' ? true : false,
          exposure_risk_assessment: this.state.exposure_risk_assessment,
          monitoring_plan: this.state.monitoring_plan,
          public_health_action: this.state.public_health_action,
          message: this.state.message,
          reasoning:
            (this.state.showMonitoringStatusModal && this.state.monitoring_status === 'Not Monitoring'
              ? this.state.monitoring_reason + (this.state.reasoning !== '' ? ', ' : '')
              : '') + this.state.reasoning,
          monitoring_reason: this.state.monitoring_status === 'Not Monitoring' ? this.state.monitoring_reason : null,
          jurisdiction: Object.keys(this.props.jurisdictionPaths).find(id => this.props.jurisdictionPaths[parseInt(id)] === this.state.jurisdiction_path),
          assigned_user: this.state.assigned_user,
          apply_to_group: this.state.apply_to_group,
          isolation: this.state.isolation,
          pause_notifications: this.state.pause_notifications,
          diffState: diffState,
          apply_to_group_cm_only: this.state.apply_to_group_cm_only,
          apply_to_group_cm_only_date: this.state.apply_to_group_cm_only_date,
        })
        .then(() => {
          if (diffState.includes('jurisdiction_path')) {
            const currentUserJurisdictionString = this.props.current_user_jurisdiction_path.join(', ');
            // check if current_user has access to the changed jurisdiction
            // if so, reload the page, if not, redirect to exposure or isolation dashboard
            if (!this.state.jurisdiction_path.startsWith(currentUserJurisdictionString)) {
              const pathEnd = this.state.isolation ? '/isolation' : '';
              location.assign((window.BASE_PATH ? window.BASE_PATH : '') + '/public_health' + pathEnd);
            } else {
              location.reload(true);
            }
          } else {
            location.reload(true);
          }
        })
        .catch(error => {
          reportError(error);
        });
    });
  }

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered onHide={toggle}>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            You are about to change this monitoree&apos;s {this.state.message} {this.state.message_warning && <b>{this.state.message_warning}</b>}
          </p>
          {this.state.monitoring_reasons && (
            <Form.Group>
              <Form.Label>Please select reason for status change:</Form.Label>
              <Form.Control as="select" size="lg" className="form-square" id="monitoring_reason" onChange={this.handleChange} defaultValue={-1}>
                <option value={-1} disabled>
                  --
                </option>
                {this.state.monitoring_reasons.map((option, index) => (
                  <option key={`option-${index}`} value={option}>
                    {option}
                  </option>
                ))}
              </Form.Control>
            </Form.Group>
          )}
          {this.props.isolation && this.state.monitoring_reasons && this.props.in_a_group && (
            <Form.Group>
              <Form.Check
                type="switch"
                id="apply_to_group_cm_only"
                label='Update Last Date of Exposure for all household members with Continuous Exposure whose Monitoring Status is "Actively Monitoring" in the Exposure workflow'
                onChange={this.handleChange}
                checked={this.state.apply_to_group_cm_only === true || false}
              />
            </Form.Group>
          )}
          {this.props.isolation && this.state.monitoring_reasons && this.props.in_a_group && this.state.apply_to_group_cm_only && (
            <Form.Group>
              <Form.Label className="nav-input-label">LAST DATE OF EXPOSURE</Form.Label>
              <DateInput
                id="apply_to_group_cm_only_date"
                date={this.state.apply_to_group_cm_only_date}
                onChange={date => this.setState({ apply_to_group_cm_only_date: date })}
                placement="bottom"
              />
            </Form.Group>
          )}
          <Form.Group>
            <Form.Label>Please include any additional details:</Form.Label>
            <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleChange} />
          </Form.Group>
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
          {this.state.monitoring_reasons && !this.state.monitoring_reason ? (
            <Button variant="primary btn-square" disabled>
              Submit
            </Button>
          ) : (
            <Button variant="primary btn-square" onClick={submit} disabled={this.state.loading}>
              {this.state.loading && (
                <React.Fragment>
                  <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
                </React.Fragment>
              )}
              Submit
            </Button>
          )}
        </Modal.Footer>
      </Modal>
    );
  }

  renderPHARefreshTooltip(props) {
    return (
      <Tooltip id="button-tooltip" {...props}>
        {this.state.public_health_action === 'None' && <span>You can&apos;t add an additional &quot;None&quot; public health action.</span>}
        {this.state.public_health_action != 'None' && <span>Add an additional &quot;{this.state.public_health_action}&quot; public health action.</span>}
      </Tooltip>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Form className="mb-3 mt-3 px-4">
          <Row>
            <Col>
              <Form.Row className="align-items-end">
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <Form.Label className="nav-input-label">
                    MONITORING STATUS
                    <InfoTooltip tooltipTextKey="monitoringStatus" location="right"></InfoTooltip>
                  </Form.Label>
                  <Form.Control
                    as="select"
                    className="form-control-lg"
                    id="monitoring_status"
                    onChange={this.handleChange}
                    value={this.state.monitoring_status}>
                    <option>Actively Monitoring</option>
                    <option>Not Monitoring</option>
                  </Form.Control>
                </Form.Group>
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <Form.Label className="nav-input-label">
                    EXPOSURE RISK ASSESSMENT
                    <InfoTooltip tooltipTextKey="exposureRiskAssessment" location="right"></InfoTooltip>
                  </Form.Label>
                  <Form.Control
                    as="select"
                    className="form-control-lg"
                    id="exposure_risk_assessment"
                    onChange={this.handleChange}
                    value={this.state.exposure_risk_assessment}>
                    <option disabled></option>
                    <option>High</option>
                    <option>Medium</option>
                    <option>Low</option>
                    <option>No Identified Risk</option>
                  </Form.Control>
                </Form.Group>
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <Form.Label className="nav-input-label">
                    MONITORING PLAN
                    <InfoTooltip tooltipTextKey="monitoringPlan" location="right"></InfoTooltip>
                  </Form.Label>
                  <Form.Control as="select" className="form-control-lg" id="monitoring_plan" onChange={this.handleChange} value={this.state.monitoring_plan}>
                    <option>None</option>
                    <option>Daily active monitoring</option>
                    <option>Self-monitoring with public health supervision</option>
                    <option>Self-monitoring with delegated supervision</option>
                    <option>Self-observation</option>
                  </Form.Control>
                </Form.Group>
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <CaseStatus
                    patient={this.props.patient}
                    authenticity_token={this.props.authenticity_token}
                    has_group_members={this.props.has_group_members}
                  />
                </Form.Group>
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <Form.Label className="nav-input-label">
                    LATEST PUBLIC HEALTH ACTION
                    <InfoTooltip tooltipTextKey="latestPublicHealthAction" location="right"></InfoTooltip>
                  </Form.Label>
                  <Form.Control
                    as="select"
                    className="form-control-lg"
                    id="public_health_action"
                    onChange={this.handleChange}
                    value={this.state.public_health_action}>
                    <option>None</option>
                    <option>Recommended medical evaluation of symptoms</option>
                    <option>Document results of medical evaluation</option>
                    <option>Recommended laboratory testing</option>
                  </Form.Control>
                </Form.Group>
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <Form.Label className="nav-input-label">
                    ASSIGNED USER
                    <InfoTooltip tooltipTextKey="assignedUser" location="right"></InfoTooltip>
                  </Form.Label>
                  <Form.Group className="d-flex mb-0">
                    <Form.Control
                      as="input"
                      name="assignedUser"
                      list="assignedUsers"
                      autoComplete="off"
                      className="form-control-lg"
                      onChange={this.handleChange}
                      onKeyPress={this.handleKeyPress}
                      value={this.state.assigned_user}
                    />
                    <datalist id="assignedUsers">
                      {this.props.assignedUsers.map(num => {
                        return (
                          <option value={num} key={num}>
                            {num}
                          </option>
                        );
                      })}
                    </datalist>
                    {this.state.assigned_user === this.state.original_assigned_user ? (
                      <Button className="btn-lg btn-square text-nowrap ml-2" disabled>
                        <i className="fas fa-users"></i> Change User
                      </Button>
                    ) : (
                      <Button className="btn-lg btn-square text-nowrap ml-2" onClick={this.toggleAssignedUserModal}>
                        <i className="fas fa-users"></i> Change User
                      </Button>
                    )}
                  </Form.Group>
                </Form.Group>
                <Form.Group as={Col} lg="24" className="pt-2">
                  <Form.Label className="nav-input-label">
                    ASSIGNED JURISDICTION
                    <InfoTooltip tooltipTextKey="assignedJurisdiction" location="right"></InfoTooltip>
                  </Form.Label>
                  <Form.Group className="d-flex mb-0">
                    <Form.Control
                      as="input"
                      name="jurisdictionId"
                      list="jurisdictionPaths"
                      autoComplete="off"
                      className="form-control-lg"
                      onChange={this.handleChange}
                      onKeyPress={this.handleKeyPress}
                      value={this.state.jurisdiction_path}
                    />
                    <datalist id="jurisdictionPaths">
                      {Object.entries(this.props.jurisdictionPaths).map(([id, path]) => {
                        return (
                          <option value={path} key={id}>
                            {path}
                          </option>
                        );
                      })}
                    </datalist>
                    {!this.state.validJurisdiction || this.state.jurisdiction_path === this.props.jurisdictionPaths[this.state.original_jurisdiction_id] ? (
                      <Button className="btn-lg btn-square text-nowrap ml-2" disabled>
                        <i className="fas fa-map-marked-alt"></i> Change Jurisdiction
                      </Button>
                    ) : (
                      <Button className="btn-lg btn-square text-nowrap ml-2" onClick={this.toggleJurisdictionModal}>
                        <i className="fas fa-map-marked-alt"></i> Change Jurisdiction
                      </Button>
                    )}
                  </Form.Group>
                </Form.Group>
              </Form.Row>
            </Col>
          </Row>
        </Form>
        {this.state.showMonitoringStatusModal && this.createModal('Monitoring Status', this.toggleMonitoringStatusModal, this.submit)}
        {this.state.showMonitoringPlanModal && this.createModal('Monitoring Plan', this.toggleMonitoringPlanModal, this.submit)}
        {this.state.showExposureRiskAssessmentModal && this.createModal('Exposure Risk Assessment', this.toggleExposureRiskAssessmentModal, this.submit)}
        {this.state.showJurisdictionModal && this.createModal('Jurisdiction', this.toggleJurisdictionModal, this.submit)}
        {this.state.showassignedUserModal && this.createModal('Assigned User', this.toggleAssignedUserModal, this.submit)}
        {this.state.showPublicHealthActionModal && this.createModal('Public Health Action', this.togglePublicHealthAction, this.submit)}
        {this.state.showIsolationModal && this.createModal('Isolation', this.toggleIsolation, this.submit)}
        {this.state.showNotificationsModal && this.createModal('Notifications', this.toggleNotifications, this.submit)}
      </React.Fragment>
    );
  }
}

MonitoringStatus.propTypes = {
  current_user_jurisdiction_path: PropTypes.array,
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  jurisdictionPaths: PropTypes.object,
  assignedUsers: PropTypes.array,
  has_group_members: PropTypes.bool,
  in_a_group: PropTypes.bool,
  isolation: PropTypes.bool,
};

export default MonitoringStatus;
