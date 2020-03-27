import React from 'react';
import { Card, Button, Form, Col } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import * as yup from 'yup';
import libphonenumber from 'google-libphonenumber';

const PNF = libphonenumber.PhoneNumberFormat;
const phoneUtil = libphonenumber.PhoneNumberUtil.getInstance();

class Contact extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props, current: { ...this.props.currentState }, errors: {}, modified: {} };
    this.handleChange = this.handleChange.bind(this);
    this.validate = this.validate.bind(this);
    this.updatePrimaryContactMethodValidations = this.updatePrimaryContactMethodValidations.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let modified = this.state.modified;
    this.setState({ current: { ...current, [event.target.id]: value }, modified: { ...modified, [event.target.id]: value } }, () => {
      this.props.setEnrollmentState({ ...this.state.modified });
    });
    this.updatePrimaryContactMethodValidations(event);
  }

  updatePrimaryContactMethodValidations(event) {
    if (event?.currentTarget.id == 'preferred_contact_method') {
      if (
        event?.currentTarget.value == 'Telephone call' ||
        event?.currentTarget.value == 'SMS Text-message' ||
        event?.currentTarget.value == 'SMS Texted Weblink'
      ) {
        schema = yup.object().shape({
          primary_telephone: yup
            .string()
            .phone()
            .required('Please provide a primary telephone number')
            .max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone: yup
            .string()
            .phone()
            .max(200, 'Max length exceeded, please limit to 200 characters.'),
          primary_telephone_type: yup
            .string()
            .required('Please indicate the primary phone type.')
            .max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          email: yup
            .string()
            .email('Please enter a valid email.')
            .max(200, 'Max length exceeded, please limit to 200 characters.'),
          confirm_email: yup.string().oneOf([yup.ref('email'), null], 'Confirm email must match.'),
          preferred_contact_method: yup
            .string()
            .required('Please indicate a preferred contact method.')
            .max(200, 'Max length exceeded, please limit to 200 characters.'),
        });
      } else if (event?.currentTarget.value == 'E-mailed Web Link') {
        schema = yup.object().shape({
          primary_telephone: yup
            .string()
            .phone()
            .max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone: yup
            .string()
            .phone()
            .max(200, 'Max length exceeded, please limit to 200 characters.'),
          primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          email: yup
            .string()
            .email('Please enter a valid email.')
            .required('Please provide an email')
            .max(200, 'Max length exceeded, please limit to 200 characters.'),
          confirm_email: yup
            .string()
            .required('Please confirm email.')
            .oneOf([yup.ref('email'), null], 'Confirm email must match.'),
          preferred_contact_method: yup
            .string()
            .required('Please indicate a preferred contact method.')
            .max(200, 'Max length exceeded, please limit to 200 characters.'),
        });
      }
      this.setState({ errors: {} });
    }
  }

  validate(callback) {
    let self = this;
    schema
      .validate(this.state.current, { abortEarly: false })
      .then(function() {
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
  }

  render() {
    return (
      <React.Fragment>
        <Card className="mx-2 card-square">
          <Card.Header as="h5">Monitoree Contact Information</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row className="pt-2 pb-3">
                <Form.Group as={Col} md="8" controlId="preferred_contact_method">
                  <Form.Label className="nav-input-label">
                    PREFERRED REPORTING METHOD{schema?.fields?.preferred_contact_method?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['preferred_contact_method']}
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.preferred_contact_method || ''}
                    onChange={this.handleChange}>
                    <option></option>
                    <option>E-mailed Web Link</option>
                    <option>SMS Texted Weblink</option>
                    <option>Telephone call</option>
                    <option>SMS Text-message</option>
                  </Form.Control>
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['preferred_contact_method']}
                  </Form.Control.Feedback>
                </Form.Group>
                {this.state.current.preferred_contact_method !== 'E-mailed Web Link' && (
                  <Form.Group as={Col} md="8" controlId="preferred_contact_time">
                    <Form.Label className="nav-input-label">
                      PREFERRED CONTACT TIME{schema?.fields?.preferred_contact_time?._exclusive?.required && ' *'}
                    </Form.Label>
                    <Form.Control
                      isInvalid={this.state.errors['preferred_contact_time']}
                      as="select"
                      size="lg"
                      className="form-square"
                      value={this.state.current.preferred_contact_time || ''}
                      onChange={this.handleChange}>
                      <option></option>
                      <option>Morning</option>
                      <option>Afternoon</option>
                      <option>Evening</option>
                    </Form.Control>
                    <Form.Control.Feedback className="d-block" type="invalid">
                      {this.state.errors['preferred_contact_time']}
                    </Form.Control.Feedback>
                  </Form.Group>
                )}
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="11" controlId="primary_telephone">
                  <Form.Label className="nav-input-label">PRIMARY TELEPHONE NUMBER{schema?.fields?.primary_telephone?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['primary_telephone']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.primary_telephone || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['primary_telephone']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} md="2"></Form.Group>
                <Form.Group as={Col} md="11" controlId="secondary_telephone">
                  <Form.Label className="nav-input-label">
                    SECONDARY TELEPHONE NUMBER{schema?.fields?.secondary_telephone?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['secondary_telephone']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.secondary_telephone || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['secondary_telephone']}
                  </Form.Control.Feedback>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="11" controlId="primary_telephone_type">
                  <Form.Label className="nav-input-label">PRIMARY PHONE TYPE{schema?.fields?.primary_telephone_type?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['primary_telephone_type']}
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.primary_telephone_type || ''}
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
                <Form.Group as={Col} md="2"></Form.Group>
                <Form.Group as={Col} md="11" controlId="secondary_telephone_type">
                  <Form.Label className="nav-input-label">
                    SECONDARY PHONE TYPE{schema?.fields?.secondary_telephone_type?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['secondary_telephone_type']}
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.secondary_telephone_type || ''}
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
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="auto">
                  Smartphone
                  <br />
                  Plain Cell
                  <br />
                  Landline
                </Form.Group>
                <Form.Group as={Col} md="auto">
                  <span className="font-weight-light">Phone capable of accessing web-based reporting tool</span>
                  <br />
                  <span className="font-weight-light">Phone capable of SMS messaging</span>
                  <br />
                  <span className="font-weight-light">Has telephone but cannot use SMS or web-based reporting tool</span>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-3 pb-3">
                <Form.Group as={Col} md="8" controlId="email">
                  <Form.Label className="nav-input-label">E-MAIL ADDRESS{schema?.fields?.email?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['email']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.email || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['email']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} md="8" controlId="confirm_email">
                  <Form.Label className="nav-input-label">CONFIRM E-MAIL ADDRESS{schema?.fields?.confirm_email?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['confirm_email']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.confirm_email || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['confirm_email']}
                  </Form.Control.Feedback>
                </Form.Group>
              </Form.Row>
            </Form>
            {this.props.previous && (
              <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>
                Previous
              </Button>
            )}
            {this.props.next && (
              <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={() => this.validate(this.props.next)}>
                Next
              </Button>
            )}
            {this.props.submit && (
              <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.submit}>
                Finish
              </Button>
            )}
          </Card.Body>
        </Card>
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
        return !!phoneUtil.format(phoneUtil.parse(value, 'US'), PNF.E164);
      } catch (e) {
        return false;
      }
    },
  });
});

var schema = yup.object().shape({
  primary_telephone: yup
    .string()
    .phone()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  secondary_telephone: yup
    .string()
    .phone()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  primary_telephone_type: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  secondary_telephone_type: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  email: yup
    .string()
    .email('Please enter a valid email.')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  confirm_email: yup
    .string()
    .oneOf([yup.ref('email'), null], 'Confirm email must match.')
    .nullable(),
  preferred_contact_method: yup
    .string()
    .required('Please indicate a preferred contact method.')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  preferred_contact_time: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
});

Contact.propTypes = {
  currentState: PropTypes.object,
  previous: PropTypes.func,
  setEnrollmentState: PropTypes.func,
  next: PropTypes.func,
  submit: PropTypes.func,
};

export default Contact;
