import React from 'react';
import { Form, Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';

class ContactAttempt extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showContactAttemptModal: false,
      comment: '',
      attempt: 'Successful',
    };
    this.toggleContactAttemptModal = this.toggleContactAttemptModal.bind(this);
    this.submit = this.submit.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  toggleContactAttemptModal() {
    let current = this.state.showContactAttemptModal;
    this.setState({
      showContactAttemptModal: !current,
    });
  }

  handleChange(event) {
    this.setState({ [event.target.id]: event.target.value });
  }

  submit() {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(window.BASE_PATH + '/histories', {
        patient_id: this.props.patient.id,
        comment: this.state.attempt + ' contact attempt.' + (this.state.comment ? ' Note: ' + this.state.comment : ''),
        type: 'Contact Attempt',
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
          <Form.Group>
            <Form.Label>Contact was:</Form.Label>
            <Form.Control as="select" size="lg" className="form-square" id="attempt" onChange={this.handleChange}>
              <option>Successful</option>
              <option>Unsuccessful</option>
            </Form.Control>
          </Form.Group>
          <p>Please include any additional details:</p>
          <Form.Group>
            <Form.Control as="textarea" rows="2" id="comment" onChange={this.handleChange} />
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
        <Button onClick={this.toggleContactAttemptModal} className="btn btn-lg" block>
          Add Contact Attempt
        </Button>
        {this.state.showContactAttemptModal && this.createModal('Contact Attempt', this.toggleContactAttemptModal, this.submit)}
      </React.Fragment>
    );
  }
}

ContactAttempt.propTypes = {
  authenticity_token: PropTypes.string,
  patient: PropTypes.object,
};

export default ContactAttempt;
