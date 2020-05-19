import React from 'react';
import { Form, Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import reportError from '../util/ReportError';

class ClearSingleReport extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showClearReportModal: false,
      loading: false,
    };
    this.toggleClearReportModal = this.toggleClearReportModal.bind(this);
    this.clearReport = this.clearReport.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  toggleClearReportModal() {
    let current = this.state.showClearReportModal;
    this.setState({
      showClearReportModal: !current,
    });
  }

  handleChange(event) {
    this.setState({ [event.target.id]: event.target.value });
  }

  clearReport() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status/clear/' + this.props.assessment_id, {
          reasoning: this.state.reasoning,
        })
        .then(() => {
          location.reload(true);
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
              This will change the selected report&apos;s &quot;Needs Review&quot; column from &quot;Yes&quot; to &quot;No&quot;. This subject will be moved
              from the &quot;Symptomatic&quot; line list to either the asymptomatic or non reporting line list as appropriate.
            </p>
          )}
          {this.props.patient.isolation && (
            <p>
              This will change the selected report&apos;s &quot;Needs Review&quot; column from &quot;Yes&quot; to &quot;No&quot;. If this case is currently
              under the &quot;Records Requiring Review&quot; line list, they will be moved to the &quot;Reporting&quot; or &quot;Non-Reporting&quot; line list
              as appropriate until a recovery definition is met.
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
        <Button variant="link" onClick={this.toggleClearReportModal} className="dropdown-item">
          <i className="fas fa-check fa-fw"></i> Review
        </Button>
        {this.state.showClearReportModal && this.createModal('Mark As Reviewed', this.toggleClearReportModal, this.clearReport)}
      </React.Fragment>
    );
  }
}

ClearSingleReport.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  assessment_id: PropTypes.number,
};

export default ClearSingleReport;
