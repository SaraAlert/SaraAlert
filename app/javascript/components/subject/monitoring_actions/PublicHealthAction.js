import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Button, Modal } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';

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
      loading: false,
    };
    this.origState = Object.assign({}, this.state);
  }

  handlePublicHealthActionChange = event => {
    this.setState({
      showPublicHealthActionModal: true,
      public_health_action: event.target.value || '',
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

  togglePublicHealthAction = () => {
    const current = this.state.showPublicHealthActionModal;
    this.setState({
      showPublicHealthActionModal: !current,
      public_health_action: this.props.patient.public_health_action ? this.props.patient.public_health_action : '',
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
          public_health_action: this.state.public_health_action,
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
              <Form.Group>
                {this.state.apply_to_household && this.props.patient.monitoring && (
                  <i>
                    If any household members are being monitored in the exposure workflow, those records will appear on the PUI line list if any public health
                    action other than &quot;None&quot; is selected above. If any household members are being monitored in the isolation workflow, this update
                    will not impact the line list on which those records appear.
                  </i>
                )}
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
          <Form.Label className="nav-input-label">
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
  has_dependents: PropTypes.bool,
};

export default PublicHealthAction;
