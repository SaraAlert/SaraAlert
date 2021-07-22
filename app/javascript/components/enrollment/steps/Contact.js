import React from 'react';
import { PropTypes } from 'prop-types';
import { Alert, Button, Card, Col, Form } from 'react-bootstrap';

import axios from 'axios';
import libphonenumber from 'google-libphonenumber';
import * as yup from 'yup';

import InfoTooltip from '../../util/InfoTooltip';
import PhoneInput from '../../util/PhoneInput';
import { phoneSchemaValidator } from '../../../utils/Patient';

const PNF = libphonenumber.PhoneNumberFormat;
const phoneUtil = libphonenumber.PhoneNumberUtil.getInstance();

class Contact extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props, current: { ...this.props.currentState }, errors: {}, modified: {} };
  }

  componentDidMount() {
    if (this.props.isEditMode) {
      // Update the Schema Validator by simulating the user changing their preferred_contact_method to what their actual preferred_contact_method really is.
      // This is to trigger schema validation when editing.
      this.updatePrimaryContactMethodValidations({
        currentTarget: {
          id: 'preferred_contact_method',
          value: this.state.current.patient.preferred_contact_method,
        },
      });
    }
    // There are two instances when a user might already have an email that we'd want to prefill the confirm email field
    // One is editing an existing monitoree. The other is when enrolling a close contact
    if (this.state.current.patient.email) {
      this.setState(state => {
        const current = { ...state.current };
        current.patient.confirm_email = state.current.patient.email;
        return { current };
      });
    }
  }

  handleChange = event => {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    if (event.target.id === 'primary_telephone' || event.target.id === 'secondary_telephone') {
      value = value.replace(/-/g, '');
    }

    let blocked_sms = this.state.current.blocked_sms;
    if (event.target.id === 'primary_telephone') {
      if (event.target.value.replace('_', '').length === 12) {
        axios({
          method: 'get',
          url: `${window.BASE_PATH}/patients/sms_eligibility_check`,
          params: { phone_number: phoneUtil.format(phoneUtil.parse(value, 'US'), PNF.E164) },
        })
          .then(response => {
            let sms_eligible = true;
            if (response?.data?.sms_eligible != null) {
              sms_eligible = response.data.sms_eligible;
            }

            let current = this.state.current;
            let modified = this.state.modified;
            this.setState(
              {
                current: { ...current, blocked_sms: !sms_eligible },
                modified: { ...modified, blocked_sms: !sms_eligible },
              },
              () => {
                this.props.setEnrollmentState({ ...this.state.modified });
              }
            );
          })
          .catch(error => {
            console.error(error);
          });
      } else {
        blocked_sms = false;
      }
    }

    let current = this.state.current;
    let modified = this.state.modified;
    this.setState(
      {
        current: { ...current, blocked_sms, patient: { ...current.patient, [event.target.id]: value } },
        modified: { ...modified, blocked_sms, patient: { ...modified.patient, [event.target.id]: value } },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
    this.updatePrimaryContactMethodValidations(event);
  };

  updatePrimaryContactMethodValidations = event => {
    if (event?.currentTarget.id == 'preferred_contact_method') {
      if (
        event?.currentTarget.value === 'Telephone call' ||
        event?.currentTarget.value === 'SMS Text-message' ||
        event?.currentTarget.value === 'SMS Texted Weblink'
      ) {
        schema = yup.object().shape({
          primary_telephone: yup
            .string()
            .phone()
            .required('Please provide a Primary Telephone Number, or change Preferred Reporting Method.')
            .max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          email: yup.string().email('Please enter a valid Email.').max(200, 'Max length exceeded, please limit to 200 characters.'),
          confirm_email: yup.string().oneOf([yup.ref('email'), null], 'Confirm Email must match.'),
          preferred_contact_method: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        });
      } else if (event?.currentTarget.value === 'E-mailed Web Link') {
        schema = yup.object().shape({
          primary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          email: yup
            .string()
            .email('Please enter a valid Email.')
            .required('Please provide an Email or change Preferred Reporting Method')
            .max(200, 'Max length exceeded, please limit to 200 characters.'),
          confirm_email: yup
            .string()
            .required('Please confirm Email.')
            .oneOf([yup.ref('email'), null], 'Confirm Email must match.'),
          preferred_contact_method: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        });
      } else {
        schema = yup.object().shape({
          primary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          email: yup.string().email('Please enter a valid Email.').max(200, 'Max length exceeded, please limit to 200 characters.'),
          confirm_email: yup.string().oneOf([yup.ref('email'), null], 'Confirm Email must match.'),
          preferred_contact_method: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        });
      }
    } else if (event?.currentTarget.id === 'primary_telephone') {
      schema = yup.object().shape({
        primary_telephone: yup
          .string()
          .phone()
          .max(200, 'Max length exceeded, please limit to 200 characters.')
          .nullable()
          .when('preferred_contact_method', pcm => {
            if (pcm && ['Telephone call', 'SMS Text-message', 'SMS Texted Weblink'].includes(pcm)) {
              return yup.string().phone().required('Please provide a Primary Telephone Number, or change Preferred Reporting Method.');
            }
          }),
        secondary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
        primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        email: yup.string().email('Please enter a valid Email.').max(200, 'Max length exceeded, please limit to 200 characters.'),
        confirm_email: yup.string().oneOf([yup.ref('email'), null], 'Confirm Email must match.'),
        preferred_contact_method: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
      });
    }
    this.setState({ errors: {} });
  };

  validate = callback => {
    let self = this;
    schema
      .validate(this.state.current.patient, { abortEarly: false })
      .then(() => {
        // No validation issues? Invoke callback (move to next step)
        self.setState({ errors: {} }, () => {
          callback();
        });
      })
      .catch(err => {
        // Validation errors, update state to display to user
        if (err && err.inner) {
          let issues = {};
          for (var issue of err.inner) {
            issues[issue['path']] = issue['errors'];
          }
          self.setState({ errors: issues });
        }
      });
  };

  renderWarningBanner = (message, showTooltip) => {
    return (
      <Form.Group as={Col} className="mt-1 mb-3 mb-lg-0" sm={{ span: 24, order: 2 }} lg={{ span: 24, order: 3 }}>
        <Alert variant="danger" className="mb-0">
          <b>Warning:</b> {message}
          {showTooltip && <InfoTooltip tooltipTextKey="blockedSMSContactMethod" location="right" />}
        </Alert>
      </Form.Group>
    );
  };

  render() {
    return (
      <React.Fragment>
        <h1 className="sr-only">Monitoree Contact Information</h1>
        <Card className="mx-2 card-square">
          <Card.Header className="h5">Monitoree Contact Information</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row>
                <Form.Group as={Col} lg="12" controlId="preferred_contact_method">
                  <Form.Label className="input-label">
                    PREFERRED REPORTING METHOD{schema?.fields?.preferred_contact_method?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['preferred_contact_method']}
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.preferred_contact_method || ''}
                    onChange={this.handleChange}>
                    <option></option>
                    <option>Unknown</option>
                    <option>E-mailed Web Link</option>
                    <option>SMS Texted Weblink</option>
                    <option>Telephone call</option>
                    <option>SMS Text-message</option>
                    <option>Opt-out</option>
                  </Form.Control>
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['preferred_contact_method']}
                  </Form.Control.Feedback>
                </Form.Group>
                {(this.state.current.patient.preferred_contact_method === 'SMS Texted Weblink' ||
                  this.state.current.patient.preferred_contact_method === 'Telephone call' ||
                  this.state.current.patient.preferred_contact_method === 'SMS Text-message' ||
                  this.state.current.patient.preferred_contact_method === 'E-mailed Web Link') && (
                  <Form.Group as={Col} lg="12" controlId="preferred_contact_time">
                    <Form.Label className="input-label">
                      PREFERRED CONTACT TIME{schema?.fields?.preferred_contact_time?._exclusive?.required && ' *'}
                      <InfoTooltip tooltipTextKey="preferredContactTime" location="right"></InfoTooltip>
                    </Form.Label>
                    <Form.Control
                      isInvalid={this.state.errors['preferred_contact_time']}
                      as="select"
                      size="lg"
                      className="form-square"
                      value={this.state.current.patient.preferred_contact_time || ''}
                      onChange={this.handleChange}>
                      <option></option>
                      <option>Morning</option>
                      <option>Afternoon</option>
                      <option>Evening</option>
                    </Form.Control>
                    <div className="mt-3">
                      <span className="font-weight-bold">Morning: </span>
                      <span className="font-weight-light">Between 8:00 and 12:00 in monitoree&apos;s timezone</span>
                      <br />
                      <span className="font-weight-bold">Afternoon: </span>
                      <span className="font-weight-light">Between 12:00 and 16:00 in monitoree&apos;s timezone</span>
                      <br />
                      <span className="font-weight-bold">Evening: </span>
                      <span className="font-weight-light">Between 16:00 and 20:00 in monitoree&apos;s timezone</span>
                    </div>
                    <Form.Control.Feedback className="d-block" type="invalid">
                      {this.state.errors['preferred_contact_time']}
                    </Form.Control.Feedback>
                  </Form.Group>
                )}
              </Form.Row>
              <Form.Row className="mb-4">
                <Form.Group as={Col} className="mb-0" sm={{ span: 24, order: 1 }} lg={{ span: 12, order: 1 }} controlId="primary_telephone">
                  <Form.Label className="input-label">PRIMARY TELEPHONE NUMBER{schema?.fields?.primary_telephone?._exclusive?.required && ' *'}</Form.Label>
                  {this.state.current.blocked_sms && (
                    <span className="float-right font-weight-bold">
                      SMS Blocked
                      <InfoTooltip tooltipTextKey="blockedSMS" location="right" />
                    </span>
                  )}
                  <PhoneInput
                    id="primary_telephone"
                    value={this.state.current.patient.primary_telephone}
                    onChange={this.handleChange}
                    isInvalid={!!this.state.errors['primary_telephone']}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['primary_telephone']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} className="mb-0" sm={{ span: 24, order: 3 }} lg={{ span: 12, order: 2 }} controlId="secondary_telephone">
                  <Form.Label className="input-label">SECONDARY TELEPHONE NUMBER{schema?.fields?.secondary_telephone?._exclusive?.required && ' *'}</Form.Label>
                  <PhoneInput
                    id="secondary_telephone"
                    value={this.state.current.patient.secondary_telephone}
                    onChange={this.handleChange}
                    isInvalid={!!this.state.errors['secondary_telephone']}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['secondary_telephone']}
                  </Form.Control.Feedback>
                </Form.Group>
                {this.state.current.patient?.preferred_contact_method?.includes('SMS') &&
                  this.state.current.blocked_sms &&
                  this.renderWarningBanner('SMS-based reporting selected and this phone number has blocked SMS communications with Sara Alert)', true)}
              </Form.Row>
              <Form.Row className="mb-3">
                <Form.Group as={Col} className="mb-0" sm={{ span: 24, order: 1 }} lg={{ span: 12, order: 1 }} controlId="primary_telephone_type">
                  <Form.Label className="input-label">PRIMARY PHONE TYPE{schema?.fields?.primary_telephone_type?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['primary_telephone_type']}
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.primary_telephone_type || ''}
                    onChange={this.handleChange}>
                    <option></option>
                    <option>Smartphone</option>
                    <option>Plain Cell</option>
                    <option>Landline</option>
                  </Form.Control>
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['primary_telephone_type']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} className="mb-0" sm={{ span: 24, order: 3 }} lg={{ span: 12, order: 2 }} controlId="secondary_telephone_type">
                  <Form.Label className="input-label">SECONDARY PHONE TYPE{schema?.fields?.secondary_telephone_type?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['secondary_telephone_type']}
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.secondary_telephone_type || ''}
                    onChange={this.handleChange}>
                    <option></option>
                    <option>Smartphone</option>
                    <option>Plain Cell</option>
                    <option>Landline</option>
                  </Form.Control>
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['secondary_telephone_type']}
                  </Form.Control.Feedback>
                </Form.Group>
                {this.state.current.patient.preferred_contact_method === 'SMS Texted Weblink' &&
                  this.state.current.patient.primary_telephone_type == 'Plain Cell' &&
                  this.renderWarningBanner(
                    'Plain cell phones cannot receive web-links. Please make sure the monitoree has a compatible device to receive this type of message.'
                  )}
                {this.state.current.patient.preferred_contact_method === 'SMS Texted Weblink' &&
                  this.state.current.patient.primary_telephone_type == 'Landline' &&
                  this.renderWarningBanner(
                    'Landline phones cannot receive web-links. Please make sure the monitoree has a compatible device to receive this type of message.'
                  )}
                {this.state.current.patient.preferred_contact_method === 'SMS Text-message' &&
                  this.state.current.patient.primary_telephone_type === 'Landline' &&
                  this.renderWarningBanner(
                    'Landline phones cannot receive text messages. Please make sure the monitoree has a compatible device to receive this type of message.'
                  )}
              </Form.Row>
              <Form.Row>
                <Form.Group as={Col}>
                  <div>
                    <span className="font-weight-bold">Smartphone: </span>
                    <span className="font-weight-light">Phone capable of accessing web-based reporting tool</span>
                    <br />
                    <span className="font-weight-bold">Plain Cell: </span>
                    <span className="font-weight-light">Phone capable of SMS messaging</span>
                    <br />
                    <span className="font-weight-bold">Landline: </span>
                    <span className="font-weight-light">Has telephone but cannot use SMS or web-based reporting tool</span>
                  </div>
                </Form.Group>
              </Form.Row>
              <Form.Row className="mt-2">
                <Form.Group as={Col} lg="12" controlId="email">
                  <Form.Label className="input-label">E-MAIL ADDRESS{schema?.fields?.email?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['email']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.email || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['email']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} lg="12" controlId="confirm_email">
                  <Form.Label className="input-label">CONFIRM E-MAIL ADDRESS{schema?.fields?.confirm_email?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['confirm_email']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.confirm_email || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['confirm_email']}
                  </Form.Control.Feedback>
                </Form.Group>
              </Form.Row>
            </Form>
            {this.props.previous && !this.props.hidePreviousButton && !this.props.isEditMode && (
              <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>
                Previous
              </Button>
            )}
            {this.props.next && (
              <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={() => this.validate(this.props.next)}>
                Next
              </Button>
            )}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

yup.addMethod(yup.string, 'phone', phoneSchemaValidator);

var schema = yup.object().shape({
  primary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  secondary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  email: yup.string().email('Please enter a valid Email.').max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  confirm_email: yup
    .string()
    .oneOf([yup.ref('email'), null], 'Confirm Email must match.')
    .nullable(),
  preferred_contact_method: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  preferred_contact_time: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
});

Contact.propTypes = {
  currentState: PropTypes.object,
  setEnrollmentState: PropTypes.func,
  previous: PropTypes.func,
  next: PropTypes.func,
  hidePreviousButton: PropTypes.bool,
  isEditMode: PropTypes.bool,
};

export default Contact;
