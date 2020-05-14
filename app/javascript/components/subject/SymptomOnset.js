import React from 'react';
import { Form, Row, Col, Button } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import confirmDialog from '../util/ConfirmDialog';
import reportError from '../util/ReportError';
import InfoTooltip from '../util/InfoTooltip';

class SymptomOnset extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      symptom_onset: this.props.patient.symptom_onset,
    };
    this.handleSubmit = this.handleSubmit.bind(this);
    this.submit = this.submit.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.symptomOnsetTooltip = `Used by the system to determine if the non-test based recovery definition
    in the isolation monitoring workflow has been met. This field is auto-populated with the date
    of the earliest symptomatic report in the system unless a user enters an earlier date.`;
  }

  handleChange(event) {
    this.setState({ [event.target.id]: event.target.value });
  }

  handleSubmit = async confirmText => {
    if (await confirmDialog(confirmText)) {
      this.submit();
    }
  };

  submit() {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
        symptom_onset: this.state.symptom_onset,
      })
      .then(() => {
        location.href = window.BASE_PATH + '/patients/' + this.props.patient.id;
      })
      .catch(error => {
        reportError(error);
      });
  }

  render() {
    return (
      <React.Fragment>
        <Row>
          <Form.Group as={Col} md="6">
            <Form.Label className="nav-input-label">
              SYMPTOM ONSET
              <InfoTooltip tooltipText={this.symptomOnsetTooltip} location="right"></InfoTooltip>
            </Form.Label>
            <Form.Control
              size="lg"
              id="symptom_onset"
              type="date"
              className="form-square"
              value={this.state.symptom_onset || ''}
              onChange={this.handleChange}
            />
          </Form.Group>
          <Form.Group as={Col} md="18" className="align-self-end pl-0">
            <Button className="btn-lg" onClick={() => this.handleSubmit('Are you sure you want to modify the symptom onset date?')}>
              <i className="fas fa-temperature-high"></i> Update
            </Button>
          </Form.Group>
        </Row>
      </React.Fragment>
    );
  }
}

SymptomOnset.propTypes = {
  authenticity_token: PropTypes.string,
  patient: PropTypes.object,
};

export default SymptomOnset;
