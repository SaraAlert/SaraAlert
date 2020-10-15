import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Button, Modal } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';

import InfoTooltip from '../util/InfoTooltip';
import reportError from '../util/ReportError';

class GenericAction extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      patient: props.patient,
      showExposureRiskAssessmentModal: false,
      showMonitoringPlanModal: false,
      showPublicHealthActionModal: false,
      showIsolationModal: false,
      showNotificationsModal: false,
      message: '',
      reasoning: '',
      monitoring_plan: props.patient.monitoring_plan ? props.patient.monitoring_plan : '',
      exposure_risk_assessment: props.patient.exposure_risk_assessment ? props.patient.exposure_risk_assessment : '',
      public_health_action: props.patient.public_health_action ? props.patient.public_health_action : '',
      apply_to_group: false,
      loading: false,
      household_warning: '',
    };
    this.origState = Object.assign({}, this.state);
  }

  handleChange = event => {
    if (event?.target?.id && event.target.id === 'exposure_risk_assessment') {
      const exposureRiskAssessmentPrompt = event.target.value ? `"${event.target.value}"` : 'blank';
      this.setState({
        showExposureRiskAssessmentModal: true,
        message: `exposure risk assessment to ${exposureRiskAssessmentPrompt}`,
        message_warning: '',
        exposure_risk_assessment: event?.target?.value ? event.target.value : '',
      });
    } else if (event?.target?.id && event.target.id === 'monitoring_plan') {
      this.setState({
        showMonitoringPlanModal: true,
        message: `monitoring plan to "${event.target.value}"`,
        message_warning: '',
        monitoring_plan: event?.target?.value ? event.target.value : '',
      });
    } else if (event?.target?.id && event.target.id === 'public_health_action') {
      if (!this.state.patient.monitoring) {
        this.setState({
          showPublicHealthActionModal: true,
          message: `latest public health action to "${event.target.value}"`,
          message_warning:
            'Since this record is on the "Closed" line list, updating this value will not move this record to another line list. If this individual should be actively monitored, please update the record\'s Monitoring Status.',
          public_health_action: event?.target?.value ? event.target.value : '',
        });
      } else if (this.state.patient.isolation) {
        this.setState({
          showPublicHealthActionModal: true,
          message: `latest public health action to "${event.target.value}"`,
          message_warning: 'This will not impact the line list on which this record appears.',
          household_warning:
            'If any household members are being monitored in the exposure workflow, those records will appear on the PUI line list if any public health action other than "None" is selected above. If any household members are being monitored in the isolation workflow, this update will not impact the line list on which those records appear.',
          public_health_action: event?.target?.value ? event.target.value : '',
        });
      } else {
        this.setState({
          showPublicHealthActionModal: true,
          message: `latest public health action to "${event.target.value}"`,
          message_warning:
            event.target.value === 'None'
              ? 'The monitoree will be moved back into the primary status line lists.'
              : 'The monitoree will be moved into the PUI line list.',
          household_warning:
            'If any household members are being monitored in the exposure workflow, those records will appear on the PUI line list if any public health action other than "None" is selected above. If any household members are being monitored in the isolation workflow, this update will not impact the line list on which those records appear.',
          public_health_action: event?.target?.value ? event.target.value : '',
        });
      }
    } else if (event?.target?.name && event.target.name === 'apply_to_group') {
      let applyToGroup = event.target.id === 'apply_to_group_yes';
      this.setState({ [event.target.name]: applyToGroup });
    } else if (event?.target?.id) {
      let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
      this.setState({ [event.target.id]: event?.target?.value ? value : '' });
    }
  };

  toggleExposureRiskAssessmentModal = () => {
    let current = this.state.showExposureRiskAssessmentModal;
    this.setState({
      showExposureRiskAssessmentModal: !current,
      exposure_risk_assessment: this.props.patient.exposure_risk_assessment ? this.props.patient.exposure_risk_assessment : '',
      apply_to_group: false,
      reasoning: '',
    });
  };

  toggleMonitoringPlanModal = () => {
    let current = this.state.showMonitoringPlanModal;
    this.setState({
      showMonitoringPlanModal: !current,
      monitoring_plan: this.props.patient.monitoring_plan ? this.props.patient.monitoring_plan : '',
      apply_to_group: false,
      reasoning: '',
    });
  };

  togglePublicHealthAction = () => {
    let current = this.state.showPublicHealthActionModal;
    this.setState({
      showPublicHealthActionModal: !current,
      public_health_action: this.props.patient.public_health_action ? this.props.patient.public_health_action : '',
      apply_to_group: false,
      reasoning: '',
    });
  };

  submit = () => {
    let diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          exposure_risk_assessment: this.state.exposure_risk_assessment,
          monitoring_plan: this.state.monitoring_plan,
          public_health_action: this.state.public_health_action,
          reasoning: this.state.reasoning,
          apply_to_group: this.state.apply_to_group,
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

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered onHide={toggle}>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            Are you sure you want to change {this.state.message}? {this.state.message_warning && <b>{this.state.message_warning}</b>}
          </p>
          {this.props.has_group_members && (
            <React.Fragment>
              <p className="mb-2">Please select the records that you would like to apply this change to:</p>
              <Form.Group className="px-4">
                <Form.Check
                  type="radio"
                  className="mb-1"
                  name="apply_to_group"
                  id="apply_to_group_no"
                  label="This monitoree only"
                  onChange={this.handleChange}
                  checked={!this.state.apply_to_group}
                />
                <Form.Check
                  type="radio"
                  className="mb-3"
                  name="apply_to_group"
                  id="apply_to_group_yes"
                  label="This monitoree and all household members"
                  onChange={this.handleChange}
                  checked={this.state.apply_to_group}
                />
              </Form.Group>
              <Form.Group>{this.state.apply_to_group && this.state.household_warning && <i>{this.state.household_warning}</i>}</Form.Group>
            </React.Fragment>
          )}
          <Form.Group>
            <Form.Label>Please include any additional details:</Form.Label>
            <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleChange} />
          </Form.Group>
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

  render() {
    return (
      <React.Fragment>
        <div className="disabled">
          <Form.Label className="nav-input-label">
            {this.props.title}
            <InfoTooltip tooltipTextKey={this.props.tooltipKey} location="right"></InfoTooltip>
          </Form.Label>
          <Form.Control
            as="select"
            className="form-control-lg"
            id={this.props.monitoringAction}
            onChange={this.handleChange}
            value={this.state[this.props.monitoringAction]}>
            {this.props.options.map(function(option, index) {
              return <option key={index}>{option}</option>;
            })}
          </Form.Control>
        </div>
        {this.state.showExposureRiskAssessmentModal && this.createModal('Exposure Risk Assessment', this.toggleExposureRiskAssessmentModal, this.submit)}
        {this.state.showMonitoringPlanModal && this.createModal('Monitoring Plan', this.toggleMonitoringPlanModal, this.submit)}
        {this.state.showPublicHealthActionModal && this.createModal('Public Health Action', this.togglePublicHealthAction, this.submit)}
      </React.Fragment>
    );
  }
}

GenericAction.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  has_group_members: PropTypes.bool,
  title: PropTypes.string,
  monitoringAction: PropTypes.string,
  tooltipKey: PropTypes.string,
  options: PropTypes.array,
};

export default GenericAction;
