import React from 'react';
import { Form, Row, Col, Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';

class MonitoringStatus extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showExposureRiskAssessmentModal: false,
      showMonitoringPlanModal: false,
      showMonitoringStatusModal: false,
      message: '',
      reasoning: '',
      monitoring_status: props.patient.monitoring ? 'Actively Monitoring' : 'Not Monitoring',
      monitoring_plan: props.patient.monitoring_plan ? props.patient.monitoring_plan : '',
      exposure_risk_assessment: props.patient.exposure_risk_assessment ? props.patient.exposure_risk_assessment : '',
    };
    this.handleChange = this.handleChange.bind(this);
    this.submit = this.submit.bind(this);
    this.toggleMonitoringStatusModal = this.toggleMonitoringStatusModal.bind(this);
    this.toggleMonitoringPlanModal = this.toggleMonitoringPlanModal.bind(this);
    this.toggleExposureRiskAssessmentModal = this.toggleExposureRiskAssessmentModal.bind(this);
  }

  handleChange(event) {
    if (event?.target?.id && event.target.id === 'exposure_risk_assessment') {
      this.setState({
        showExposureRiskAssessmentModal: true,
        message: 'exposure risk assessment to "' + event.target.value + '".',
        [event.target.id]: event?.target?.value ? event.target.value : '',
      });
    } else if (event?.target?.id && event.target.id === 'monitoring_plan') {
      this.setState({
        showMonitoringPlanModal: true,
        message: 'monitoring plan to "' + event.target.value + '".',
        [event.target.id]: event?.target?.value ? event.target.value : '',
      });
    } else if (event?.target?.id && event.target.id === 'monitoring_status') {
      this.setState({
        showMonitoringStatusModal: true,
        message: 'monitoring status to "' + event.target.value + '".',
        [event.target.id]: event?.target?.value ? event.target.value : '',
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

  submit() {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post('/patients/' + this.props.patient.id + '/status', {
        monitoring: this.state.monitoring_status === 'Actively Monitoring' ? true : false,
        exposure_risk_assessment: this.state.exposure_risk_assessment,
        monitoring_plan: this.state.monitoring_plan,
        message: this.state.message,
        reasoning: this.state.reasoning,
      })
      .then(() => {
        location.href = '/patients/' + this.props.patient.id;
      })
      .catch(error => {
        console.log(error);
      });
  }

  render() {
    return (
      <React.Fragment>
        <Form className="mb-3 mt-3 pt-2 px-4">
          <Row>
            <Col>
              <Form.Row>
                <Form.Group as={Col}>
                  <Form.Label>MONITORING STATUS</Form.Label>
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
                  <Form.Label>EXPOSURE RISK ASSESSMENT</Form.Label>
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
                  <Form.Label>MONITORING PLAN</Form.Label>
                  <Form.Control as="select" className="form-control-lg" id="monitoring_plan" onChange={this.handleChange} value={this.state.monitoring_plan}>
                    <option disabled></option>
                    <option>Daily active monitoring</option>
                    <option>Self-monitoring with public health supervision</option>
                    <option>Self-monitoring with delegated supervision</option>
                    <option>Self-observation</option>
                  </Form.Control>
                </Form.Group>
              </Form.Row>
            </Col>
          </Row>
        </Form>
        <Modal show={this.state.showExposureRiskAssessmentModal}>
          <Modal.Header>
            <Modal.Title>Monitoree Exposure Risk Assessment</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <p>You are about to change this monitoree&apos;s {this.state.message}</p>
            <Form.Group>
              <Form.Label>Please describe your reasoning:</Form.Label>
              <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleChange} />
            </Form.Group>
          </Modal.Body>
          <Modal.Footer>
            <Button variant="primary btn-square" onClick={this.submit}>
              Submit
            </Button>
            <Button variant="secondary btn-square" onClick={this.toggleExposureRiskAssessmentModal}>
              Cancel
            </Button>
          </Modal.Footer>
        </Modal>
        <Modal show={this.state.showMonitoringPlanModal}>
          <Modal.Header>
            <Modal.Title>Monitoring Plan</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <p>You are about to change this monitoree&apos;s {this.state.message}</p>
            <Form.Group>
              <Form.Label>Please describe your reasoning:</Form.Label>
              <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleChange} />
            </Form.Group>
          </Modal.Body>
          <Modal.Footer>
            <Button variant="primary btn-square" onClick={this.submit}>
              Submit
            </Button>
            <Button variant="secondary btn-square" onClick={this.toggleMonitoringPlanModal}>
              Cancel
            </Button>
          </Modal.Footer>
        </Modal>
        <Modal show={this.state.showMonitoringStatusModal}>
          <Modal.Header>
            <Modal.Title>Monitoring Status</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <p>You are about to change this monitoree&apos;s {this.state.message}</p>
            <Form.Group>
              <Form.Label>Please describe your reasoning:</Form.Label>
              <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleChange} />
            </Form.Group>
          </Modal.Body>
          <Modal.Footer>
            <Button variant="primary btn-square" onClick={this.submit}>
              Submit
            </Button>
            <Button variant="secondary btn-square" onClick={this.toggleMonitoringStatusModal}>
              Cancel
            </Button>
          </Modal.Footer>
        </Modal>
      </React.Fragment>
    );
  }
}

MonitoringStatus.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default MonitoringStatus;
