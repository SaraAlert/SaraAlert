import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Row, Col, Button, Modal } from 'react-bootstrap';
import axios from 'axios';

import reportError from '../util/ReportError';
import confirmDialog from '../util/ConfirmDialog';

class CloseContact extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showModal: false,
      loading: false,
      first_name: this.props.close_contact.first_name || '',
      last_name: this.props.close_contact.last_name || '',
      primary_telephone: this.props.close_contact.primary_telephone || '',
      email: this.props.close_contact.email || '',
      notes: this.props.close_contact.notes || '',
      enrolled_id: this.props.close_contact.enrolled_id || null,
      contact_attempts: this.props.close_contact.contact_attempts || 0,
    };
    this.closeContactNotePlaceholder = this.props.patient.isolation
      ? 'enter additional information about case'
      : 'enter additional information about monitoree’s potential exposure';
    this.toggleModal = this.toggleModal.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.submit = this.submit.bind(this);
    this.contactAttempt = this.contactAttempt.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  toggleModal() {
    let current = this.state.showModal;
    this.setState({
      showModal: !current,
    });
  }

  handleChange(event) {
    this.setState({ [event.target.id]: event.target.value });
  }

  contactAttempt = async () => {
    if (await confirmDialog('Are you sure you want to log an additional contact attempt?', { title: 'New Contact Attempt' })) {
      this.setState({ contact_attempts: this.state.contact_attempts + 1 }, () => {
        this.submit();
      });
    }
  };

  submit() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/close_contacts' + (this.props.close_contact.id ? '/' + this.props.close_contact.id : ''), {
          patient_id: this.props.patient.id,
          first_name: this.state.first_name || '',
          last_name: this.state.last_name || '',
          primary_telephone: this.state.primary_telephone || '',
          email: this.state.email || '',
          notes: this.state.notes || '',
          enrolled_id: this.state.enrolled_id || null,
          contact_attempts: this.state.contact_attempts || 0,
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
      <Modal size="lg" show centered onHide={toggle}>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">First Name</Form.Label>
                <Form.Control size="lg" id="first_name" className="form-square" value={this.state.first_name || ''} onChange={this.handleChange} />
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Last Name</Form.Label>
                <Form.Control size="lg" id="last_name" className="form-square" value={this.state.last_name || ''} onChange={this.handleChange} />
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Phone Number</Form.Label>
                <Form.Control
                  size="lg"
                  id="primary_telephone"
                  className="form-square"
                  value={this.state.primary_telephone || ''}
                  onChange={this.handleChange}
                />
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Email</Form.Label>
                <Form.Control size="lg" id="email" className="form-square" value={this.state.email || ''} onChange={this.handleChange} />
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Notes</Form.Label>
                <Form.Control
                  as="textarea"
                  rows="5"
                  id="notes"
                  className="form-square"
                  value={this.state.notes || ''}
                  placeholder={this.closeContactNotePlaceholder}
                  maxLength="2000"
                  onChange={this.handleChange}
                />
                <Form.Label className="close-contact-character-limit"> {2000 - this.state.notes.length} characters remaining </Form.Label>
              </Form.Group>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
          <Button
            variant="primary btn-square"
            onClick={submit}
            disabled={
              !(this.state.first_name || this.state.last_name || this.state.email || this.state.primary_telephone || this.state.notes) || this.state.loading
            }>
            {this.props.close_contact.id ? 'Update' : 'Create'}
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        {!this.props.close_contact.id && (
          <Button onClick={this.toggleModal}>
            <i className="fas fa-plus"></i> Add New Close Contact
          </Button>
        )}
        {this.props.close_contact.id && (
          <React.Fragment>
            <Button variant="link" onClick={this.toggleModal} className="btn btn-link py-0" size="sm">
              <i className="fas fa-edit"></i> Edit
            </Button>
            <Button variant="link" onClick={this.contactAttempt} className="btn btn-link py-0" size="sm">
              <i className="fas fa-phone"></i> Contact Attempt
            </Button>
          </React.Fragment>
        )}
        {this.props.close_contact.id && this.props.close_contact.enrolled_id && (
          <Button
            variant="link"
            onClick={() => {
              location.href = window.BASE_PATH + '/patients/' + this.props.close_contact.enrolled_id;
            }}
            className="btn btn-link py-0"
            size="sm">
            <i className="fas fa-search"></i> View Record
          </Button>
        )}
        {this.props.close_contact.id && !this.props.close_contact.enrolled_id && this.props.user_role === 'public_health_enroller' && (
          <Button
            variant="link"
            onClick={() => {
              location.href = window.BASE_PATH + `/patients/new?cc=${this.props.close_contact.id}`;
            }}
            className="btn btn-link py-0"
            size="sm">
            <i className="fas fa-plus"></i> Enroll
          </Button>
        )}
        {this.state.showModal && this.createModal('Close Contact', this.toggleModal, this.submit)}
      </React.Fragment>
    );
  }
}

CloseContact.propTypes = {
  close_contact: PropTypes.object,
  user_role: PropTypes.string,
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default CloseContact;
