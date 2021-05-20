import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Button, Modal } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';
import ReactTooltip from 'react-tooltip';

import ApplyToHousehold from '../household/actions/ApplyToHousehold';
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
      apply_to_household_ids: [],
      loading: false,
      noMembersSelected: false,
    };
    this.origState = Object.assign({}, this.state);
  }

  handleExposureRiskAssessmentChange = event => {
    this.setState({
      showExposureRiskAssessmentModal: true,
      exposure_risk_assessment: event.target.value || '',
    });
  };

  handleReasoningChange = event => {
    let value = event?.target?.value;
    this.setState({ [event.target.id]: value || '' });
  };

  handleApplyHouseholdChange = apply_to_household => {
    const noMembersSelected = apply_to_household && this.state.apply_to_household_ids.length === 0;
    this.setState({ apply_to_household, noMembersSelected });
  };

  handleApplyHouseholdIdsChange = apply_to_household_ids => {
    const noMembersSelected = this.state.apply_to_household && apply_to_household_ids.length === 0;
    this.setState({ apply_to_household_ids, noMembersSelected });
  };

  toggleExposureRiskAssessmentModal = () => {
    const current = this.state.showExposureRiskAssessmentModal;
    this.setState({
      showExposureRiskAssessmentModal: !current,
      exposure_risk_assessment: this.props.patient.exposure_risk_assessment ? this.props.patient.exposure_risk_assessment : '',
      apply_to_household: false,
      apply_to_household_ids: [],
      reasoning: '',
      noMembersSelected: false,
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
          {this.props.household_members.length > 0 && (
            <ApplyToHousehold
              household_members={this.props.household_members}
              handleApplyHouseholdChange={this.handleApplyHouseholdChange}
              handleApplyHouseholdIdsChange={this.handleApplyHouseholdIdsChange}
              current_user={this.props.current_user}
              jurisdiction_paths={this.props.jurisdiction_paths}
              workflow={this.props.workflow}
              continuous_exposure_enabled={this.props.continuous_exposure_enabled}
            />
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
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.loading || this.state.noMembersSelected}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            <span data-for="exposure-risk-assessment-submit" data-tip="">
              Submit
            </span>
            {this.state.noMembersSelected && (
              <ReactTooltip id="exposure-risk-assessment-submit" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
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
          <Form.Label htmlFor="exposure_risk_assessment" className="input-label">
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
  household_members: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  workflow: PropTypes.string,
  continuous_exposure_enabled: PropTypes.bool,
};

export default ExposureRiskAssessment;
