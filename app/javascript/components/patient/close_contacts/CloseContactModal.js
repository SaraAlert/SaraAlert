import React from 'react';
import PropTypes from 'prop-types';
import { Button, Modal, Row, Col, Form } from 'react-bootstrap';

import { phoneSchemaValidator } from '../../../utils/Patient';

import _ from 'lodash';
import moment from 'moment';
import * as yup from 'yup';

import DateInput from '../../util/DateInput';
import ReactTooltip from 'react-tooltip';
import PhoneInput from '../../util/PhoneInput';
import InfoTooltip from '../../util/InfoTooltip';

const MAX_NOTES_LENGTH = 2000;

class CloseContactModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      first_name: props.currentCloseContact.first_name,
      last_name: props.currentCloseContact.last_name,
      primary_telephone: props.currentCloseContact.primary_telephone,
      email: props.currentCloseContact.email,
      last_date_of_exposure: props.currentCloseContact.last_date_of_exposure,
      assigned_user: props.currentCloseContact.assigned_user,
      contact_attempts: props.currentCloseContact.contact_attempts,
      notes: props.currentCloseContact.notes || '',
      errors: {},
      isValid:
        (props.currentCloseContact.first_name || props.currentCloseContact.last_name) &&
        (props.currentCloseContact.primary_telephone || props.currentCloseContact.email),
    };
  }

  validateAndSubmit = () => {
    schema
      .validate({ ...this.state }, { abortEarly: false })
      .then(() => {
        this.props.onSave(this.state);
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

  handleNameChange = event => {
    if (event?.target?.value && typeof event.target.value === 'string' && event.target.value.match(/^\s*$/) !== null) {
      // Empty spaces are allowed to be typed (for example, a first name may be 'Mary Beth')
      // But empty starting first spaces should not be allowed
      event.target.value = '';
    }
    this.updateState(_.trim(event.target.id, 'cc_'), event.target.value);
  };

  handlePhoneNumberChange = event => this.updateState('primary_telephone', event.target.value.replace(/-/g, ''));

  handleEmailChange = event => this.updateState('email', event.target.value);

  handleDateChange = event => this.updateState('last_date_of_exposure', event);

  handleNotesChange = event => this.updateState('notes', event.target.value);

  handleAssignedUserChange = event => {
    if (isNaN(event.target.value) || parseInt(event.target.value) > 999999) return;
    // trim() call included since there is a bug with yup validation for numbers that allows whitespace entry
    const value = _.trim(event.target.value) === '' ? null : parseInt(event.target.value);
    this.updateState('assigned_user', value);
  };

  updateState(key, value) {
    this.setState({ [key]: value }, () => {
      let isValid = (this.state.first_name || this.state.last_name) && (this.state.primary_telephone || this.state.email);
      this.setState({
        isValid,
      });
    });
  }

  render() {
    return (
      <Modal size="lg" show centered onHide={this.props.onClose}>
        <h1 className="sr-only">{this.props.title}</h1>
        <Modal.Header>
          <Modal.Title>{this.props.title}</Modal.Title>
        </Modal.Header>
        <Modal.Body className="px-5">
          <Row className="mt-3">
            <Form.Group as={Col} lg="12" controlId="cc_first_name">
              <Form.Label className="input-label">First Name {schema?.fields?.first_name?._exclusive?.required && '*'} </Form.Label>
              <Form.Control size="lg" className="form-square" value={this.state.first_name || ''} onChange={this.handleNameChange} />
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['first_name']}
              </Form.Control.Feedback>
            </Form.Group>
            <Form.Group as={Col} lg="12" controlId="cc_last_name">
              <Form.Label className="input-label">Last Name {schema?.fields?.last_name?._exclusive?.required && '*'} </Form.Label>
              <Form.Control size="lg" className="form-square" value={this.state.last_name || ''} onChange={this.handleNameChange} />
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['last_name']}
              </Form.Control.Feedback>
            </Form.Group>
          </Row>
          <Row>
            <Form.Group as={Col} lg="12" controlId="cc_primary_telephone">
              <Form.Label className="input-label">Phone Number {schema?.fields?.primary_telephone?._exclusive?.required && '*'}</Form.Label>
              <PhoneInput
                id="primary_telephone"
                className="form-square"
                value={this.state.primary_telephone}
                onChange={this.handlePhoneNumberChange}
                isInvalid={!!this.state.errors['primary_telephone']}
              />
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['primary_telephone']}
              </Form.Control.Feedback>
            </Form.Group>
            <Form.Group as={Col} lg="12" controlId="cc_email">
              <Form.Label className="input-label">Email {schema?.fields?.email?._exclusive?.required && '*'} </Form.Label>
              <Form.Control size="lg" className="form-square" value={this.state.email || ''} onChange={this.handleEmailChange} />
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['email']}
              </Form.Control.Feedback>
            </Form.Group>
          </Row>
          <hr></hr>
          <Row>
            <Form.Group as={Col} lg="12" controlId="cc_last_date_of_exposure">
              <Form.Label className="input-label">Last Date of Exposure {schema?.fields?.last_date_of_exposure?._exclusive?.required && '*'}</Form.Label>
              <DateInput
                id="cc_last_date_of_exposure"
                date={this.state.last_date_of_exposure}
                minDate={'2020-01-01'}
                maxDate={moment().add(30, 'days').format('YYYY-MM-DD')}
                onChange={date => this.handleDateChange(date)}
                placement="top"
                isInvalid={!!this.state.errors['last_date_of_exposure']}
                customClass="form-control-lg"
              />
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['last_date_of_exposure']}
              </Form.Control.Feedback>
            </Form.Group>
            <Form.Group as={Col} lg="12" controlId="cc_assigned_user">
              <Form.Label className="input-label">
                Assigned User {schema?.fields?.assigned_user?._exclusive?.required && '*'}
                <InfoTooltip tooltipTextKey="assignedUser" location="top"></InfoTooltip>
              </Form.Label>
              <Form.Control
                isInvalid={this.state.errors['assigned_user']}
                as="input"
                list="cc_assigned_users"
                autoComplete="off"
                size="lg"
                className="d-block"
                onChange={this.handleAssignedUserChange}
                value={this.state.assigned_user || ''}
              />
              <datalist id="cc_assigned_users">
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
              <Form.Label htmlFor="notes" className="input-label">
                Notes
                {schema?.fields?.notes?._exclusive?.required && '*'}
              </Form.Label>
              <Form.Control
                id="notes"
                as="textarea"
                rows="5"
                className="form-square"
                value={this.state.notes || ''}
                placeholder="enter additional information about contact"
                maxLength={MAX_NOTES_LENGTH}
                onChange={this.handleNotesChange}
              />
              <div className="character-limit-text">{MAX_NOTES_LENGTH - this.state.notes.length} characters remaining</div>
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['notes']}
              </Form.Control.Feedback>
            </Form.Group>
          </Row>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.onClose}>
            Cancel
          </Button>
          <Button variant="primary btn-square" disabled={!this.state.isValid} onClick={this.validateAndSubmit}>
            <span data-for="submit-tooltip" data-tip="" className="ml-1">
              {this.props.isEditing ? 'Update' : 'Create'}
            </span>
          </Button>
          {/* Typically we pair the ReactTooltip up directly next to the mount point. However, due to the disabled attribute on the button */}
          {/* above, this Tooltip should be placed outside the parent component (to prevent unwanted parent opacity settings from being inherited) */}
          {/* This does not impact component functionality at all. */}
          {!this.state.isValid && (
            <ReactTooltip id="submit-tooltip" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container text-left">
              Please enter at least one name (First Name or Last Name) and at least one contact method (Phone Number or Email).
            </ReactTooltip>
          )}
        </Modal.Footer>
      </Modal>
    );
  }
}

yup.addMethod(yup.string, 'phone', phoneSchemaValidator);

const schema = yup.object().shape({
  first_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  last_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  primary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  email: yup.string().email('Please enter a valid email.').max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  last_date_of_exposure: yup
    .date('Date must correspond to the "mm/dd/yyyy" format.')
    .min(moment('2020-01-01'), 'Last Date of Exposure must fall after January 1, 2020.')
    .max(moment().add(30, 'days').toDate(), 'Date can not be more than 30 days in the future.')
    .nullable(),
  assigned_user: yup
    .number()
    .typeError('Assigned User must be a number (or left blank)')
    .min(1)
    .max(999999)
    .positive('Please enter a valid Assigned User')
    .nullable(),
  notes: yup.string().max(2000, 'Max length exceeded, please limit to 2000 characters.').nullable(),
});

CloseContactModal.propTypes = {
  title: PropTypes.string,
  currentCloseContact: PropTypes.object,
  onClose: PropTypes.func,
  onSave: PropTypes.func,
  isEditing: PropTypes.bool,
  assigned_users: PropTypes.array,
};

export default CloseContactModal;
