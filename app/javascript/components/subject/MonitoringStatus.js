import React from 'react';
import { Form, Row, Col, Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';

class MonitoringStatus extends React.Component {
  constructor(props) {
    super(props);
    const jur = this.props.jurisdiction_paths.find(jur => jur.value === props.jurisdiction_id);
    this.state = {
      showExposureRiskAssessmentModal: false,
      showMonitoringPlanModal: false,
      showMonitoringStatusModal: false,
      showJurisdictionModal: false,
      message: '',
      reasoning: '',
      monitoring_status: props.patient.monitoring ? 'Actively Monitoring' : 'Not Monitoring',
      monitoring_plan: props.patient.monitoring_plan ? props.patient.monitoring_plan : '',
      exposure_risk_assessment: props.patient.exposure_risk_assessment ? props.patient.exposure_risk_assessment : '',
      jurisdiction: jur ? jur.label : '',
      current_jurisdiction: jur ? jur.label : '', // Used to remember jur on page load in case user cancels change modal
      monitoring_status_options: null,
    };
    this.handleChange = this.handleChange.bind(this);
    this.submit = this.submit.bind(this);
    this.toggleMonitoringStatusModal = this.toggleMonitoringStatusModal.bind(this);
    this.toggleMonitoringPlanModal = this.toggleMonitoringPlanModal.bind(this);
    this.toggleExposureRiskAssessmentModal = this.toggleExposureRiskAssessmentModal.bind(this);
    this.toggleJurisdictionModal = this.toggleJurisdictionModal.bind(this);
  }

  handleChange(event) {
    if (event?.target?.name && event.target.name === 'jurisdictionList') {
      // Jurisdiction is a weird case; the datalist and input work differently together
      this.setState({
        message: 'jurisdiction to "' + event.target.value + '".',
        message_warning: '',
        jurisdiction: event?.target?.value ? event.target.value : '',
        monitoring_status_options: null,
        monitoring_status_option: null,
      });
    } else if (event?.target?.id && event.target.id === 'exposure_risk_assessment') {
      this.setState({
        showExposureRiskAssessmentModal: true,
        message: 'exposure risk assessment to "' + event.target.value + '".',
        message_warning: '',
        exposure_risk_assessment: event?.target?.value ? event.target.value : '',
        monitoring_status_options: null,
        monitoring_status_option: null,
      });
    } else if (event?.target?.id && event.target.id === 'monitoring_plan') {
      this.setState({
        showMonitoringPlanModal: true,
        message: 'monitoring plan to "' + event.target.value + '".',
        message_warning: '',
        monitoring_plan: event?.target?.value ? event.target.value : '',
        monitoring_status_options: null,
        monitoring_status_option: null,
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
              ]
            : null,
        monitoring_status_option: null,
      });
    } else if (event?.target?.id) {
      this.setState({ [event.target.id]: event?.target?.value ? event.target.value : '' });
    }
  }

  toggleMonitoringStatusModal() {
    let current = this.state.showMonitoringStatusModal;
    this.setState({
      showMonitoringStatusModal: !current,
      monitoring_status: this.props.patient.monitoring ? 'Actively Monitoring' : 'Not Monitoring',
    });
  }

  toggleMonitoringPlanModal() {
    let current = this.state.showMonitoringPlanModal;
    this.setState({
      showMonitoringPlanModal: !current,
      monitoring_plan: this.props.patient.monitoring_plan ? this.props.patient.monitoring_plan : '',
    });
  }

  toggleExposureRiskAssessmentModal() {
    let current = this.state.showExposureRiskAssessmentModal;
    this.setState({
      showExposureRiskAssessmentModal: !current,
      exposure_risk_assessment: this.props.patient.exposure_risk_assessment ? this.props.patient.exposure_risk_assessment : '',
    });
  }

  toggleJurisdictionModal() {
    let current = this.state.showJurisdictionModal;
    this.setState({
      message: 'jurisdiction to "' + this.state.jurisdiction + '".',
      showJurisdictionModal: !current,
      jurisdiction: current ? this.state.current_jurisdiction : this.state.jurisdiction, // Reset select jurisdiction if cancel
    });
  }

  submit() {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    const jur = this.props.jurisdiction_paths.find(jur => jur.label === this.state.jurisdiction);
    axios
      .post('/patients/' + this.props.patient.id + '/status', {
        monitoring: this.state.monitoring_status === 'Actively Monitoring' ? true : false,
        exposure_risk_assessment: this.state.exposure_risk_assessment,
        monitoring_plan: this.state.monitoring_plan,
        message: this.state.message,
        reasoning: (this.state.monitoring_status_option ? this.state.monitoring_status_option + (this.state.reasoning ? ', ' : '') : '') + this.state.reasoning,
        jurisdiction: jur ? jur.value : null,
      })
      .then(() => {
        location.href = '/patients/' + this.props.patient.id;
      })
      .catch(error => {
        console.log(error);
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
            You are about to change this subject&apos;s {this.state.message} {this.state.message_warning && <b>{this.state.message_warning}</b>}
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
                    <option disabled></option>
                    <option>Daily active monitoring</option>
                    <option>Self-monitoring with public health supervision</option>
                    <option>Self-monitoring with delegated supervision</option>
                    <option>Self-observation</option>
                  </Form.Control>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-3 align-items-end">
                <Form.Group as={Col} md={14}>
                  <Form.Label className="nav-input-label">ASSIGNED JURISDICTION</Form.Label>
                  <Form.Control
                    as="input"
                    list="jurisdiction"
                    name="jurisdictionList"
                    value={this.state.jurisdiction}
                    className="form-control-lg"
                    onChange={this.handleChange}
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
                <Form.Group as={Col} md={10}>
                  <Button onClick={this.toggleJurisdictionModal} className="btn-lg btn-square">
                    Change Jurisdiction
                  </Button>
                </Form.Group>
              </Form.Row>
            </Col>
          </Row>
        </Form>
        {this.state.showMonitoringStatusModal && this.createModal('Monitoring Status', this.toggleMonitoringStatusModal, this.submit)}
        {this.state.showMonitoringPlanModal && this.createModal('Monitoring Plan', this.toggleMonitoringPlanModal, this.submit)}
        {this.state.showExposureRiskAssessmentModal && this.createModal('Exposure Risk Assessment', this.toggleExposureRiskAssessmentModal, this.submit)}
        {this.state.showJurisdictionModal && this.createModal('Jurisdiction', this.toggleJurisdictionModal, this.submit)}
      </React.Fragment>
    );
  }
}

MonitoringStatus.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.array,
  jurisdiction_id: PropTypes.number,
};

export default MonitoringStatus;
