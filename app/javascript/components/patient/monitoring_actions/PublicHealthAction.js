import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Button, Modal } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';
import ReactTooltip from 'react-tooltip';

import ApplyToHousehold from '../household/actions/ApplyToHousehold';
import InfoTooltip from '../../util/InfoTooltip';
import reportError from '../../util/ReportError';

class PublicHealthAction extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      patient: props.patient,
      showPublicHealthActionModal: false,
      reasoning: '',
      public_health_action: props.patient.public_health_action || '',
      apply_to_household: false,
      apply_to_household_ids: [],
      loading: false,
      noMembersSelected: false,
    };
    this.origState = Object.assign({}, this.state);
  }

  handlePublicHealthActionChange = event => {
    this.setState({
      showPublicHealthActionModal: true,
      public_health_action: event.target.value || '',
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

  togglePublicHealthAction = () => {
    const current = this.state.showPublicHealthActionModal;
    this.setState({
      showPublicHealthActionModal: !current,
      public_health_action: this.props.patient.public_health_action ? this.props.patient.public_health_action : '',
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
          public_health_action: this.state.public_health_action,
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
          <Modal.Title>Public Health Action</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            Are you sure you want to change latest public health action to &quot;{this.state.public_health_action}&quot;?
            {!this.props.patient.monitoring && (
              <b>
                {' '}
                Since this record is on the &quot;Closed&quot; line list, updating this value will not move this record to another line list. If this individual
                should be actively monitored, please update the record&apos;s Monitoring Status.
              </b>
            )}
            {this.props.patient.isolation && this.props.patient.monitoring && <b> This will not impact the line list on which this record appears.</b>}
            {!this.props.patient.isolation && this.props.patient.monitoring && this.state.public_health_action === 'None' && (
              <b> The monitoree will be moved back into the primary status line lists.</b>
            )}
            {!this.props.patient.isolation && this.props.patient.monitoring && this.state.public_health_action !== 'None' && (
              <b> The monitoree will be moved into the PUI line list.</b>
            )}
          </p>
          {this.props.household_members.length > 0 && (
            <React.Fragment>
              <ApplyToHousehold
                household_members={this.props.household_members}
                current_user={this.props.current_user}
                jurisdiction_paths={this.props.jurisdiction_paths}
                handleApplyHouseholdChange={this.handleApplyHouseholdChange}
                handleApplyHouseholdIdsChange={this.handleApplyHouseholdIdsChange}
                workflow={this.props.workflow}
                continuous_exposure_enabled={this.props.continuous_exposure_enabled}
              />
              {this.state.apply_to_household && this.props.patient.monitoring && (
                <Form.Group>
                  <i>
                    If any household members are being monitored in the exposure workflow, those records will appear on the PUI line list if any public health
                    action other than &quot;None&quot; is selected above. If any household members are being monitored in the isolation workflow, this update
                    will not impact the line list on which those records appear.
                  </i>
                </Form.Group>
              )}
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
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.loading || this.state.noMembersSelected}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            <span data-for="public-health-action-submit" data-tip="">
              Submit
            </span>
            {this.state.noMembersSelected && (
              <ReactTooltip id="public-health-action-submit" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
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
          <Form.Label htmlFor="public_health_action" className="input-label">
            LATEST PUBLIC HEALTH ACTION
            <InfoTooltip
              tooltipTextKey={this.props.patient.isolation ? 'latestPublicHealthActionInIsolation' : 'latestPublicHealthActionInExposure'}
              location="right"></InfoTooltip>
          </Form.Label>
          <Form.Control
            as="select"
            className="form-control-lg"
            id="public_health_action"
            onChange={this.handlePublicHealthActionChange}
            value={this.state.public_health_action}>
            <option>None</option>
            <option>Recommended medical evaluation of symptoms</option>
            <option>Document results of medical evaluation</option>
            <option>Recommended laboratory testing</option>
          </Form.Control>
        </div>
        {this.state.showPublicHealthActionModal && this.createModal(this.togglePublicHealthAction, this.submit)}
      </React.Fragment>
    );
  }
}

PublicHealthAction.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  household_members: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  workflow: PropTypes.string,
  continuous_exposure_enabled: PropTypes.bool,
};

export default PublicHealthAction;
