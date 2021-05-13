import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Row, Col, Button, Modal } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import axios from 'axios';
import * as yup from 'yup';
import _ from 'lodash';
import moment from 'moment';
import libphonenumber from 'google-libphonenumber';

const PNF = libphonenumber.PhoneNumberFormat;
const phoneUtil = libphonenumber.PhoneNumberUtil.getInstance();

import confirmDialog from '../../util/ConfirmDialog';
import DateInput from '../../util/DateInput';
import InfoTooltip from '../../util/InfoTooltip';
import PhoneInput from '../../util/PhoneInput';
import reportError from '../../util/ReportError';

const MAX_NOTES_LENGTH = 2000;

class CloseContact extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showModal: false,
      disableCreate:
        (!this.props.close_contact.first_name && !this.props.close_contact.last_name) ||
        (!this.props.close_contact.primary_telephone && !this.props.close_contact.email),
      loading: false,
      errors: {},
      first_name: this.props.close_contact.first_name || '',
      last_name: this.props.close_contact.last_name || '',
      primary_telephone: this.props.close_contact.primary_telephone || '',
      email: this.props.close_contact.email || '',
      last_date_of_exposure: this.props.close_contact.last_date_of_exposure || null,
      assigned_user: this.props.close_contact.assigned_user || null,
      notes: this.props.close_contact.notes || '',
      enrolled_id: this.props.close_contact.enrolled_id || null,
      contact_attempts: this.props.close_contact.contact_attempts || 0,
    };
    this.closeContactNotePlaceholder = this.props.patient.isolation
      ? 'enter additional information about contact'
      : 'enter additional information about monitoree’s potential exposure';
  }

  toggleModal = () => {
    let newState = {
      showModal: !this.state.showModal,
    };
    if (this.state.showModal) {
      // if we currently are showing the modal, that means they clicked cancel
      // (because the rest of this method hasnt had time to fire, and change 'show' to false)
      // When they click cancel, we want to null out all of the fields
      newState = {
        disableCreate:
          (!this.props.close_contact.first_name && !this.props.close_contact.last_name) ||
          (!this.props.close_contact.primary_telephone && !this.props.close_contact.email),
        errors: {},
        first_name: this.props.close_contact.first_name || '',
        last_name: this.props.close_contact.last_name || '',
        primary_telephone: this.props.close_contact.primary_telephone || '',
        email: this.props.close_contact.email || '',
        last_date_of_exposure: this.props.close_contact.last_date_of_exposure || null,
        assigned_user: this.props.close_contact.assigned_user || null,
        notes: this.props.close_contact.notes || '',
        enrolled_id: this.props.close_contact.enrolled_id || null,
        contact_attempts: this.props.close_contact.contact_attempts || 0,
        ...newState, // merge in the flip-flopped value of showModal
      };
    }
    this.setState(newState);
  };

  handleDateChange = event => this.setState({ last_date_of_exposure: event });

  handleChange = event => {
    if (event?.target?.value && typeof event.target.value === 'string' && event.target.value.match(/^\s*$/) !== null) {
      // Empty spaces are allowed to be typed (for example, a first name may be 'Mary Beth')
      // But empty starting first spaces should not be allowed
      event.target.value = '';
    }
    let value;
    if (event?.target?.id && event.target.id === 'assigned_user') {
      if (isNaN(event.target.value) || parseInt(event.target.value) > 999999) return;
      // trim() call included since there is a bug with yup validation for numbers that allows whitespace entry
      value = _.trim(event.target.value) === '' ? null : parseInt(event.target.value);
    } else if (event?.target?.id && event.target.id === 'primary_telephone') {
      value = event.target.value.replace(/-/g, '');
    } else {
      value = event.target.value;
    }
    this.setState({ [event.target.id]: value }, () => {
      let disableCreate = (!this.state.first_name && !this.state.last_name) || (!this.state.primary_telephone && !this.state.email);
      this.setState({
        disableCreate,
      });
    });
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
              primary_telephone: this.state.primary_telephone ? phoneUtil.format(phoneUtil.parse(this.state.primary_telephone, 'US'), PNF.E164) : '',
              email: this.state.email || '',
              last_date_of_exposure: this.state.last_date_of_exposure || null,
              assigned_user: this.state.assigned_user || null,
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
        <h1 className="sr-only">{title}</h1>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body className="px-5">
          <Row className="mt-3">
            <Form.Group as={Col} lg="12" controlId="first_name">
              <Form.Label className="nav-input-label">First Name {schema?.fields?.first_name?._exclusive?.required && '*'} </Form.Label>
              <Form.Control size="lg" className="form-square" value={this.state.first_name || ''} onChange={this.handleChange} />
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['first_name']}
              </Form.Control.Feedback>
            </Form.Group>
            <Form.Group as={Col} lg="12" controlId="last_name">
              <Form.Label className="nav-input-label">Last Name {schema?.fields?.last_name?._exclusive?.required && '*'} </Form.Label>
              <Form.Control size="lg" className="form-square" value={this.state.last_name || ''} onChange={this.handleChange} />
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['last_name']}
              </Form.Control.Feedback>
            </Form.Group>
          </Row>
          <Row>
            <Form.Group as={Col} lg="12" controlId="primary_telephone">
              <Form.Label className="nav-input-label">Phone Number {schema?.fields?.primary_telephone?._exclusive?.required && '*'}</Form.Label>
              <PhoneInput
                id="primary_telephone"
                className="form-square"
                value={this.state.primary_telephone}
                onChange={this.handleChange}
                isInvalid={!!this.state.errors['primary_telephone']}
              />
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['primary_telephone']}
              </Form.Control.Feedback>
            </Form.Group>
            <Form.Group as={Col} lg="12" controlId="email">
              <Form.Label className="nav-input-label">Email {schema?.fields?.email?._exclusive?.required && '*'} </Form.Label>
              <Form.Control size="lg" className="form-square" value={this.state.email || ''} onChange={this.handleChange} />
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['email']}
              </Form.Control.Feedback>
            </Form.Group>
          </Row>
          <hr></hr>
          <Row>
            <Form.Group as={Col} lg="12" controlId="last_date_of_exposure">
              <Form.Label className="nav-input-label">Last Date of Exposure {schema?.fields?.last_date_of_exposure?._exclusive?.required && '*'}</Form.Label>
              <DateInput
                id="last_date_of_exposure"
                date={this.state.last_date_of_exposure}
                minDate={'2020-01-01'}
                maxDate={moment()
                  .add(30, 'days')
                  .format('YYYY-MM-DD')}
                onChange={this.handleDateChange}
                placement="top"
                isInvalid={!!this.state.errors['last_date_of_exposure']}
                customClass="form-control-lg"
                ariaLabel="Last Date of Exposure Input"
              />
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['last_date_of_exposure']}
              </Form.Control.Feedback>
            </Form.Group>
            <Form.Group as={Col} lg="12" controlId="assigned_user">
              <Form.Label className="nav-input-label">
                Assigned User {schema?.fields?.assigned_user?._exclusive?.required && '*'}
                <InfoTooltip tooltipTextKey="assignedUser" location="top"></InfoTooltip>
              </Form.Label>
              <Form.Control
                isInvalid={this.state.errors['assigned_user']}
                as="input"
                list="assigned_users"
                autoComplete="off"
                size="lg"
                className="d-block"
                onChange={this.handleChange}
                value={this.state.assigned_user || ''}
              />
              <datalist id="assigned_users">
                {this.props.assigned_users?.map(num => {
                  return (
                    <option value={num} key={num}>
                      {num}
                    </option>
                  );
                })}
              </datalist>
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['assigned_user']}
              </Form.Control.Feedback>
            </Form.Group>
          </Row>
          <Row>
            <Form.Group as={Col}>
              <Form.Label htmlFor="notes" className="nav-input-label">
                Notes
                {schema?.fields?.notes?._exclusive?.required && '*'}
              </Form.Label>
              <Form.Control
                id="notes"
                as="textarea"
                rows="5"
                className="form-square"
                value={this.state.notes || ''}
                placeholder={this.closeContactNotePlaceholder}
                maxLength={MAX_NOTES_LENGTH}
                onChange={this.handleChange}
              />
              <div className="character-limit-text">{MAX_NOTES_LENGTH - this.state.notes.length} characters remaining</div>
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['notes']}
              </Form.Control.Feedback>
            </Form.Group>
          </Row>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.disableCreate || this.state.loading}>
            <span data-for="create-tooltip" data-tip="" className="ml-1">
              {this.props.close_contact.id ? 'Update' : 'Create'}
            </span>
          </Button>
          {/* Typically we pair the ReactTooltip up directly next to the mount point. However, due to the disabled attribute on the button */}
          {/* above, this Tooltip should be placed outside the parent component (to prevent unwanted parent opacity settings from being inherited) */}
          {/* This does not impact component functionality at all. */}
          {this.state.disableCreate && (
            <ReactTooltip id="create-tooltip" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container text-left">
              Please enter at least one name (First Name or Last Name) and at least one contact method (Phone Number or Email).
            </ReactTooltip>
          )}
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        {!this.props.close_contact.id && (
          <Button onClick={this.toggleModal}>
            <i className="fas fa-plus fa-fw"></i>
            <span className="ml-2">Add New Close Contact</span>
          </Button>
        )}
        {this.props.close_contact.id && (
          <div className="pl-2">
            <React.Fragment>
              <Button variant="link" onClick={this.toggleModal} className="btn btn-link py-0" size="sm">
                <i className="fas fa-edit"></i> Edit
              </Button>
              <div className="pl-2"></div>
              <Button variant="link" onClick={this.contactAttempt} className="btn btn-link py-0" size="sm">
                <i className="fas fa-phone fa-flip-horizontal"></i> Contact Attempt
              </Button>
            </React.Fragment>
          </div>
        )}
        {this.props.close_contact.id && this.props.close_contact.enrolled_id && (
          <div className="pl-2">
            <Button
              variant="link"
              onClick={() => {
                location.href = window.BASE_PATH + '/patients/' + this.props.close_contact.enrolled_id;
              }}
              className="btn btn-link py-0"
              size="sm">
              <i className="fas fa-search"></i> View Record
            </Button>
          </div>
        )}
        {this.props.close_contact.id && !this.props.close_contact.enrolled_id && this.props.can_enroll_patient_close_contacts && (
          <div className="pl-2">
            <Button
              variant="link"
              onClick={() => {
                location.href = window.BASE_PATH + `/patients/new?cc=${this.props.close_contact.id}`;
              }}
              className="btn btn-link py-0"
              size="sm">
              <i className="fas fa-plus"></i> Enroll
            </Button>
          </div>
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
        return !!phoneUtil.format(phoneUtil.parse(value, 'US'), PNF.E164) && /(0|[2-9])\d{9}/.test(value.replace('+1', '').replace(/\D/g, ''));
      } catch (e) {
        return false;
      }
    },
  });
});

const schema = yup.object().shape({
  first_name: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  last_name: yup
    .string()
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
  last_date_of_exposure: yup
    .date('Date must correspond to the "mm/dd/yyyy" format.')
    .min(moment('2020-01-01'), 'Last Date of Exposure must fall after January 1, 2020.')
    .max(
      moment()
        .add(30, 'days')
        .toDate(),
      'Date can not be more than 30 days in the future.'
    )
    .nullable(),
  assigned_user: yup
    .number()
    .typeError('Assigned User must be a number (or left blank)')
    .min(1)
    .max(999999)
    .positive('Please enter a valid Assigned User')
    .nullable(),
  notes: yup
    .string()
    .max(2000, 'Max length exceeded, please limit to 2000 characters.')
    .nullable(),
});

CloseContact.propTypes = {
  close_contact: PropTypes.object,
  can_enroll_patient_close_contacts: PropTypes.bool,
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  assigned_users: PropTypes.array,
};

export default CloseContact;
