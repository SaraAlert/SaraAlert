import React from 'react';
import { Form, Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';

class ClearReports extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showClearReportsModal: false,
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
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status/clear', {
        reasoning: this.state.reasoning,
      })
      .then(() => {
        location.href = window.BASE_PATH + '/patients/' + this.props.patient.id;
      })
      .catch(error => {
        console.error(error);
      });
  }

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            This will change any reports where the &quot;Needs Review&quot; column is &quot;Yes&quot; to &quot;No&quot;. This subject will be moved from the
            &quot;Symptomatic&quot; line list to either the asymptomatic or non reporting line list as appropriate.
          </p>
          <Form.Group>
            <Form.Label>Please describe your reasoning:</Form.Label>
            <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleChange} />
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="primary btn-square" onClick={submit}>
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
        <Button onClick={this.toggleClearReportsModal}>Mark All As Reviewed</Button>
        {this.state.showClearReportsModal && this.createModal('Mark All As Reviewed', this.toggleClearReportsModal, this.clearReports)}
      </React.Fragment>
    );
  }
}

ClearReports.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.array,
  jurisdiction_id: PropTypes.number,
};

export default ClearReports;
