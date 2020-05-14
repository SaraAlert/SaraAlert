import React from 'react';
import { Form, Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import reportError from '../util/ReportError';

class ClearReports extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showClearReportsModal: false,
      loading: false,
    };
    this.toggleClearReportsModal = this.toggleClearReportsModal.bind(this);
    this.clearReports = this.clearReports.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  toggleClearReportsModal() {
    let current = this.state.showClearReportsModal;
    this.setState({
      showClearReportsModal: !current,
    });
  }

  handleChange(event) {
    this.setState({ [event.target.id]: event.target.value });
  }

  clearReports() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status/clear', {
          reasoning: this.state.reasoning,
        })
        .then(() => {
          location.href = window.BASE_PATH + '/patients/' + this.props.patient.id;
        })
        .catch(error => {
          reportError(error);
        });
    });
  }

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {!this.props.patient.isolation && (
            <p>
              This will change any reports where the &quot;Needs Review&quot; column is &quot;Yes&quot; to &quot;No&quot;. This subject will be moved from the
              &quot;Symptomatic&quot; line list to either the asymptomatic or non reporting line list as appropriate.
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
            <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleChange} />
          </Form.Group>
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
        <Button onClick={this.toggleClearReportsModal} className="mr-2">
          <i className="fas fa-check"></i> Mark All As Reviewed
        </Button>
        {this.state.showClearReportsModal && this.createModal('Mark All As Reviewed', this.toggleClearReportsModal, this.clearReports)}
      </React.Fragment>
    );
  }
}

ClearReports.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default ClearReports;
