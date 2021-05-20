import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Button, Modal } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';
import ReactTooltip from 'react-tooltip';

import ApplyToHousehold from '../household/actions/ApplyToHousehold';
import InfoTooltip from '../../util/InfoTooltip';
import reportError from '../../util/ReportError';

class MonitoringPlan extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      patient: props.patient,
      showMonitoringPlanModal: false,
      reasoning: '',
      monitoring_plan: props.patient.monitoring_plan || '',
      apply_to_household: false,
      apply_to_household_ids: [],
      loading: false,
      noMembersSelected: false,
    };
    this.origState = Object.assign({}, this.state);
  }

  handleMonitoringPlanChange = event => {
    this.setState({
      showMonitoringPlanModal: true,
      monitoring_plan: event.target.value || '',
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

  toggleMonitoringPlanModal = () => {
    const current = this.state.showMonitoringPlanModal;
    this.setState({
      showMonitoringPlanModal: !current,
      monitoring_plan: this.props.patient.monitoring_plan ? this.props.patient.monitoring_plan : '',
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
          monitoring_plan: this.state.monitoring_plan,
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
          <Modal.Title>Monitoring Plan</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>Are you sure you want to change monitoring plan to {this.state.monitoring_plan ? `"${this.state.monitoring_plan}"` : 'blank'}?</p>
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
            <span data-for="monitoring-plan-submit" data-tip="">
              Submit
            </span>
            {this.state.noMembersSelected && (
              <ReactTooltip id="monitoring-plan-submit" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
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
          <Form.Label htmlFor="monitoring_plan" className="input-label">
            MONITORING PLAN
            <InfoTooltip tooltipTextKey={'monitoringPlan'} location="right"></InfoTooltip>
          </Form.Label>
          <Form.Control
            as="select"
            className="form-control-lg"
            id="monitoring_plan"
            onChange={this.handleMonitoringPlanChange}
            value={this.state.monitoring_plan}>
            <option></option>
            <option>None</option>
            <option>Daily active monitoring</option>
            <option>Self-monitoring with public health supervision</option>
            <option>Self-monitoring with delegated supervision</option>
            <option>Self-observation</option>
          </Form.Control>
        </div>
        {this.state.showMonitoringPlanModal && this.createModal(this.toggleMonitoringPlanModal, this.submit)}
      </React.Fragment>
    );
  }
}

MonitoringPlan.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  household_members: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  workflow: PropTypes.string,
  continuous_exposure_enabled: PropTypes.bool,
};

export default MonitoringPlan;
