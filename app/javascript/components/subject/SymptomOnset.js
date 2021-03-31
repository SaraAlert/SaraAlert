import React from 'react';
import { PropTypes } from 'prop-types';
import { Col, Form, Row } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import axios from 'axios';
import moment from 'moment';

import confirmDialog from '../util/ConfirmDialog';
import DateInput from '../util/DateInput';
import InfoTooltip from '../util/InfoTooltip';
import reportError from '../util/ReportError';

class SymptomOnset extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      symptom_onset: this.props.patient.symptom_onset,
      loading: false,
    };
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

  handleSubmit = async confirmText => {
    if (await confirmDialog(confirmText)) {
      this.submit();
    } else {
      this.setState({ symptom_onset: this.props.patient.symptom_onset });
    }
  };

  submit = () => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          symptom_onset: this.state.symptom_onset,
          user_defined_symptom_onset: true,
          diffState: ['symptom_onset', 'user_defined_symptom_onset'],
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  };

  render() {
    return (
      <React.Fragment>
        <Form.Group as={Col} controlId="symptom_onset">
          <Row className="reports-actions-title">
            <Col>
              <Form.Label className="nav-input-label">
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
                        This date is auto-populated by the system as the date of the earliest report flagged as symptomatic (red highlight) in the reports
                        table. Field is blank when there are no symptomatic reports.
                      </span>
                    )}
                  </ReactTooltip>
                </div>
              </Form.Label>
            </Col>
          </Row>
          <Row>
            <Col>
              <DateInput
                id="symptom_onset"
                date={this.state.symptom_onset}
                minDate={'2020-01-01'}
                maxDate={moment()
                  .add(30, 'days')
                  .format('YYYY-MM-DD')}
                onChange={this.handleDateChange}
                placement="bottom"
                isClearable={this.props.patient.user_defined_symptom_onset}
                customClass="form-control-lg"
                ariaLabel="Symptom Onset Date Input"
              />
            </Col>
          </Row>
          <Row>
            <Col></Col>
          </Row>
        </Form.Group>
      </React.Fragment>
    );
  }
}

SymptomOnset.propTypes = {
  authenticity_token: PropTypes.string,
  patient: PropTypes.object,
};

export default SymptomOnset;
