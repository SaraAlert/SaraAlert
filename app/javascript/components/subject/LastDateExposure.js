import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Row, Col, Button, Modal, OverlayTrigger, Tooltip } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';
import moment from 'moment';

import DateInput from '../util/DateInput';
import InfoTooltip from '../util/InfoTooltip';
import reportError from '../util/ReportError';
import ExtendedIsolation from './ExtendedIsolation';
import SymptomOnset from './SymptomOnset';

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
    this.handleDateChange = this.handleDateChange.bind(this);
    this.closeExposureDateModal = this.closeExposureDateModal.bind(this);
    this.toggleContinuousMonitoringModal = this.toggleContinuousMonitoringModal.bind(this);
    this.createModal = this.createModal.bind(this);
    this.createCEToggle = this.createCEToggle.bind(this);
  }

  toggleContinuousMonitoringModal() {
    this.setState({
      showContinuousMonitoringModal: !this.state.showContinuousMonitoringModal,
      continuous_exposure: !this.state.continuous_exposure,
      apply_to_group: false,
      apply_to_group_cm_only: false,
    });
  }

  closeExposureDateModal() {
    this.setState({
      last_date_of_exposure: this.props.patient.last_date_of_exposure,
      showExposureDateModal: false,
      apply_to_group: false,
      apply_to_group_cm_only: false,
    });
  }

  handleDateChange(date) {
    if (date && date !== this.props.patient.last_date_of_exposure) {
      this.setState({
        last_date_of_exposure: date,
        showExposureDateModal: true,
        apply_to_group: false,
        apply_to_group_cm_only: false,
      });
    } else {
      this.setState({
        last_date_of_exposure: date,
      });
    }
  }

  handleChange(event) {
    event.persist();
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    this.setState({ [event.target.id]: value }, () => {
      if (event.target.id === 'apply_to_monitoree_only') {
        this.setState({ apply_to_group_cm_only: false, apply_to_group: false });
      } else if (event.target.id === 'apply_to_group') {
        this.setState({ apply_to_group_cm_only: false, apply_to_group: true });
      } else if (event.target.id === 'apply_to_group_cm_only') {
        this.setState({ apply_to_group_cm_only: true, apply_to_group: false });
      }
    });
  }

  submit(isLDE) {
    let diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    diffState.push('continuous_exposure'); // Since exposure date updates change CE, always make sure this gets changed
    this.setState({ loading: true, continuous_exposure: diffState.includes('last_date_of_exposure') || isLDE ? false : this.state.continuous_exposure }, () => {
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
    message += this.props.has_group_members ? '(s):' : '.';
    return (
      <Modal size="lg" show centered onHide={toggle}>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>{message}</p>
          {this.props.has_group_members && (
            <Form.Group className="mb-2 px-4">
              <Form.Check
                type="radio"
                id="apply_to_monitoree_only"
                label="This monitoree only"
                onChange={this.handleChange}
                checked={this.state.apply_to_group === false && this.state.apply_to_group_cm_only === false}
              />
            </Form.Group>
          )}
          {this.props.has_group_members && this.state.showExposureDateModal && (
            <Form.Group className="mb-2 px-4">
              <Form.Check
                type="radio"
                id="apply_to_group_cm_only"
                label="This monitoree and only household members where Continuous Exposure is turned ON"
                onChange={this.handleChange}
                checked={this.state.apply_to_group_cm_only === true}
              />
            </Form.Group>
          )}
          {this.props.has_group_members && (
            <Form.Group className="mb-2 px-4">
              <Form.Check
                type="radio"
                id="apply_to_group"
                label="This monitoree and all household members"
                onChange={this.handleChange}
                checked={this.state.apply_to_group === true}
              />
            </Form.Group>
          )}
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

  createCEToggle() {
    return (
      <Form.Check
        size="lg"
        label="CONTINUOUS EXPOSURE"
        id="continuous_exposure"
        disabled={!this.props.patient.monitoring}
        checked={this.state.continuous_exposure}
        onChange={() => this.toggleContinuousMonitoringModal()}
      />
    );
  }

  render() {
    return (
      <React.Fragment>
        {this.state.showExposureDateModal &&
          this.createModal(
            'Last Date of Exposure',
            `Are you sure you want to modify the Last Date of Exposure to ${this.state.last_date_of_exposure}? The Last Date of Exposure will be updated and Continuous Exposure will be turned off for the selected record`,
            this.closeExposureDateModal,
            () => this.submit(true)
          )}
        {this.state.showContinuousMonitoringModal &&
          this.createModal(
            'Continuous Exposure',
            'Are you sure you want to modify Continuous Exposure? Continuous Exposure will be turned for the selected record',
            this.toggleContinuousMonitoringModal,
            () => this.submit(false)
          )}
        <Row>
          <SymptomOnset authenticity_token={this.props.authenticity_token} patient={this.props.patient} />
          <Col>
            <Row className="reports-actions-title">
              <Col>
                <h6 className="nav-input-label">
                  LAST DATE OF EXPOSURE
                  <InfoTooltip tooltipTextKey="lastDateOfExposure" location="right"></InfoTooltip>
                </h6>
              </Col>
            </Row>
            <Row>
              <Col>
                <DateInput
                  id="last_date_of_exposure"
                  date={this.state.last_date_of_exposure}
                  minDate={moment()
                    .subtract(1, 'year')
                    .format('YYYY-MM-DD')}
                  maxDate={moment()
                    .add(30, 'days')
                    .format('YYYY-MM-DD')}
                  onChange={this.handleDateChange}
                  placement="top"
                />
              </Col>
            </Row>
            <Row className="pt-2">
              <Col>
                {!this.props.patient.monitoring && (
                  <OverlayTrigger
                    key="tooltip-ot-ce"
                    placement="left"
                    overlay={
                      <Tooltip id="tooltip-ce">
                        Continuous Exposure cannot be turned for records on the Closed line list. If this monitoree requires monitoring due to a Continuous
                        Exposure, you may update this field after changing Monitoring Status to &quot;Actively Monitoring&quot;
                      </Tooltip>
                    }>
                    <span className="d-inline-block">{this.createCEToggle()}</span>
                  </OverlayTrigger>
                )}
                {this.props.patient.monitoring && <span className="d-inline-block">{this.createCEToggle()}</span>}
                <InfoTooltip tooltipTextKey="continuousExposure" location="right"></InfoTooltip>
              </Col>
            </Row>
          </Col>
          {this.props.patient.isolation ? (
            <ExtendedIsolation authenticity_token={this.props.authenticity_token} patient={this.props.patient} />
          ) : (
            <Col>
              <Row className="reports-actions-title">
                <Col>
                  <span className="nav-input-label">END OF MONITORING</span>
                  <InfoTooltip tooltipTextKey="endOfMonitoring" location="right"></InfoTooltip>
                </Col>
              </Row>
              <Row>
                <Col>{this.props.patient.linelist.end_of_monitoring}</Col>
              </Row>
              <Row>
                <Col></Col>
              </Row>
            </Col>
          )}
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
