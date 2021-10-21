import React from 'react';
import { PropTypes } from 'prop-types';
import { Alert, Button, Card, Col, Form, Modal, Nav, Tab } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faExclamationCircle } from '@fortawesome/free-solid-svg-icons';

import axios from 'axios';
import libphonenumber from 'google-libphonenumber';
import * as yup from 'yup';
import Select from 'react-select';

import InfoTooltip from '../../util/InfoTooltip';
import PhoneInput from '../../util/PhoneInput';
import { phoneSchemaValidator } from '../../../utils/PatientFormatters';
import {
  customPreferredContactTimeOptions,
  customPreferredContactTimeGroupedOptions,
  basicPreferredContactTimeOptions,
} from '../../../data/preferredContactTimeOptions';
import {
  preferredContactTimeSelectStyling,
  customPreferredContactTimeSelectStyling,
  bootstrapSelectTheme,
} from '../../../packs/stylesheets/ReactSelectStyling';

const PNF = libphonenumber.PhoneNumberFormat;
const phoneUtil = libphonenumber.PhoneNumberUtil.getInstance();

class Contact extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      current: { ...this.props.currentState },
      errors: {},
      modified: {},
      selectedTab: 'primary',
      showPrimaryValidationIcon: false,
      showAlternateValidationIcon: false,
      showCustomPreferredContactTimeModal: false,
      custom_preferred_contact_time_confirmed: false,
    };
  }

  componentDidMount() {
    if (this.props.edit_mode) {
      // Update the Schema Validator by simulating the user changing their preferred_contact_method to what their actual preferred_contact_method really is.
      // This is to trigger schema validation when editing.
      this.updateContactMethodValidations({
        currentTarget: {
          id: 'preferred_contact_method',
          value: this.state.current.patient.preferred_contact_method,
        },
      });
    }

    // There are two instances when a user might already have an email or alt email that we'd want to prefill the confirm email field
    // One is editing an existing monitoree. The other is when enrolling a close contact
    // Always preset the confirm email field to the defined email OR null (this is to ensure the yup validation works)
    // email and alternate_email fields MUST be set to null if they are undefined in order for the yup validation to work as well
    this.setState(state => {
      const current = { ...state.current };
      current.patient.email = state.current.patient.email || '';
      current.patient.alternate_email = state.current.patient.alternate_email || '';
      current.patient.confirm_email = state.current.patient.email || '';
      current.patient.confirm_alternate_email = state.current.patient.alternate_email || '';
      return { current };
    });
  }

  handleChange = event => {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    if (event.target.id === 'primary_telephone' || event.target.id === 'secondary_telephone') {
      value = value.replace(/-/g, '');
    } else if (event.target.id === 'international_telephone') {
      value = value.replace(/[^0-9.\-()+ ]/g, '');
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

    if (event.target.id === 'preferred_contact_time' && event.target.value === 'Custom...') {
      this.setState({ showCustomPreferredContactTimeModal: true });
    }

    let current = this.state.current;
    let modified = this.state.modified;
    const updates = { [event.target.id]: value };

    // Clear contact name if contact type is set to self reporter (for primary and alternate)
    if (event.target.id === 'contact_type' || event.target.id === 'alternate_contact_type') {
      if (event.target.value === 'Self') {
        updates[event.target.id.replace('type', 'name')] = '';
      }
    }

    this.setState(
      {
        current: { ...current, blocked_sms, patient: { ...current.patient, ...updates } },
        modified: { ...modified, blocked_sms, patient: { ...modified.patient, ...updates } },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
    this.updateContactMethodValidations(event);
  };

  updateContactMethodValidations = event => {
    if (event?.currentTarget.id == 'preferred_contact_method') {
      if (
        event?.currentTarget.value === 'Telephone call' ||
        event?.currentTarget.value === 'SMS Text-message' ||
        event?.currentTarget.value === 'SMS Texted Weblink'
      ) {
        schema = yup.object().shape({
          contact_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          contact_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          primary_telephone: yup
            .string()
            .phone()
            .required('Please provide a Primary Telephone Number, or change Preferred Reporting Method.')
            .max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          international_telephone: yup.string().max(50, 'Max length exceeded, please limit to 50 characters.'),
          email: yup.string().email('Please enter a valid Email.').max(200, 'Max length exceeded, please limit to 200 characters.'),
          confirm_email: yup.string().oneOf([yup.ref('email'), null], 'Confirm Email must match.'),
          preferred_contact_method: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_contact_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_contact_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_primary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_secondary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_international_telephone: yup.string().max(50, 'Max length exceeded, please limit to 50 characters.'),
          alternate_email: yup.string().email('Please enter a valid Email.').max(200, 'Max length exceeded, please limit to 200 characters.'),
          confirm_alternate_email: yup.string().oneOf([yup.ref('alternate_email'), null], 'Confirm Email must match.'),
          alternate_preferred_contact_method: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_preferred_contact_time: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        });
      } else if (event?.currentTarget.value === 'E-mailed Web Link') {
        schema = yup.object().shape({
          contact_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          contact_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          primary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          international_telephone: yup.string().max(50, 'Max length exceeded, please limit to 50 characters.'),
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
          alternate_contact_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_contact_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_primary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_secondary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_international_telephone: yup.string().max(50, 'Max length exceeded, please limit to 50 characters.'),
          alternate_email: yup.string().email('Please enter a valid Email.').max(200, 'Max length exceeded, please limit to 200 characters.'),
          confirm_alternate_email: yup.string().oneOf([yup.ref('alternate_email'), null], 'Confirm Email must match.'),
          alternate_preferred_contact_method: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_preferred_contact_time: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        });
      } else {
        schema = yup.object().shape({
          contact_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          contact_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          primary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          international_telephone: yup.string().max(50, 'Max length exceeded, please limit to 50 characters.'),
          email: yup.string().email('Please enter a valid Email.').max(200, 'Max length exceeded, please limit to 200 characters.'),
          confirm_email: yup.string().oneOf([yup.ref('email'), null], 'Confirm Email must match.'),
          preferred_contact_method: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_contact_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_contact_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_primary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_secondary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_international_telephone: yup.string().max(50, 'Max length exceeded, please limit to 50 characters.'),
          alternate_email: yup.string().email('Please enter a valid Email.').max(200, 'Max length exceeded, please limit to 200 characters.'),
          confirm_alternate_email: yup.string().oneOf([yup.ref('alternate_email'), null], 'Confirm Email must match.'),
          alternate_preferred_contact_method: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
          alternate_preferred_contact_time: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        });
      }
    } else if (event?.currentTarget.id === 'primary_telephone') {
      schema = yup.object().shape({
        contact_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        contact_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
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
        international_telephone: yup.string().max(50, 'Max length exceeded, please limit to 50 characters.'),
        email: yup.string().email('Please enter a valid Email.').max(200, 'Max length exceeded, please limit to 200 characters.'),
        confirm_email: yup.string().oneOf([yup.ref('email'), null], 'Confirm Email must match.'),
        preferred_contact_method: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        alternate_contact_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        alternate_contact_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        alternate_primary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
        alternate_secondary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.'),
        alternate_primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        alternate_secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        alternate_international_telephone: yup.string().max(50, 'Max length exceeded, please limit to 50 characters.'),
        alternate_email: yup.string().email('Please enter a valid Email.').max(200, 'Max length exceeded, please limit to 200 characters.'),
        confirm_alternate_email: yup.string().oneOf([yup.ref('alternate_email'), null], 'Confirm Email must match.'),
        alternate_preferred_contact_method: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
        alternate_preferred_contact_time: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
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
        self.setState({ errors: {}, showPrimaryValidationIcon: false, showAlternateValidationIcon: false }, () => {
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
          self.setState({ errors: issues }, () => {
            let showPrimaryValidationIcon = false;
            let showAlternateValidationIcon = false;
            if (this.state.selectedTab === 'primary') {
              showAlternateValidationIcon = Object.keys(issues).filter(key => key.includes('alternate')).length > 0;
            } else {
              showPrimaryValidationIcon = Object.keys(issues).filter(key => !key.includes('alternate')).length > 0;
            }
            self.setState({ showPrimaryValidationIcon, showAlternateValidationIcon });
          });
        }
      });
  };

  closePreferredContactTimeModal = () => {
    this.setState(
      state => {
        return {
          showCustomPreferredContactTimeModal: false,
          custom_preferred_contact_time: null,
          custom_preferred_contact_time_confirmed: false,
          current: { ...state.current, patient: { ...state.current.patient, preferred_contact_time: this.props.patient.preferred_contact_time } },
          modified: { ...state.modified, patient: { ...state.modified.patient, preferred_contact_time: this.props.patient.preferred_contact_time } },
        };
      },
      () => this.props.setEnrollmentState({ ...this.state.modified })
    );
  };

  renderInvalidIcon = () => {
    return (
      <div style={{ display: 'inline' }}>
        <span data-for="invalid-fields" data-tip="">
          <FontAwesomeIcon className="text-danger ml-1" icon={faExclamationCircle} />
        </span>
        <ReactTooltip id="invalid-fields" multiline={true} place="right" effect="solid" className="tooltip-container">
          All required fields in this tab must be completed and properly formatted before proceeding
        </ReactTooltip>
      </div>
    );
  };

  renderWarningBanner = (message, showTooltip, variant) => {
    return (
      <Alert variant={variant || 'danger'} className="mb-0">
        <b>Warning:</b> {message}
        {showTooltip && <InfoTooltip tooltipTextKey="blockedSMSContactMethod" location="right" />}
      </Alert>
    );
  };

  renderPreferredContactTimeModal = () => {
    return (
      <Modal size="mdlg" show={this.state.showCustomPreferredContactTimeModal} onHide={this.closePreferredContactTimeModal} centered>
        <Modal.Header closeButton>
          <Modal.Title>Custom Preferred Contact Time</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            You may specify a preferred contact time outside normal hours for this monitoree. This is the <b>earliest</b> time that any reminder would be sent
            to the monitoree for that day.
          </p>
          <Select
            inputId="custom_preferred_contact_time-select"
            name="custom_preferred_contact_time"
            options={customPreferredContactTimeGroupedOptions}
            onChange={e => this.setState({ custom_preferred_contact_time: e.value })}
            placeholder="Select custom preferred contact time..."
            className="mb-3"
            styles={customPreferredContactTimeSelectStyling}
            theme={theme => bootstrapSelectTheme(theme, 'lg')}
          />
          <p className="text-muted">
            Reminders and contact attempts outside of normal hours of 8:00 to 20:00 should only be done with the consent of the monitoree. Please indicate that
            you have confirmed this time with the monitoree before continuing.
          </p>
          <Form.Check
            size="lg"
            className="form-square"
            id="confirm_custom_preferred_contact_time"
            label="I have confirmed with the monitoree that they agree to be contacted at this time"
            checked={this.state.custom_preferred_contact_time_confirmed}
            disabled={!this.state.custom_preferred_contact_time}
            onChange={() =>
              this.setState(state => {
                return { ...state, custom_preferred_contact_time_confirmed: !state.custom_preferred_contact_time_confirmed };
              })
            }
          />
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={() => this.setState(this.closePreferredContactTimeModal)}>
            Cancel
          </Button>
          <Button
            variant="primary btn-square"
            disabled={!this.state.custom_preferred_contact_time || !this.state.custom_preferred_contact_time_confirmed}
            onClick={() => {
              this.handleChange({
                target: { id: 'preferred_contact_time', value: this.state.custom_preferred_contact_time },
                currentTarget: { id: 'preferred_contact_time' },
              });
              this.setState({ showCustomPreferredContactTimeModal: false, custom_preferred_contact_time_confirmed: false });
            }}>
            Submit
          </Button>
        </Modal.Footer>
      </Modal>
    );
  };

  renderContactFields(alternate) {
    const prefix = alternate ? 'alternate_' : '';
    return (
      <Form>
        <Form.Row>
          <Form.Group as={Col} lg="12" controlId={`${prefix}contact_type`}>
            <Form.Label className="input-label">
              CONTACT RELATIONSHIP{schema?.fields[`${prefix}contact_type`]?._exclusive?.required && ' *'}
              <InfoTooltip tooltipTextKey="contactRelationship" location="right"></InfoTooltip>
            </Form.Label>
            <Form.Control
              isInvalid={this.state.errors[`${prefix}contact_type`]}
              as="select"
              size="lg"
              className="form-square"
              value={this.state.current.patient[`${prefix}contact_type`] || ''}
              onChange={this.handleChange}>
              {alternate && <option></option>}
              <option>Self</option>
              <option>Parent/Guardian</option>
              <option>Spouse/Partner</option>
              <option>Caregiver</option>
              <option>Healthcare Provider</option>
              <option>Facility Representative</option>
              <option>Group Home Manager/Administrator</option>
              <option>Surrogate/Proxy</option>
              <option>Other</option>
              <option>Unknown</option>
            </Form.Control>
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors[`${prefix}contact_type`]}
            </Form.Control.Feedback>
          </Form.Group>
          {this.state.current.patient[`${prefix}contact_type`] !== 'Self' && (
            <Form.Group as={Col} lg="12" controlId={`${prefix}contact_name`}>
              <Form.Label className="input-label">CONTACT NAME{schema?.fields[`${prefix}contact_name`]?._exclusive?.required && ' *'}</Form.Label>
              <Form.Control
                isInvalid={this.state.errors[`${prefix}contact_name`]}
                size="lg"
                className="form-square"
                value={this.state.current.patient[`${prefix}contact_name`] || ''}
                onChange={this.handleChange}
              />
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors[`${prefix}contact_name`]}
              </Form.Control.Feedback>
            </Form.Group>
          )}
        </Form.Row>
        <Form.Row>
          <Form.Group as={Col} lg="12" controlId={`${prefix}preferred_contact_method`}>
            <Form.Label className="input-label">
              PREFERRED {alternate ? 'CONTACT' : 'REPORTING'} METHOD{schema?.fields[`${prefix}preferred_contact_method`]?._exclusive?.required && ' *'}
            </Form.Label>
            <Form.Control
              isInvalid={this.state.errors[`${prefix}preferred_contact_method`]}
              as="select"
              size="lg"
              className="form-square"
              value={this.state.current.patient[`${prefix}preferred_contact_method`] || ''}
              onChange={this.handleChange}>
              <option></option>
              <option>Unknown</option>
              {!alternate && <option>E-mailed Web Link</option>}
              {alternate && <option>Email</option>}
              {!alternate && <option>SMS Texted Weblink</option>}
              <option>Telephone call</option>
              <option>SMS Text-message</option>
              {!alternate && <option>Opt-out</option>}
            </Form.Control>
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors[`${prefix}preferred_contact_method`]}
            </Form.Control.Feedback>
          </Form.Group>
          <Form.Group as={Col} lg="12" id="preferred_contact_time_wrapper">
            <Form.Label htmlFor={`${prefix}preferred_contact_time`} className="input-label">
              PREFERRED CONTACT TIME{schema?.fields[`${prefix}preferred_contact_time`]?._exclusive?.required && ' *'}
              {!alternate && <InfoTooltip tooltipTextKey="preferredContactTime" location="right"></InfoTooltip>}
            </Form.Label>
            {alternate ? (
              <Form.Control
                id="alternate_preferred_contact_time"
                isInvalid={this.state.errors['alternate_preferred_contact_time']}
                as="select"
                size="lg"
                className="form-square"
                value={this.state.current.patient.alternate_preferred_contact_time || ''}
                onChange={this.handleChange}>
                <option></option>
                <option>Morning</option>
                <option>Afternoon</option>
                <option>Evening</option>
              </Form.Control>
            ) : (
              <Select
                inputId="preferred_contact_time"
                value={{
                  label:
                    customPreferredContactTimeOptions[this.state.current.patient.preferred_contact_time] ||
                    this.state.current.patient.preferred_contact_time ||
                    '',
                  value: this.state.current.patient.preferred_contact_time || '',
                }}
                placeholder=""
                options={basicPreferredContactTimeOptions.concat(
                  [...new Set([this.state.current.patient.preferred_contact_time, this.props.patient.preferred_contact_time])]
                    .filter(value => Object.keys(customPreferredContactTimeOptions).includes(value))
                    .map(value => {
                      return { label: customPreferredContactTimeOptions[`${value}`], value };
                    })
                )}
                onChange={e =>
                  this.handleChange({
                    target: { id: 'preferred_contact_time', value: e.value },
                    currentTarget: { id: 'preferred_contact_time' },
                  })
                }
                styles={preferredContactTimeSelectStyling}
                theme={theme => bootstrapSelectTheme(theme, 'lg')}
              />
            )}
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors[`${prefix}preferred_contact_time`]}
            </Form.Control.Feedback>
            {!alternate && this.state.current.patient.preferred_contact_time && (
              <React.Fragment>
                {!this.state.current.patient.preferred_contact_method &&
                  this.renderWarningBanner(
                    'The monitoree will not be sent reminders while they do not have a Preferred Reporting Method selected.',
                    false,
                    'warning'
                  )}
                {['Unknown', 'Opt-out'].includes(this.state.current.patient.preferred_contact_method) &&
                  this.renderWarningBanner(
                    'The monitoree will not be sent reminders while they have Opt-out or Unknown selected for their Preferred Reporting Method.',
                    false,
                    'warning'
                  )}
              </React.Fragment>
            )}
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
          </Form.Group>
        </Form.Row>
        <Form.Row>
          <Form.Group as={Col} lg="12" controlId={`${prefix}primary_telephone`}>
            <Form.Label className="input-label">
              PRIMARY TELEPHONE NUMBER{schema?.fields[`${prefix}primary_telephone`]?._exclusive?.required && ' *'}
            </Form.Label>
            {!alternate && this.state.current.blocked_sms && (
              <span className="float-right font-weight-bold">
                SMS Blocked
                <InfoTooltip tooltipTextKey="blockedSMS" location="right" />
              </span>
            )}
            <PhoneInput
              id={`${prefix}primary_telephone`}
              value={this.state.current.patient[`${prefix}primary_telephone`]}
              onChange={this.handleChange}
              isInvalid={!!this.state.errors[`${prefix}primary_telephone`]}
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors[`${prefix}primary_telephone`]}
            </Form.Control.Feedback>
            {!alternate &&
              this.state.current.patient?.preferred_contact_method?.includes('SMS') &&
              this.state.current.blocked_sms &&
              this.renderWarningBanner('SMS-based reporting selected and this phone number has blocked SMS communications with Sara Alert', true)}
          </Form.Group>
          <Form.Group as={Col} lg="12" controlId={`${prefix}secondary_telephone`}>
            <Form.Label className="input-label">
              SECONDARY TELEPHONE NUMBER{schema?.fields[`${prefix}secondary_telephone`]?._exclusive?.required && ' *'}
            </Form.Label>
            <PhoneInput
              id={`${prefix}secondary_telephone`}
              value={this.state.current.patient[`${prefix}secondary_telephone`]}
              onChange={this.handleChange}
              isInvalid={!!this.state.errors[`${prefix}secondary_telephone`]}
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors[`${prefix}secondary_telephone`]}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
        <Form.Row>
          <Col lg="12">
            <Form.Group controlId={`${prefix}primary_telephone_type`}>
              <Form.Label className="input-label">
                PRIMARY PHONE TYPE{schema?.fields[`${prefix}primary_telephone_type`]?._exclusive?.required && ' *'}
              </Form.Label>
              <Form.Control
                isInvalid={this.state.errors[`${prefix}primary_telephone_type`]}
                as="select"
                size="lg"
                className="form-square"
                value={this.state.current.patient[`${prefix}primary_telephone_type`] || ''}
                onChange={this.handleChange}>
                <option></option>
                <option>Smartphone</option>
                <option>Plain Cell</option>
                <option>Landline</option>
              </Form.Control>
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors[`${prefix}primary_telephone_type`]}
              </Form.Control.Feedback>
              {this.state.current.patient[`${prefix}preferred_contact_method`] === 'SMS Texted Weblink' &&
                this.state.current.patient[`${prefix}primary_telephone_type`] == 'Plain Cell' &&
                this.renderWarningBanner(
                  'Plain cell phones cannot receive web-links. Please make sure the monitoree has a compatible device to receive this type of message.'
                )}
              {this.state.current.patient[`${prefix}preferred_contact_method`] === 'SMS Texted Weblink' &&
                this.state.current.patient[`${prefix}primary_telephone_type`] == 'Landline' &&
                this.renderWarningBanner(
                  'Landline phones cannot receive web-links. Please make sure the monitoree has a compatible device to receive this type of message.'
                )}
              {this.state.current.patient[`${prefix}preferred_contact_method`] === 'SMS Text-message' &&
                this.state.current.patient[`${prefix}primary_telephone_type`] === 'Landline' &&
                this.renderWarningBanner(
                  'Landline phones cannot receive text messages. Please make sure the monitoree has a compatible device to receive this type of message.'
                )}
            </Form.Group>
            <div className="mb-2">
              <span className="font-weight-bold">Smartphone: </span>
              <span className="font-weight-light">Phone capable of accessing web-based reporting tool</span>
              <br />
              <span className="font-weight-bold">Plain Cell: </span>
              <span className="font-weight-light">Phone capable of SMS messaging</span>
              <br />
              <span className="font-weight-bold">Landline: </span>
              <span className="font-weight-light">Has telephone but cannot use SMS or web-based reporting tool</span>
            </div>
          </Col>
          <Col lg="12">
            <Form.Group controlId={`${prefix}secondary_telephone_type`}>
              <Form.Label className="input-label">
                SECONDARY PHONE TYPE{schema?.fields[`${prefix}secondary_telephone_type`]?._exclusive?.required && ' *'}
              </Form.Label>
              <Form.Control
                isInvalid={this.state.errors[`${prefix}secondary_telephone_type`]}
                as="select"
                size="lg"
                className="form-square"
                value={this.state.current.patient[`${prefix}secondary_telephone_type`] || ''}
                onChange={this.handleChange}>
                <option></option>
                <option>Smartphone</option>
                <option>Plain Cell</option>
                <option>Landline</option>
              </Form.Control>
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors[`${prefix}secondary_telephone_type`]}
              </Form.Control.Feedback>
            </Form.Group>
            <Form.Group controlId={`${prefix}international_telephone`}>
              <Form.Label className="input-label">
                INTERNATIONAL TELEPHONE NUMBER{schema?.fields[`${prefix}international_telephone`]?._exclusive?.required && ' *'}
              </Form.Label>
              <Form.Control
                value={this.state.current.patient[`${prefix}international_telephone`] || ''}
                onChange={this.handleChange}
                size="lg"
                className="form-square"
                isInvalid={this.state.errors[`${prefix}international_telephone`]}
              />
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors[`${prefix}international_telephone`]}
              </Form.Control.Feedback>
              {this.state.current.patient[`${prefix}international_telephone`] &&
                this.renderWarningBanner('International telephone number is not used by the system for automated symptom reporting.', false, 'warning')}
            </Form.Group>
          </Col>
        </Form.Row>
        <Form.Row className="mt-2">
          <Form.Group as={Col} lg="12" controlId={`${prefix}email`}>
            <Form.Label className="input-label">E-MAIL ADDRESS{schema?.fields[`${prefix}email`]?._exclusive?.required && ' *'}</Form.Label>
            <Form.Control
              isInvalid={this.state.errors[`${prefix}email`]}
              size="lg"
              className="form-square"
              value={this.state.current.patient[`${prefix}email`] || ''}
              onChange={this.handleChange}
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors[`${prefix}email`]}
            </Form.Control.Feedback>
          </Form.Group>
          <Form.Group as={Col} lg="12" controlId={`confirm_${prefix}email`}>
            <Form.Label className="input-label">CONFIRM E-MAIL ADDRESS{schema?.fields[`confirm_${prefix}email`]?._exclusive?.required && ' *'}</Form.Label>
            <Form.Control
              isInvalid={this.state.errors[`confirm_${prefix}email`]}
              size="lg"
              className="form-square"
              value={this.state.current.patient[`confirm_${prefix}email`] || ''}
              onChange={this.handleChange}
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors[`confirm_${prefix}email`]}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
      </Form>
    );
  }

  render() {
    return (
      <React.Fragment>
        <h1 className="sr-only">Monitoree Contact Information</h1>
        <Card className="mx-2 card-square">
          <Card.Header className="h5">Monitoree Contact Information</Card.Header>
          <Card.Body>
            <Nav
              variant="tabs"
              activeKey={this.state.selectedTab}
              className="g-border-bottom mb-3"
              onSelect={tab => {
                this.setState({ selectedTab: tab });
              }}>
              <Nav.Item>
                <Nav.Link eventKey="primary">
                  Primary
                  {this.state.showPrimaryValidationIcon && this.renderInvalidIcon()}
                </Nav.Link>
              </Nav.Item>
              <Nav.Item>
                <Nav.Link eventKey="alternate">
                  Alternate
                  {this.state.showAlternateValidationIcon && this.renderInvalidIcon()}
                </Nav.Link>
              </Nav.Item>
            </Nav>
            <Tab.Content>
              {this.state.selectedTab === 'primary' && (
                <React.Fragment>
                  <Alert variant="primary">
                    <b>
                      Sara Alert will use the primary contact for communication with the monitoree. Automated messages will be sent to the primary contact
                      phone/e-mail entered here.
                    </b>
                  </Alert>
                  {this.renderContactFields()}
                </React.Fragment>
              )}
              {this.state.selectedTab === 'alternate' && (
                <React.Fragment>
                  <Alert variant="danger">
                    <b>
                      Alternate Contact Information is for reference only. Sara Alert will NOT use the alternate contact phone or e-mail for automated
                      communications.
                    </b>
                  </Alert>
                  {this.renderContactFields(true)}
                </React.Fragment>
              )}
            </Tab.Content>
            {this.props.previous && this.props.showPreviousButton && (
              <Button id="enrollment-previous-button" variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>
                Previous
              </Button>
            )}
            {this.props.next && (
              <Button
                id="enrollment-next-button"
                variant="outline-primary"
                size="lg"
                className="float-right btn-square px-5"
                onClick={() => this.validate(this.props.next)}>
                Next
              </Button>
            )}
          </Card.Body>
        </Card>
        {this.renderPreferredContactTimeModal()}
      </React.Fragment>
    );
  }
}

yup.addMethod(yup.string, 'phone', phoneSchemaValidator);

var schema = yup.object().shape({
  contact_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  contact_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  primary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  secondary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  international_telephone: yup.string().max(50, 'Max length exceeded, please limit to 50 characters.').nullable(),
  email: yup.string().email('Please enter a valid Email.').max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  confirm_email: yup
    .string()
    .oneOf([yup.ref('email'), null], 'Confirm Email must match.')
    .nullable(),
  preferred_contact_method: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  preferred_contact_time: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  alternate_contact_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  alternate_contact_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  alternate_primary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  alternate_secondary_telephone: yup.string().phone().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  alternate_primary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  alternate_secondary_telephone_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  alternate_international_telephone: yup.string().max(50, 'Max length exceeded, please limit to 50 characters.').nullable(),
  alternate_email: yup.string().email('Please enter a valid Email.').max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  confirm_alternate_email: yup
    .string()
    .oneOf([yup.ref('alternate_email'), null], 'Confirm Email must match.')
    .nullable(),
  alternate_preferred_contact_method: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  alternate_preferred_contact_time: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
});

Contact.propTypes = {
  currentState: PropTypes.object,
  setEnrollmentState: PropTypes.func,
  patient: PropTypes.object,
  previous: PropTypes.func,
  next: PropTypes.func,
  showPreviousButton: PropTypes.bool,
  edit_mode: PropTypes.bool,
};

export default Contact;
