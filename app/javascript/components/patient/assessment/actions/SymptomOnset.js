import React from 'react';
import { PropTypes } from 'prop-types';
import { Alert, Button, Form, Modal } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import _ from 'lodash';
import axios from 'axios';
import moment from 'moment';

import DateInput from '../../../util/DateInput';
import FirstPositiveLaboratory from '../../laboratory/FirstPositiveLaboratory';
import InfoTooltip from '../../../util/InfoTooltip';
import reportError from '../../../util/ReportError';

class SymptomOnset extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      symptom_onset: this.props.patient.symptom_onset,
      user_defined_symptom_onset: this.props.patient.user_defined_symptom_onset,
      showModal: false,
      loading: false,
    };
    this.origState = Object.assign({}, this.state);
  }

  submit = () => {
    let diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    this.setState({ loading: true }, () => {
      const updates = {
        symptom_onset: this.state.symptom_onset,
        user_defined_symptom_onset: this.state.user_defined_symptom_onset,
        diffState: diffState,
      };
      if (this.state.first_positive_lab) {
        updates['first_positive_lab'] = this.state.first_positive_lab;
      }
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', updates)
        .then(() => {
          location.reload();
        })
        .catch(error => {
          reportError(error);
        });
    });
  };

  openModal = date => {
    if (date !== this.props.patient.symptom_onset) {
      this.setState({
        showModal: true,
        symptom_onset: date,
        user_defined_symptom_onset: !!date,
      });
    }
  };

  closeModal = () => {
    this.setState({
      symptom_onset: this.props.patient.symptom_onset,
      user_defined_symptom_onset: this.props.patient.user_defined_symptom_onset,
      showModal: false,
      first_positive_lab: null,
      showLabModal: false,
    });
  };

  createModal = () => {
    return (
      <Modal size="lg" show centered onHide={this.closeModal}>
        <Modal.Header>
          <Modal.Title>Symptom Onset</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            {this.state.symptom_onset && this.props.patient.user_defined_symptom_onset
              ? `Are you sure you want to manually update the Symptom Onset Date to ${moment(this.state.symptom_onset).format('MM/DD/YYYY')}?`
              : this.state.symptom_onset && !this.props.patient.user_defined_symptom_onset
              ? `Are you sure you want to manually update the Symptom Onset Date to ${moment(this.state.symptom_onset).format(
                  'MM/DD/YYYY'
                )}? Doing so will result in the Symptom Onset Date no longer being auto-populated by the system.`
              : `Are you sure you want to clear the Symptom Onset Date? Doing so will result in the Symptom Onset Date being auto-populated by the system to ${
                  this.props.calculated_symptom_onset ? moment(this.props.calculated_symptom_onset).format('MM/DD/YYYY') : 'blank'
                }.`}
          </p>
          {this.props.patient.isolation && !this.state.symptom_onset && !this.props.symptomatic_assessments_exist && this.props.num_pos_labs === 0 && (
            <React.Fragment>
              <Alert variant="warning" className="mt-2 mb-3 alert-warning-text">
                Warning: Since the Symptom Onset Date will be set to blank, please consider entering a positive lab result in order for this record to be
                eligible to appear on the Records Requiring Review line list as an asymptomatic case.
              </Alert>
              <FirstPositiveLaboratory lab={this.state.first_positive_lab} onChange={lab => this.setState({ first_positive_lab: lab })} />
            </React.Fragment>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.closeModal}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={this.submit} disabled={this.state.loading}>
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
        {this.state.showModal && this.createModal()}
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
            onChange={this.openModal}
            placement="bottom"
            isClearable={this.props.patient.user_defined_symptom_onset}
            customClass="form-control-lg"
            ariaLabel="Symptom Onset Date Input"
          />
        </Form.Group>
      </React.Fragment>
    );
  }
}

SymptomOnset.propTypes = {
  authenticity_token: PropTypes.string,
  patient: PropTypes.object,
  symptomatic_assessments_exist: PropTypes.bool,
  num_pos_labs: PropTypes.number,
  calculated_symptom_onset: function (props) {
    if (props.calculated_symptom_onset && !moment(props.calculated_symptom_onset, 'YYYY-MM-DD').isValid()) {
      return new Error(
        'Invalid prop `calculated_symptom_onset` supplied to `DateInput`, `calculated_symptom_onset` must be a valid date string in the `YYYY-MM-DD` format.'
      );
    }
  },
};

export default SymptomOnset;
