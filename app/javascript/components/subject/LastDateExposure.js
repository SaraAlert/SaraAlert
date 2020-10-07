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
      showLastDateOfExposureModal: false,
      showContinuousExposureModal: false,
    };
    this.origState = Object.assign({}, this.state);
    this.handleChange = this.handleChange.bind(this);
    this.submit = this.submit.bind(this);
    this.openContinuousExposureModal = this.openContinuousExposureModal.bind(this);
    this.openLastDateOfExposureModal = this.openLastDateOfExposureModal.bind(this);
    this.closeModal = this.closeModal.bind(this);
    this.createModal = this.createModal.bind(this);
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

  submit() {
    let diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    diffState.push('continuous_exposure'); // Since exposure date updates change CE, always make sure this gets changed
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

  openContinuousExposureModal() {
    this.setState({
      showContinuousExposureModal: true,
      last_date_of_exposure: null,
      continuous_exposure: !this.props.patient.continuous_exposure,
      apply_to_group: false,
      apply_to_group_cm_only: false,
    });
  }

  openLastDateOfExposureModal(date) {
    if (date && date !== this.props.patient.last_date_of_exposure) {
      this.setState({
        showLastDateOfExposureModal: true,
        last_date_of_exposure: date,
        continuous_exposure: false,
        apply_to_group: false,
        apply_to_group_cm_only: false,
      });
    }
  }

  closeModal() {
    this.setState({
      last_date_of_exposure: this.props.patient.last_date_of_exposure,
      continuous_exposure: !!this.props.patient.continuous_exposure,
      showLastDateOfExposureModal: false,
      showContinuousExposureModal: false,
      apply_to_group: false,
      apply_to_group_cm_only: false,
    });
  }

  createModal(title, message, close, submit) {
    const update_continuous_exposure = title === 'Continuous Exposure';
    return (
      <Modal size="lg" show centered onHide={close}>
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
          {this.props.has_group_members && this.state.showLastDateOfExposureModal && (
            <Form.Group className="mb-2 px-4">
              <Form.Check
                type="radio"
                id="apply_to_group_cm_only"
                label={`This monitoree and only household members ${
                  update_continuous_exposure ? 'that are not on the closed line list' : ''
                } where Continuous Exposure is turned ON`}
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
                label={`This monitoree and all household members ${update_continuous_exposure ? 'that are not on the closed line list' : ''}`}
                onChange={this.handleChange}
                checked={this.state.apply_to_group === true}
              />
            </Form.Group>
          )}
          {!!this.props.patient.continuous_exposure && !this.state.continuous_exposure && (
            <div className="mt-2">
              <Form.Label className="nav-input-label">Update Last Date of Exposure to:</Form.Label>
              <DateInput
                id="last_date_of_exposure"
                date={this.state.last_date_of_exposure}
                maxDate={moment()
                  .add(30, 'days')
                  .format('YYYY-MM-DD')}
                onChange={date => this.setState({ last_date_of_exposure: date })}
                placement="top"
              />
            </div>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={close}>
            Cancel
          </Button>
          <Button
            variant="primary btn-square"
            onClick={submit}
            disabled={this.state.loading || (!this.state.last_date_of_exposure && !this.state.continuous_exposure)}>
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
        {this.state.showLastDateOfExposureModal &&
          this.createModal(
            'Last Date of Exposure',
            `Are you sure you want to modify the Last Date of Exposure to ${moment(this.state.last_date_of_exposure).format(
              'MM/DD/YYYY'
            )}? The Last Date of Exposure will be updated and Continuous Exposure will be turned OFF for the selected record${
              this.props.has_group_members ? '(s):' : '.'
            }`,
            this.closeModal,
            this.submit
          )}
        {this.state.showContinuousExposureModal &&
          this.createModal(
            'Continuous Exposure',
            `Are you sure you want to turn ${this.state.continuous_exposure ? 'ON' : 'OFF'} Continuous Exposure? The Last Date of Exposure will ${
              this.state.continuous_exposure ? 'be cleared' : 'need to be populated'
            } and Continuous Exposure will be turned ${this.state.continuous_exposure ? 'ON' : 'OFF'} for the selected record${
              this.props.has_group_members ? '(s):' : '.'
            }`,
            this.closeModal,
            this.submit
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
                  minDate={'2020-01-01'}
                  maxDate={moment()
                    .add(30, 'days')
                    .format('YYYY-MM-DD')}
                  onChange={this.openLastDateOfExposureModal}
                  placement="top"
                  customClass="form-control-lg"
                  isClearable
                />
              </Col>
            </Row>
            <Row className="pt-2">
              <Col>
                <OverlayTrigger
                  key="tooltip-ot-ce"
                  placement="left"
                  overlay={
                    <Tooltip id="tooltip-ce" style={this.props.patient.monitoring ? { display: 'none' } : {}}>
                      Continuous Exposure cannot be turned on or off for records on the Closed line list. If this monitoree requires monitoring due to a
                      Continuous Exposure, you may update this field after changing Monitoring Status to &quot;Actively Monitoring&quot;
                    </Tooltip>
                  }>
                  <span className="d-inline-block">
                    <Form.Check
                      size="lg"
                      label="CONTINUOUS EXPOSURE"
                      id="continuous_exposure"
                      disabled={!this.props.patient.monitoring}
                      checked={this.state.continuous_exposure}
                      onChange={() => this.openContinuousExposureModal()}
                    />
                  </span>
                </OverlayTrigger>
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
