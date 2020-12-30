import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Modal, Form } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';

import InfoTooltip from '../../util/InfoTooltip';
import reportError from '../../util/ReportError';

class Jurisdiction extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showJurisdictionModal: false,
      jurisdiction_path: this.props.jurisdiction_paths[this.props.patient.jurisdiction_id],
      original_jurisdiction_id: this.props.patient.jurisdiction_id,
      validJurisdiction: true,
      apply_to_household: false,
      loading: false,
      reasoning: '',
    };
    this.origState = Object.assign({}, this.state);
  }

  handleJurisdictionChange = event => {
    this.setState({
      jurisdiction_path: event?.target?.value ? event.target.value : '',
      validJurisdiction: Object.values(this.props.jurisdiction_paths).includes(event.target.value),
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

  // if user hits the Enter key after changing the jurisdiction value, shows the modal (in leu of clicking the button)
  handleKeyPress = event => {
    if (
      event.which === 13 &&
      this.state.validJurisdiction &&
      this.state.jurisdiction_path !== this.props.jurisdiction_paths[this.state.original_jurisdiction_id]
    ) {
      event.preventDefault();
      this.toggleJurisdictionModal();
    }
  };

  toggleJurisdictionModal = () => {
    const current = this.state.showJurisdictionModal;
    this.setState({
      showJurisdictionModal: !current,
      jurisdiction_path: current ? this.props.jurisdiction_paths[this.state.original_jurisdiction_id] : this.state.jurisdiction_path,
      apply_to_household: false,
      reasoning: '',
    });
  };

  submit = () => {
    const diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    // If the jurisdiction_path changed, this means the underlying id must also have changed
    if (diffState.indexOf('jurisdiction_path') > -1) {
      diffState.push('jurisdiction_id');
    }
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          jurisdiction_id: Object.keys(this.props.jurisdiction_paths).find(id => this.props.jurisdiction_paths[parseInt(id)] === this.state.jurisdiction_path),
          reasoning: this.state.reasoning,
          apply_to_household: this.state.apply_to_household,
          diffState: diffState,
        })
        .then(() => {
          const currentUserJurisdictionString = this.props.current_user.jurisdiction_path.join(', ');
          // check if current_user has access to the changed jurisdiction
          // if so, reload the page, if not, redirect to exposure or isolation dashboard
          if (!this.state.jurisdiction_path.startsWith(currentUserJurisdictionString)) {
            const pathEnd = this.state.isolation ? '/isolation' : '';
            location.assign((window.BASE_PATH ? window.BASE_PATH : '') + '/public_health' + pathEnd);
          } else {
            location.reload(true);
          }
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
          <Modal.Title>Jurisdiction</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            Are you sure you want to change jurisdiction from &quot;{this.props.jurisdiction_paths[this.state.original_jurisdiction_id]}&quot; to &quot;
            {this.state.jurisdiction_path}&quot;?
            {this.state.assigned_user !== '' && <b> Please also consider removing or updating the assigned user if it is no longer applicable.</b>}
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
          <Form.Label htmlFor="jurisdiction_id" className="nav-input-label">
            ASSIGNED JURISDICTION
            <InfoTooltip
              tooltipTextKey={this.props.user_can_transfer ? 'assignedJurisdictionCanTransfer' : 'assignedJurisdictionCannotTransfer'}
              location="right"></InfoTooltip>
          </Form.Label>
          <Form.Group className="d-flex mb-0">
            <Form.Control
              as="input"
              id="jurisdiction_id"
              list="jurisdiction_paths"
              autoComplete="off"
              className="form-control-lg"
              onChange={this.handleJurisdictionChange}
              onKeyPress={this.handleKeyPress}
              value={this.state.jurisdiction_path}
            />
            <datalist id="jurisdiction_paths">
              {Object.entries(this.props.jurisdiction_paths).map(([id, path]) => {
                return (
                  <option value={path} key={id}>
                    {path}
                  </option>
                );
              })}
            </datalist>
            <Button
              className="btn-lg btn-square text-nowrap ml-2"
              onClick={this.toggleJurisdictionModal}
              disabled={!this.state.validJurisdiction || this.state.jurisdiction_path === this.props.jurisdiction_paths[this.state.original_jurisdiction_id]}>
              <i className="fas fa-map-marked-alt"></i> Change Jurisdiction
            </Button>
          </Form.Group>
        </div>
        {this.state.showJurisdictionModal && this.createModal(this.toggleJurisdictionModal, this.submit)}
      </React.Fragment>
    );
  }
}

Jurisdiction.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  has_dependents: PropTypes.bool,
  jurisdiction_paths: PropTypes.object,
  current_user: PropTypes.object,
  user_can_transfer: PropTypes.bool,
};

export default Jurisdiction;
