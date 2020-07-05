import React from 'react';
import { Form, Row, Col, Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import reportError from '../util/ReportError';
import InfoTooltip from '../util/InfoTooltip';
import _ from 'lodash';

class LastDateExposure extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      last_date_of_exposure: this.props.patient.last_date_of_exposure,
      continuous_exposure: !!this.props.patient.continuous_exposure,
      loading: false,
      apply_to_group: false, // Flag to apply a change to all members
      apply_to_group_cm_only: false, // Flag to apply a change only to group members where continuous_exposure is true
      showExposureDateModal: false,
      showContinuousMonitoringModal: false,
    };
    this.origState = Object.assign({}, this.state);
    this.submit = this.submit.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.toggleExposureDateModal = this.toggleExposureDateModal.bind(this);
    this.toggleContinuousMonitoringModal = this.toggleContinuousMonitoringModal.bind(this);
    this.createModal = this.createModal.bind(this);
  }

  toggleExposureDateModal() {
    this.setState({ showExposureDateModal: !this.state.showExposureDateModal, apply_to_group: false, apply_to_group_cm_only: false });
  }

  toggleContinuousMonitoringModal() {
    this.setState({
      showContinuousMonitoringModal: !this.state.showContinuousMonitoringModal,
      continuous_exposure: !this.state.continuous_exposure,
      apply_to_group: false,
      apply_to_group_cm_only: false,
    });
  }

  handleChange(event) {
    event.persist();
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    this.setState({ [event.target.id]: value }, () => {
      // Make sure other toggle is reset (these need to act like radio buttons)
      if (event.target.id === 'apply_to_group' && this.state.apply_to_group) {
        this.setState({ apply_to_group_cm_only: false });
      } else if (event.target.id === 'apply_to_group_cm_only' && this.state.apply_to_group_cm_only) {
        this.setState({ apply_to_group: false });
      }
    });
  }

  submit() {
    let diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          last_date_of_exposure: this.state.last_date_of_exposure,
          continuous_exposure: this.state.continuous_exposure,
          apply_to_group: this.state.apply_to_group,
          apply_to_group_cm_only: this.state.apply_to_group_cm_only,
          diffState: diffState,
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  }

  createModal(title, message, toggle, submit) {
    return (
      <Modal size="lg" show centered>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>{message}</p>
          {this.props.has_group_members && (
            <Form.Group className="mt-2">
              <Form.Check
                type="switch"
                id="apply_to_group"
                label="Apply to all active members in this reporting group within the exposure workflow"
                onChange={this.handleChange}
                checked={this.state.apply_to_group === true || false}
              />
            </Form.Group>
          )}
          {this.props.has_group_members && this.state.showExposureDateModal && <b>OR</b>}
          {this.props.has_group_members && this.state.showExposureDateModal && (
            <Form.Group className="mt-3">
              <Form.Check
                type="switch"
                id="apply_to_group_cm_only"
                label="Apply to all active members in this reporting group within the exposure workflow who have continuous exposure enabled"
                onChange={this.handleChange}
                checked={this.state.apply_to_group_cm_only === true || false}
              />
            </Form.Group>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.loading}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Submit
          </Button>
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
        {this.state.showExposureDateModal &&
          this.createModal('Last Date of Exposure', 'Are you sure you want to modify the last date of exposure?', this.toggleExposureDateModal, this.submit)}
        {this.state.showContinuousMonitoringModal &&
          this.createModal('Continuous Exposure', 'Are you sure you want to modify continuous monitoring?', this.toggleContinuousMonitoringModal, this.submit)}
        <Row>
          <Form.Group as={Col} md="6">
            <Form.Label className="nav-input-label">
              LAST DATE OF EXPOSURE
              <InfoTooltip tooltipTextKey="lastDateOfExposure" location="right"></InfoTooltip>
            </Form.Label>
            <Form.Control
              size="lg"
              id="last_date_of_exposure"
              type="date"
              className="form-square"
              value={this.state.last_date_of_exposure || ''}
              onChange={this.handleChange}
            />
          </Form.Group>
          <Form.Group as={Col} md="18" className="align-self-end pl-0">
            <Button className="btn-lg" onClick={() => this.toggleExposureDateModal()}>
              <i className="fas fa-temperature-high"></i> Update
              {this.state.loading && (
                <React.Fragment>
                  &nbsp;<span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
                </React.Fragment>
              )}
            </Button>
          </Form.Group>
        </Row>
        <Row>
          <Form.Group as={Col} md="6">
            <Form.Check
              size="lg"
              label="CONTINUOUS EXPOSURE"
              type="switch"
              id="continuous_exposure"
              checked={this.state.continuous_exposure === true || false}
              onClick={() => this.toggleContinuousMonitoringModal()}
            />
          </Form.Group>
        </Row>
      </React.Fragment>
    );
  }
}

LastDateExposure.propTypes = {
  has_group_members: PropTypes.bool,
  authenticity_token: PropTypes.string,
  patient: PropTypes.object,
};

export default LastDateExposure;
