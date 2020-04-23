import React from 'react';
import { Form, Row, Col, Button, Modal, Tooltip, OverlayTrigger } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';

class MonitoringStatus extends React.Component {
  constructor(props) {
    super(props);
    const jur = this.props.jurisdiction_paths.find(jur => jur.value === props.jurisdiction_id);
    this.state = {
      patient: props.patient,
      showExposureRiskAssessmentModal: false,
      showMonitoringPlanModal: false,
      showMonitoringStatusModal: false,
      showJurisdictionModal: false,
      showPublicHealthActionModal: false,
      showIsolationModal: false,
      showNotificationsModal: false,
      message: '',
      reasoning: '',
      monitoring_status: props.patient.monitoring ? 'Actively Monitoring' : 'Not Monitoring',
      monitoring_plan: props.patient.monitoring_plan ? props.patient.monitoring_plan : '',
      exposure_risk_assessment: props.patient.exposure_risk_assessment ? props.patient.exposure_risk_assessment : '',
      jurisdiction: jur ? jur.label : '',
      current_jurisdiction: jur ? jur.label : '', // Used to remember jur on page load in case user cancels change modal
      valid_jurisdiction: true,
      monitoring_status_options: null,
      monitoring_status_option: props.patient.monitoring_reason ? props.patient.monitoring_reason : '',
      public_health_action: props.patient.public_health_action ? props.patient.public_health_action : '',
      apply_to_group: false,
      isolation: props.patient.isolation,
      isolation_status: props.patient.isolation ? 'Isolation' : 'Exposure',
      pause_notifications: props.patient.pause_notifications,
    };
    this.handleChange = this.handleChange.bind(this);
    this.handleKeyPress = this.handleKeyPress.bind(this);
    this.submit = this.submit.bind(this);
    this.toggleMonitoringStatusModal = this.toggleMonitoringStatusModal.bind(this);
    this.toggleMonitoringPlanModal = this.toggleMonitoringPlanModal.bind(this);
    this.toggleExposureRiskAssessmentModal = this.toggleExposureRiskAssessmentModal.bind(this);
    this.toggleJurisdictionModal = this.toggleJurisdictionModal.bind(this);
    this.togglePublicHealthAction = this.togglePublicHealthAction.bind(this);
    this.toggleIsolation = this.toggleIsolation.bind(this);
    this.toggleNotifications = this.toggleNotifications.bind(this);
    this.publicHealthActionRefresh = this.publicHealthActionRefresh.bind(this);
    this.renderPHARefreshTooltip = this.renderPHARefreshTooltip.bind(this);
  }

  handleChange(event) {
    if (event?.target?.name && event.target.name === 'jurisdictionList') {
      // Jurisdiction is a weird case; the datalist and input work differently together
      this.setState({
        message: 'jurisdiction from "' + this.state.current_jurisdiction + '" to "' + event.target.value + '".',
        message_warning: '',
        jurisdiction: event?.target?.value ? event.target.value : '',
        monitoring_status_options: null,
        valid_jurisdiction: this.props.jurisdiction_paths.map(jur => jur.label).includes(event.target.value),
      });
    } else if (event?.target?.id && event.target.id === 'exposure_risk_assessment') {
      this.setState({
        showExposureRiskAssessmentModal: true,
        message: 'exposure risk assessment to "' + event.target.value + '".',
        message_warning: '',
        exposure_risk_assessment: event?.target?.value ? event.target.value : '',
        monitoring_status_options: null,
      });
    } else if (event?.target?.id && event.target.id === 'monitoring_plan') {
      this.setState({
        showMonitoringPlanModal: true,
        message: 'monitoring plan to "' + event.target.value + '".',
        message_warning: '',
        monitoring_plan: event?.target?.value ? event.target.value : '',
        monitoring_status_options: null,
      });
    } else if (event?.target?.id && event.target.id === 'pause_notifications') {
      this.setState({
        showNotificationsModal: true,
        message: 'notification status to ' + (!this.state.pause_notifications ? 'paused.' : 'resumed.'),
        message_warning: '',
        pause_notifications: !this.state.pause_notifications,
        monitoring_status_options: null,
      });
    } else if (event?.target?.id && event.target.id === 'public_health_action') {
      if (this.state.patient.isolation) {
        this.setState({
          showPublicHealthActionModal: true,
          message: 'latest public health action to "' + event.target.value + '".',
          message_warning:
            'The monitoree will be moved to the "Records Requiring Review" line list if they meet a recovery definition or will remain on the "Reporting" or "Non-Reporting" line list as appropriate until a recovery definition is met.',
          public_health_action: event?.target?.value ? event.target.value : '',
          monitoring_status_options: null,
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
          monitoring_status_options: null,
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
        monitoring_status_options: null,
      });
    } else if (event?.target?.id && event.target.id === 'monitoring_status') {
      this.setState({
        showMonitoringStatusModal: true,
        message: 'monitoring status to "' + event.target.value + '".',
        message_warning: event.target.value === 'Not Monitoring' ? 'This record will be moved to the closed line list.' : '',
        monitoring_status: event?.target?.value ? event.target.value : '',
        monitoring_status_options:
          event.target.value === 'Not Monitoring'
            ? [
                'Completed Monitoring',
                'Lost to follow-up during monitoring period',
                'Lost to follow-up (contact never established)',
                'Transferred to another jurisdiction',
                'Person Under Investigation (PUI)',
                'Case confirmed',
                'Meets criteria to discontinue isolation',
                'Deceased',
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
    if (event?.target?.name && event.target.name === 'jurisdictionList') {
      if (event.which === 13) {
        event.preventDefault();
        this.toggleJurisdictionModal();
      }
    }
  }

  toggleMonitoringStatusModal() {
    let current = this.state.showMonitoringStatusModal;
    this.setState({
      showMonitoringStatusModal: !current,
      monitoring_status: this.props.patient.monitoring ? 'Actively Monitoring' : 'Not Monitoring',
      apply_to_group: false,
    });
  }

  toggleNotifications() {
    let current = this.state.showNotificationsModal;
    this.setState({
      showNotificationsModal: !current,
      pause_notifications: this.props.patient.pause_notifications,
      apply_to_group: false,
    });
  }

  toggleMonitoringPlanModal() {
    let current = this.state.showMonitoringPlanModal;
    this.setState({
      showMonitoringPlanModal: !current,
      monitoring_plan: this.props.patient.monitoring_plan ? this.props.patient.monitoring_plan : '',
      apply_to_group: false,
    });
  }

  toggleExposureRiskAssessmentModal() {
    let current = this.state.showExposureRiskAssessmentModal;
    this.setState({
      showExposureRiskAssessmentModal: !current,
      exposure_risk_assessment: this.props.patient.exposure_risk_assessment ? this.props.patient.exposure_risk_assessment : '',
      apply_to_group: false,
    });
  }

  toggleJurisdictionModal() {
    let current = this.state.showJurisdictionModal;
    this.setState({
      message: 'jurisdiction from "' + this.state.current_jurisdiction + '" to "' + this.state.jurisdiction + '".',
      showJurisdictionModal: !current,
      jurisdiction: current ? this.state.current_jurisdiction : this.state.jurisdiction, // Reset select jurisdiction if cancel
      apply_to_group: false,
    });
  }

  togglePublicHealthAction() {
    let current = this.state.showPublicHealthActionModal;
    this.setState({
      showPublicHealthActionModal: !current,
      public_health_action: this.props.patient.public_health_action ? this.props.patient.public_health_action : '',
      apply_to_group: false,
    });
  }

  toggleIsolation() {
    let current = this.state.showIsolationModal;
    this.setState({
      showIsolationModal: !current,
      isolation: this.props.patient.isolation ? this.props.patient.isolation : false,
      isolation_status: this.props.patient.isolation ? 'Isolation' : 'Exposure',
      apply_to_group: false,
    });
  }

  submit() {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    const jur = this.props.jurisdiction_paths.find(jur => jur.label === this.state.jurisdiction);
    axios
      .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
        comment: true,
        monitoring: this.state.monitoring_status === 'Actively Monitoring' ? true : false,
        exposure_risk_assessment: this.state.exposure_risk_assessment,
        monitoring_plan: this.state.monitoring_plan,
        public_health_action: this.state.public_health_action,
        message: this.state.message,
        reasoning: (this.state.monitoring_status_option ? this.state.monitoring_status_option + (this.state.reasoning ? ', ' : '') : '') + this.state.reasoning,
        monitoring_reason: this.state.monitoring_status === 'Not Monitoring' ? this.state.monitoring_status_option : null,
        jurisdiction: jur ? jur.value : null,
        apply_to_group: this.state.apply_to_group,
        isolation: this.state.isolation,
        pause_notifications: this.state.pause_notifications,
      })
      .then(() => {
        location.href = window.BASE_PATH + '/patients/' + this.props.patient.id;
      })
      .catch(error => {
        console.error(error);
      });
  }

  publicHealthActionRefresh() {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(window.BASE_PATH + '/histories', {
        patient_id: this.props.patient.id,
        type: 'Monitoring Change',
        comment: 'User added an additional public health action: "' + this.state.public_health_action + '".',
      })
      .then(() => {
        location.href = window.BASE_PATH + '/patients/' + this.props.patient.id;
      })
      .catch(error => {
        console.error(error);
      });
  }

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            You are about to change this monitoree&apos;s {this.state.message} {this.state.message_warning && <b>{this.state.message_warning}</b>}
          </p>
          {this.state.monitoring_status_options && (
            <Form.Group>
              <Form.Label>Please select reason for status change:</Form.Label>
              <Form.Control as="select" size="lg" className="form-square" id="monitoring_status_option" onChange={this.handleChange}>
                <option disabled selected value></option>
                {this.state.monitoring_status_options.map((option, index) => (
                  <option key={`option-${index}`} value={option}>
                    {option}
                  </option>
                ))}
              </Form.Control>
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
          {this.state.monitoring_status_options && !this.state.monitoring_status_option ? (
            <Button variant="primary btn-square" disabled>
              Submit
            </Button>
          ) : (
            <Button variant="primary btn-square" onClick={submit}>
              Submit
            </Button>
          )}
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
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
        <Form className="mb-3 mt-3 pt-2 px-4">
          <Row>
            <Col>
              <Form.Row>
                <Form.Group as={Col}>
                  <Form.Label className="nav-input-label">MONITORING STATUS</Form.Label>
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
                <Form.Group as={Col}>
                  <Form.Label className="nav-input-label">EXPOSURE RISK ASSESSMENT</Form.Label>
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
                <Form.Group as={Col}>
                  <Form.Label className="nav-input-label">MONITORING PLAN</Form.Label>
                  <Form.Control as="select" className="form-control-lg" id="monitoring_plan" onChange={this.handleChange} value={this.state.monitoring_plan}>
                    <option>None</option>
                    <option>Daily active monitoring</option>
                    <option>Self-monitoring with public health supervision</option>
                    <option>Self-monitoring with delegated supervision</option>
                    <option>Self-observation</option>
                  </Form.Control>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-3 align-items-end">
                <Form.Group as={Col} md={8}>
                  <Form.Label className="nav-input-label">CURRENT WORKFLOW</Form.Label>
                  <Form.Control as="select" className="form-control-lg" id="isolation_status" onChange={this.handleChange} value={this.state.isolation_status}>
                    <option>Exposure</option>
                    <option>Isolation</option>
                  </Form.Control>
                </Form.Group>
                <Form.Group as={Col} md={14}>
                  <Form.Label className="nav-input-label">LATEST PUBLIC HEALTH ACTION</Form.Label>
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
                <Form.Group as={Col} md={2}>
                  {this.state.public_health_action === 'None' && (
                    <OverlayTrigger placement="top" delay={{ show: 100, hide: 400 }} overlay={this.renderPHARefreshTooltip}>
                      <span className="d-inline-block">
                        <Button className="btn-lg btn-square" disabled style={{ pointerEvents: 'none' }}>
                          <i className="fas fa-redo"></i>
                        </Button>
                      </span>
                    </OverlayTrigger>
                  )}
                  {this.state.public_health_action != 'None' && (
                    <OverlayTrigger placement="top" delay={{ show: 100, hide: 400 }} overlay={this.renderPHARefreshTooltip}>
                      <Button
                        className="btn-lg btn-square"
                        onClick={() => {
                          if (window.confirm("This will add an additional duplicate public health action to this monitoree's history. Are you sure?")) {
                            this.publicHealthActionRefresh();
                          }
                        }}>
                        <i className="fas fa-redo"></i>
                      </Button>
                    </OverlayTrigger>
                  )}
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-3 align-items-end">
                <Form.Group as={Col} md={14}>
                  <Form.Label className="nav-input-label">ASSIGNED JURISDICTION</Form.Label>
                  <Form.Control
                    as="input"
                    list="jurisdiction"
                    name="jurisdictionList"
                    autoComplete="off"
                    value={this.state.jurisdiction}
                    className="form-control-lg"
                    onChange={this.handleChange}
                    onKeyPress={this.handleKeyPress}
                  />
                  <datalist id="jurisdiction">
                    {this.props.jurisdiction_paths.map(jur => {
                      return (
                        <option value={jur.label} key={`jur-${jur.value}`}>
                          {jur.label}
                        </option>
                      );
                    })}
                  </datalist>
                </Form.Group>
                <Form.Group as={Col} md={8}>
                  {!this.state.valid_jurisdiction || this.state.current_jurisdiction === this.state.jurisdiction ? (
                    <Button disabled className="btn-lg btn-square">
                      <i className="fas fa-map-marked-alt"></i> Change Jurisdiction
                    </Button>
                  ) : (
                    <Button onClick={this.toggleJurisdictionModal} className="btn-lg btn-square">
                      <i className="fas fa-map-marked-alt"></i> Change Jurisdiction
                    </Button>
                  )}
                </Form.Group>
                {/* <Form.Group as={Col} md={6}>
                  {!this.props.patient.pause_notifications && (
                    <Button className="btn-lg btn-square float-right" id="pause_notifications" onClick={this.handleChange}>
                      <i className="fas fa-pause"></i> Pause Notifications
                    </Button>
                  )}
                  {this.props.patient.pause_notifications && (
                    <Button className="btn-lg btn-square float-right" id="pause_notifications" onClick={this.handleChange}>
                      <i className="fas fa-play"></i> Resume Notifications
                    </Button>
                  )}
                </Form.Group> */}
              </Form.Row>
            </Col>
          </Row>
        </Form>
        {this.state.showMonitoringStatusModal && this.createModal('Monitoring Status', this.toggleMonitoringStatusModal, this.submit)}
        {this.state.showMonitoringPlanModal && this.createModal('Monitoring Plan', this.toggleMonitoringPlanModal, this.submit)}
        {this.state.showExposureRiskAssessmentModal && this.createModal('Exposure Risk Assessment', this.toggleExposureRiskAssessmentModal, this.submit)}
        {this.state.showJurisdictionModal && this.createModal('Jurisdiction', this.toggleJurisdictionModal, this.submit)}
        {this.state.showPublicHealthActionModal && this.createModal('Public Health Action', this.togglePublicHealthAction, this.submit)}
        {this.state.showIsolationModal && this.createModal('Isolation', this.toggleIsolation, this.submit)}
        {this.state.showNotificationsModal && this.createModal('Notifications', this.toggleNotifications, this.submit)}
      </React.Fragment>
    );
  }
}

MonitoringStatus.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.array,
  jurisdiction_id: PropTypes.number,
  has_group_members: PropTypes.bool,
};

export default MonitoringStatus;
