import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Button, Modal } from 'react-bootstrap';
import axios from 'axios';

import reportError from '../../util/ReportError';

class ClearAssessments extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showClearAssessmentsModal: false,
      loading: false,
    };
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

  ClearAssessments = () => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status/clear', {
          reasoning: this.state.reasoning,
        })
        .then(() => {
          location.reload(true);
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
          <Modal.Title>Mark All As Reviewed</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {!this.props.patient.isolation && (
            <p>
              You are about to clear all symptomatic report flags (red highlight) on this record. This indicates that the disease of interest is not suspected
              after review of all of the monitoree&apos;s symptomatic reports. The &quot;Needs Review&quot; status will be changed to &quot;No&quot; for all
              reports. The record will move from the symptomatic line list to the asymptomatic or non-reporting line list as appropriate
              <b> unless a symptom onset date has been entered by a user.</b>
            </p>
          )}
          {this.props.patient.isolation && (
            <p>
              This will change any reports where the &quot;Needs Review&quot; column is &quot;Yes&quot; to &quot;No&quot;. If this case is currently under the
              &quot;Records Requiring Review&quot; line list, they will be moved to the &quot;Reporting&quot; or &quot;Non-Reporting&quot; line list as
              appropriate until a recovery definition is met.
            </p>
          )}
          <Form.Group>
            <Form.Label>Please describe your reasoning:</Form.Label>
            <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleChange} aria-label="Reasoning Text Area" />
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
        <Button onClick={this.toggleClearAssessmentsModal} className="mr-2">
          <i className="fas fa-check"></i> Mark All As Reviewed
        </Button>
        {this.state.showClearAssessmentsModal && this.createModal(this.toggleClearAssessmentsModal, this.ClearAssessments)}
      </React.Fragment>
    );
  }
}

ClearAssessments.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default ClearAssessments;
