import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Row, Col, Button, Modal } from 'react-bootstrap';
import axios from 'axios';
import * as yup from 'yup';
import libphonenumber from 'google-libphonenumber';

const PNF = libphonenumber.PhoneNumberFormat;
const phoneUtil = libphonenumber.PhoneNumberUtil.getInstance();

import reportError from '../util/ReportError';
import confirmDialog from '../util/ConfirmDialog';

class CloseContact extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showModal: false,
      loading: false,
      errors: {},
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
  }

  toggleModal = () => {
    let current = this.state.showModal;
    this.setState({
      showModal: !current,
    });
  };

  handleChange = event => {
    this.setState({ [event.target.id]: event.target.value });
  };

  contactAttempt = async () => {
    if (await confirmDialog('Are you sure you want to log an additional contact attempt?', { title: 'New Contact Attempt' })) {
      this.setState({ contact_attempts: this.state.contact_attempts + 1 }, () => {
        this.submit();
      });
    }
  };

  submit = () => {
    schema
      .validate({ ...this.state }, { abortEarly: false })
      .then(() => {
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
      })
      .catch(err => {
        // Validation errors, update state to display to user
        if (err && err.inner) {
          let issues = {};
          for (const issue of err.inner) {
            issues[issue['path']] = issue['errors'];
          }
          this.setState({ errors: issues });
        }
      });
  };

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
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['first_name']}
                </Form.Control.Feedback>
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Last Name</Form.Label>
                <Form.Control size="lg" id="last_name" className="form-square" value={this.state.last_name || ''} onChange={this.handleChange} />
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['last_name']}
                </Form.Control.Feedback>
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
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['primary_telephone']}
                </Form.Control.Feedback>
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Email</Form.Label>
                <Form.Control size="lg" id="email" className="form-square" value={this.state.email || ''} onChange={this.handleChange} />
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['email']}
                </Form.Control.Feedback>
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
                <Form.Label className="notes-character-limit"> {2000 - this.state.notes.length} characters remaining </Form.Label>
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['notes']}
                </Form.Control.Feedback>
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

yup.addMethod(yup.string, 'phone', function() {
  return this.test({
    name: 'phone',
    exclusive: true,
    message: 'Please enter a valid Phone Number',
    test: value => {
      try {
        if (!value) {
          return true; // Blank numbers are allowed
        }
        // Make sure we'll be able to convert to E164 format at submission time
        return !!phoneUtil.format(phoneUtil.parse(value, 'US'), PNF.E164) && /\d{10}/.test(value.replace('+1', '').replace(/\D/g, ''));
      } catch (e) {
        return false;
      }
    },
  });
});

const schema = yup.object().shape({
  first_name: yup
    .string()
    .required('Please enter a First Name.')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  last_name: yup
    .string()
    .required('Please enter a Last Name.')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  primary_telephone: yup
    .string()
    .phone()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  email: yup
    .string()
    .email('Please enter a valid email.')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  notes: yup
    .string()
    .max(2000, 'Max length exceeded, please limit to 2000 characters.')
    .nullable(),
});

CloseContact.propTypes = {
  close_contact: PropTypes.object,
  user_role: PropTypes.string,
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default CloseContact;
