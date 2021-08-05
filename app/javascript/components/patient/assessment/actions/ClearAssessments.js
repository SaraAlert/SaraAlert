import React from 'react';
import { PropTypes } from 'prop-types';
import { Alert, Button, Form, Modal } from 'react-bootstrap';

import _ from 'lodash';
import axios from 'axios';
import moment from 'moment';

import DateInput from '../../../util/DateInput';
import FirstPositiveLaboratory from '../../laboratory/FirstPositiveLaboratory';
import reportError from '../../../util/ReportError';

class ClearAssessments extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      user_defined_symptom_onset: false,
      showClearAssessmentsModal: false,
      loading: false,
    };
    this.origState = Object.assign({}, this.state);
  }

  toggleClearAssessmentsModal = () => {
    let current = this.state.showClearAssessmentsModal;
    this.setState({
      showClearAssessmentsModal: !current,
    });
  };

  handleChange = event => {
    this.setState({ [event.target.id]: event.target.value });
  };

  submit = () => {
    let diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    this.setState({ loading: true }, () => {
      const updates = {
        symptom_onset: this.state.symptom_onset,
        user_defined_symptom_onset: this.state.user_defined_symptom_onset,
        diffState: diffState,
        reasoning: this.state.reasoning,
      };
      if (this.state.first_positive_lab) {
        updates['first_positive_lab'] = this.state.first_positive_lab;
      }
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(`${window.BASE_PATH}/patients/${this.props.patient.id}/status/clear${this.props.assessment_id ? '/' + this.props.assessment_id : ''}`, updates)
        .then(() => {
          location.reload();
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
          <Modal.Title>{this.props.assessment_id ? 'Mark as Reviewed' : 'Mark All As Reviewed'}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {this.props.assessment_id ? (
            <React.Fragment>
              {!this.props.patient.isolation && (
                <p>
                  You are about to clear the symptomatic report flag (red highlight) on this record. This indicates that the disease of interest is not
                  suspected after review of this symptomatic report. The &quot;Needs Review&quot; status will be changed to &quot;No&quot; for this report. The
                  record will move from the symptomatic line list to the asymptomatic or non-reporting line list as appropriate{' '}
                  <b>unless another symptomatic report is present in the reports table or a Symptom Onset Date has been entered by a user.</b>
                </p>
              )}
              {this.props.patient.isolation && (
                <p>
                  This will change the selected report&apos;s &quot;Needs Review&quot; column from &quot;Yes&quot; to &quot;No&quot;. If this case is currently
                  under the &quot;Records Requiring Review&quot; line list, they will be moved to the &quot;Reporting&quot; or &quot;Non-Reporting&quot; line
                  list as appropriate until a recovery definition is met.
                </p>
              )}
            </React.Fragment>
          ) : (
            <React.Fragment>
              {!this.props.patient.isolation && (
                <p>
                  You are about to clear all symptomatic report flags (red highlight) on this record. This indicates that the disease of interest is not
                  suspected after review of all of the monitoree&apos;s symptomatic reports. The &quot;Needs Review&quot; status will be changed to
                  &quot;No&quot; for all reports. The record will move from the symptomatic line list to the asymptomatic or non-reporting line list as
                  appropriate
                  <b> unless a Symptom Onset Date has been entered by a user.</b>
                </p>
              )}
              {this.props.patient.isolation && (
                <p>
                  This will change any reports where the &quot;Needs Review&quot; column is &quot;Yes&quot; to &quot;No&quot;. If this case is currently under
                  the &quot;Records Requiring Review&quot; line list, they will be moved to the &quot;Reporting&quot; or &quot;Non-Reporting&quot; line list as
                  appropriate until a recovery definition is met.
                </p>
              )}
            </React.Fragment>
          )}
          <Form.Group>
            <Form.Label>Please describe your reasoning:</Form.Label>
            <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleChange} aria-label="Reasoning Text Area" />
          </Form.Group>
          {this.props.patient.isolation &&
            !this.props.patient.user_defined_symptom_onset &&
            this.props.num_pos_labs === 0 &&
            (!this.props.assessment_id || this.props.onlySympAssessment) && (
              <React.Fragment>
                <Alert variant="warning" className="my-4 alert-warning-text">
                  Warning: Marking {this.props.assessment_id ? 'this report' : 'all reports'} as reviewed will result in the system populated Symptom Onset Date
                  being cleared. Please consider providing a Symptom Onset Date or entering a positive lab result in order for this record to be eligible to
                  appear on the Records Requiring Review line list.
                </Alert>
                <Form.Label className="input-label">SYMPTOM ONSET</Form.Label>
                <DateInput
                  id="symptom_onset_mark_as_reviewed"
                  date={this.state.symptom_onset}
                  minDate={'2020-01-01'}
                  maxDate={moment().format('YYYY-MM-DD')}
                  onChange={date =>
                    this.setState({
                      symptom_onset: date,
                      user_defined_symptom_onset: !!date,
                    })
                  }
                  placement="bottom"
                  customClass="form-control-lg mb-2"
                  ariaLabel="Symptom Onset Date Input"
                />
                <div className="my-2"></div>
                <FirstPositiveLaboratory lab={this.state.first_positive_lab} onChange={lab => this.setState({ first_positive_lab: lab })} />
              </React.Fragment>
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

  render() {
    return (
      <React.Fragment>
        {this.props.assessment_id ? (
          <Button variant="link" onClick={this.toggleClearAssessmentsModal} className="dropdown-item">
            <i className="fas fa-check fa-fw"></i> Review
          </Button>
        ) : (
          <Button onClick={this.toggleClearAssessmentsModal} className="mr-2">
            <i className="fas fa-check"></i> Mark All As Reviewed
          </Button>
        )}
        {this.state.showClearAssessmentsModal && this.createModal(this.toggleClearAssessmentsModal, this.submit)}
      </React.Fragment>
    );
  }
}

ClearAssessments.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  assessment_id: PropTypes.number,
  num_pos_labs: PropTypes.number,
  onlySympAssessment: PropTypes.bool,
};

export default ClearAssessments;
