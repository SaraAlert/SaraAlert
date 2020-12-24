import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Form, Modal } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';

import reportError from '../../util/ReportError';

class CloseRecords extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      apply_to_household: false,
      loading: false,
      monitoring: false,
      monitoring_reason: '',
      reasoning: '',
    };
  }

  handleChange = event => {
    if (event.target.id === 'monitoring_reason') {
      this.setState({ monitoring_reason: event.target.value });
    } else if (event.target.id === 'reasoning') {
      this.setState({ reasoning: event.target.value });
    } else if (event.target.id === 'apply_to_household') {
      this.setState({ apply_to_household: event.target.checked });
    }
  };

  submit = () => {
    let idArray = this.props.patients.map(x => x['id']);
    let diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));

    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/bulk_edit', {
          ids: idArray,
          monitoring: this.state.monitoring,
          monitoring_reason: this.state.monitoring_reason,
          reasoning: this.state.monitoring_reason + (this.state.monitoring_reason !== '' && this.state.reasoning !== '' ? ', ' : '') + this.state.reasoning,
          apply_to_household: this.state.apply_to_household,
          diffState: diffState,
        })
        .then(() => {
          location.href = window.BASE_PATH;
        })
        .catch(error => {
          reportError(error);
          this.setState({ loading: false });
        });
    });
  };

  render() {
    return (
      <React.Fragment>
        <Modal.Body>
          <p>
            <span>
              You are about to change the Monitoring Status of the selected records from &quot;Actively Monitoring&quot; to &quot;Not Monitoring&quot;.
            </span>
            {this.state.monitoring_reason === '' && <span> These records will be moved to the closed line list and the reason for closure will be blank.</span>}
          </p>
          <Form.Group controlId="monitoring_reason">
            <Form.Label>Please select reason for status change:</Form.Label>
            <Form.Control as="select" size="lg" className="form-square" id="monitoring_reason" onChange={this.handleChange} defaultValue={-1}>
              <option></option>
              {this.props.monitoring_reasons.map((option, index) => (
                <option key={`option-${index}`} value={option}>
                  {option}
                </option>
              ))}
            </Form.Control>
          </Form.Group>
          <Form.Group controlId="reasoning">
            <Form.Label>Please include any additional details:</Form.Label>
            <Form.Control as="textarea" rows="2" onChange={this.handleChange} />
          </Form.Group>
          <Form.Group className="my-2">
            <Form.Check
              type="switch"
              id="apply_to_household"
              label="Apply this change to the entire household that these monitorees are responsible for, if it applies."
              checked={this.state.apply_to_household}
              onChange={this.handleChange}
            />
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.close}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={this.submit}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Submit
          </Button>
        </Modal.Footer>
      </React.Fragment>
    );
  }
}

CloseRecords.propTypes = {
  authenticity_token: PropTypes.string,
  patients: PropTypes.array,
  close: PropTypes.func,
  monitoring_reasons: PropTypes.array,
};

export default CloseRecords;
