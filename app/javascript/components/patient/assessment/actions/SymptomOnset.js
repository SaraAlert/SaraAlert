import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Col, Form, Modal, OverlayTrigger, Tooltip } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import _ from 'lodash';
import axios from 'axios';
import moment from 'moment';

import DateInput from '../../../util/DateInput';
import InfoTooltip from '../../../util/InfoTooltip';
import reportError from '../../../util/ReportError';

class SymptomOnset extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      symptom_onset: this.props.patient.symptom_onset,
      asymptomatic: this.props.patient.asymptomatic || false,
      showSymptomOnsetModal: false,
      showAsymptomaticModal: false,
      loading: false,
    };
    this.origState = Object.assign({}, this.state);
  }

  handleDateChange = date => {
    this.setState({ symptom_onset: date }, () => {
      if (date && this.props.patient.user_defined_symptom_onset) {
        this.handleSubmit('Are you sure you want to manually update the symptom onset date?');
      } else if (date && !this.props.patient.user_defined_symptom_onset) {
        this.handleSubmit(
          'Are you sure you want to manually update the symptom onset date? Doing so will result in the symptom onset date no longer being auto-populated by the system.'
        );
      } else {
        this.handleSubmit(
          'Are you sure you want to clear the symptom onset date? Doing so will result in the symptom onset date being auto-populated by the system.'
        );
      }
    });
  };

  openSymptomOnsetModal = date => {
    if (date !== this.props.patient.symptom_onset) {
      this.setState({
        showSymptomOnsetModal: true,
        symptom_onset: date,
        asymptomatic: date === null,
      });
    }
  };

  openAsymptomaticModal = () => {
    this.setState({
      showAsymptomaticModal: true,
      symptom_onset: null,
      asymptomatic: !this.props.patient.asymptomatic,
    });
  };

  submit = () => {
    let diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    diffState.push('asymptomatic'); // Since symptom onset date updates change NRS, always make sure this gets changed
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          symptom_onset: this.state.symptom_onset,
          user_defined_symptom_onset: true,
          asymptomatic: this.state.asymptomatic,
          diffState: diffState,
        })
        .then(() => {
          location.reload();
        })
        .catch(error => {
          reportError(error);
        });
    });
  };

  closeModal = () => {
    this.setState({
      symptom_onset: this.props.patient.symptom_onset,
      asymptomatic: !!this.props.patient.asymptomatic,
      showSymptomOnsetModal: false,
      showAsymptomaticModal: false,
    });
  };

  createModal = (title, message, close, submit) => {
    return (
      <Modal size="lg" show centered onHide={close}>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>{message}</p>
          {!!this.props.patient.asymptomatic && !this.state.asymptomatic && (
            <div className="mt-2">
              <Form.Label className="input-label">Update Symptom Onset to:</Form.Label>
              <DateInput
                id="symptom_onset"
                date={this.state.symptom_onset}
                maxDate={moment()
                  .add(30, 'days')
                  .format('YYYY-MM-DD')}
                onChange={date => this.setState({ symptom_onset: date })}
                placement="top"
                customClass="form-control-lg"
                ariaLabel="Update Symptom Onset to Input"
              />
            </div>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={close}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.loading || (!this.state.symptom_onset && !this.state.asymptomatic)}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            <span data-for="lde-submit" data-tip="">
              Submit
            </span>
          </Button>
        </Modal.Footer>
      </Modal>
    );
  };

  render() {
    return (
      <React.Fragment>
        {this.state.showSymptomOnsetModal &&
          this.createModal(
            'Symptom Onset',
            this.state.symptom_onset && this.props.patient.user_defined_symptom_onset
              ? `Are you sure you want to manually update the Symptom Onset date to ${moment(this.state.symptom_onset).format(
                  'MM/DD/YYYY'
                )}? Asymptomatic will be ${this.state.asymptomatic ? 'checked' : 'unchecked'}`
              : this.state.symptom_onset && !this.props.patient.user_defined_symptom_onset
              ? `Are you sure you want to manually update the symptom onset date to ${moment(this.state.symptom_onset).format(
                  'MM/DD/YYYY'
                )}? Doing so will result in the symptom onset date no longer being auto-populated by the system and Asymptomatic will be ${
                  this.state.asymptomatic ? 'checked' : 'unchecked'
                }.`
              : 'Are you sure you want to clear the symptom onset date? Doing so will result in the symptom onset date being auto-populated by the system.',
            this.closeModal,
            this.submit
          )}
        {this.state.showAsymptomaticModal &&
          this.createModal(
            'Asymptomatic',
            `Are you sure you want to ${this.state.asymptomatic ? 'check' : 'uncheck'} Asymptomatic? Symptom Onset will ${
              this.state.asymptomatic ? 'be cleared' : 'need to be populated'
            } and Asymptomatic will be ${this.state.asymptomatic ? 'checked' : 'unchecked'} for the selected record.`,
            this.closeModal,
            this.submit
          )}
        <Form.Group controlId="symptom_onset">
          <Form.Label className="input-label">
            SYMPTOM ONSET
            <InfoTooltip tooltipTextKey={this.props.patient.isolation ? 'isolationSymptomOnset' : 'exposureSymptomOnset'} location="right"></InfoTooltip>
            <div style={{ display: 'inline' }}>
              <span data-for="user_defined_symptom_onset_tooltip" data-tip="" className="ml-2">
                {this.props.patient.user_defined_symptom_onset ? <i className="fas fa-user"></i> : <i className="fas fa-desktop"></i>}
              </span>
              <ReactTooltip id="user_defined_symptom_onset_tooltip" multiline={true} place="right" type="dark" effect="solid" className="tooltip-container">
                {this.props.patient.user_defined_symptom_onset ? (
                  <span>This date was set by a user</span>
                ) : (
                  <span>
                    This date is auto-populated by the system as the date of the earliest report flagged as symptomatic (red highlight) in the reports table.
                    Field is blank when there are no symptomatic reports.
                  </span>
                )}
              </ReactTooltip>
            </div>
          </Form.Label>
          <DateInput
            id="symptom_onset"
            date={this.state.symptom_onset}
            minDate={'2020-01-01'}
            maxDate={moment().add(30, 'days').format('YYYY-MM-DD')}
            onChange={this.openSymptomOnsetModal}
            placement="bottom"
            isClearable={this.props.patient.user_defined_symptom_onset}
            customClass="form-control-lg"
            ariaLabel="Symptom Onset Date Input"
          />
          <OverlayTrigger
            key="tooltip-ot-nrs"
            placement="bottom"
            overlay={
              <Tooltip id="tooltip-nrs" style={this.props.symptomatic_assessments_exist ? {} : { display: 'none' }}>
                {`"Asymptomatic" cannot be checked if monitoree has symptomatic reports. If you'd like symptom onset date cleared and this status checked to designate this monitoree as an asymptomatic case, you must review all reports`}
              </Tooltip>
            }>
            <span className="d-inline-block">
              <Form.Check
                size="lg"
                label="ASYMPTOMATIC"
                id="asymptomatic"
                className="mt-2"
                disabled={this.props.symptomatic_assessments_exist}
                checked={this.state.asymptomatic}
                onChange={this.openAsymptomaticModal}
              />
            </span>
          </OverlayTrigger>
          <InfoTooltip tooltipTextKey="asymptomatic" location="right"></InfoTooltip>
        </Form.Group>
      </React.Fragment>
    );
  }
}

SymptomOnset.propTypes = {
  authenticity_token: PropTypes.string,
  patient: PropTypes.object,
  symptomatic_assessments_exist: PropTypes.bool,
};

export default SymptomOnset;
