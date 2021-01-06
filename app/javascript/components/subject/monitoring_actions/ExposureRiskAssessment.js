import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Button, Modal } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';

import InfoTooltip from '../../util/InfoTooltip';
import reportError from '../../util/ReportError';

class ExposureRiskAssessment extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      patient: props.patient,
      showExposureRiskAssessmentModal: false,
      reasoning: '',
      exposure_risk_assessment: props.patient.exposure_risk_assessment || '',
      apply_to_household: false,
      loading: false,
    };
    this.origState = Object.assign({}, this.state);
  }

  handleExposureRiskAssessmentChange = event => {
    this.setState({
      showExposureRiskAssessmentModal: true,
      exposure_risk_assessment: event.target.value || '',
    });
  };

  handleApplyHouseholdChange = event => {
    const applyToHousehold = event.target.id === 'apply_to_household_yes';
    this.setState({ apply_to_household: applyToHousehold });
  };

  handleReasoningChange = event => {
    let value = event?.target?.value;
    this.setState({ [event.target.id]: value || '' });
  };

  toggleExposureRiskAssessmentModal = () => {
    const current = this.state.showExposureRiskAssessmentModal;
    this.setState({
      showExposureRiskAssessmentModal: !current,
      exposure_risk_assessment: this.props.patient.exposure_risk_assessment ? this.props.patient.exposure_risk_assessment : '',
      apply_to_household: false,
      reasoning: '',
    });
  };

  submit = () => {
    const diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          exposure_risk_assessment: this.state.exposure_risk_assessment,
          reasoning: this.state.reasoning,
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
          <Modal.Title>Exposure Risk Assessment</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            Are you sure you want to change exposure risk assessment to{' '}
            {this.state.exposure_risk_assessment ? `"${this.state.exposure_risk_assessment}"` : 'blank'}?
          </p>
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
          <Form.Group>
            <Form.Label>Please include any additional details:</Form.Label>
            <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleReasoningChange} aria-label="Additional Details Text Area" />
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
          <Form.Label htmlFor="exposure_risk_assessment" className="nav-input-label">
            EXPOSURE RISK ASSESSMENT
            <InfoTooltip tooltipTextKey={'exposureRiskAssessment'} location="right"></InfoTooltip>
          </Form.Label>
          <Form.Control
            as="select"
            className="form-control-lg"
            id="exposure_risk_assessment"
            onChange={this.handleExposureRiskAssessmentChange}
            value={this.state.exposure_risk_assessment}>
            <option></option>
            <option>High</option>
            <option>Medium</option>
            <option>Low</option>
            <option>No Identified Risk</option>
          </Form.Control>
        </div>
        {this.state.showExposureRiskAssessmentModal && this.createModal(this.toggleExposureRiskAssessmentModal, this.submit)}
      </React.Fragment>
    );
  }
}

ExposureRiskAssessment.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  has_dependents: PropTypes.bool,
};

export default ExposureRiskAssessment;
