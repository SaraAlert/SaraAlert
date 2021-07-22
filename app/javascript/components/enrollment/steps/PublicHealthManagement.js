import React from 'react';
import { PropTypes } from 'prop-types';
import { Col, Form } from 'react-bootstrap';
import * as yup from 'yup';
import axios from 'axios';
import moment from 'moment';
import _ from 'lodash';

import confirmDialog from '../../util/ConfirmDialog';
import InfoTooltip from '../../util/InfoTooltip';

class PublicHealthManagement extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      current: this.props.currentState,
      errors: {},
      modified: {},
      sorted_jurisdiction_paths: _.values(this.props.jurisdiction_paths).sort((a, b) => a.localeCompare(b)),
      jurisdiction_path: this.props.jurisdiction_paths[this.props.currentState.patient.jurisdiction_id],
      originalJurisdictionId: this.props.currentState.patient.jurisdiction_id,
      originalAssignedUser: this.props.currentState.patient.assigned_user,
      assigned_users: this.props.assigned_users,
      selected_jurisdiction: this.props.selected_jurisdiction,
    };
  }

  componentDidMount() {
    this.updateStaticValidations(this.props.currentState.isolation, this.props.first_positive_lab);
  }

  componentDidUpdate(prevProps) {
    if (prevProps.currentState.isolation !== this.props.currentState.isolation) {
      this.updateStaticValidations(this.props.currentState.isolation, this.props.first_positive_lab);
    }
  }

  handleChange = event => {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let modified = this.state.modified;
    if (event?.target?.id && event.target.id === 'jurisdiction_id') {
      this.setState({ jurisdiction_path: event.target.value });
      let jurisdiction_id = parseInt(Object.keys(this.props.jurisdiction_paths).find(id => this.props.jurisdiction_paths[parseInt(id)] === event.target.value));
      if (jurisdiction_id) {
        value = jurisdiction_id;
        axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
        axios
          .post(window.BASE_PATH + '/jurisdictions/assigned_users', {
            query: {
              jurisdiction: jurisdiction_id,
              scope: 'exact',
            },
          })
          .catch(() => {})
          .then(response => {
            if (response?.data?.assigned_users) {
              this.setState({ assigned_users: response.data.assigned_users });
            }
          });
      } else {
        value = -1;
      }
    } else if (event?.target?.id && event.target.id === 'assigned_user') {
      if (isNaN(event.target.value) || parseInt(event.target.value) > 999999) return;

      // trim() call included since there is a bug with yup validation for numbers that allows whitespace entry
      value = event.target.value.trim() === '' ? null : parseInt(event.target.value);
    } else if (event?.target?.id && event.target.id === 'continuous_exposure') {
      // clear out LDE if CE is turned on and populate it with previous LDE if CE is turned off
      const lde = value ? null : this.props.patient.last_date_of_exposure;
      current.patient.last_date_of_exposure = lde;
      if (modified.patient) {
        modified.patient.last_date_of_exposure = lde;
      } else {
        modified = { patient: { last_date_of_exposure: lde } };
      }
      this.updateExposureValidations({ ...current.patient, [event.target.id]: value });
    }
    this.setState(
      {
        current: { ...current, patient: { ...current.patient, [event.target.id]: value } },
        modified: { ...modified, patient: { ...modified.patient, [event.target.id]: value } },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };

  handleDateChange = (field, date) => {
    let current = this.state.current;
    let modified = this.state.modified;
    if (field === 'last_date_of_exposure') {
      // turn off CE if LDE is populated
      if (date) {
        current.patient.continuous_exposure = false;
        modified = { patient: { ...modified.patient, continuous_exposure: false } };
      }
      this.updateExposureValidations({ ...current.patient, [field]: date });
    } else if (field === 'symptom_onset') {
      this.updateIsolationValidations({ ...current.patient, [field]: date }, this.state.current.first_positive_lab);
    }
    this.setState(
      {
        current: { ...current, patient: { ...current.patient, [field]: date } },
        modified: { ...modified, patient: { ...modified.patient, [field]: date } },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };

  handlePropagatedFieldChange = event => {
    const current = this.state.current;
    const modified = this.state.modified;
    this.setState(
      {
        current: { ...current, propagatedFields: { ...current.propagatedFields, [event.target.name]: event.target.checked } },
        modified: { ...modified, propagatedFields: { ...current.propagatedFields, [event.target.name]: event.target.checked } },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };

  handleLabChange = first_positive_lab => {
    const current = this.state.current;
    const modified = this.state.modified;
    this.setState(
      {
        current: { ...current, patient: { ...current.patient, first_positive_lab_at: first_positive_lab?.specimen_collection }, first_positive_lab },
        modified: { ...modified, patient: { ...modified.patient, first_positive_lab_at: first_positive_lab?.specimen_collection }, first_positive_lab },
        showLabModal: false,
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
        this.updateIsolationValidations(current.patient, first_positive_lab);
      }
    );
  };

  updateStaticValidations = (isolation, first_positive_lab) => {
    // Update the Schema Validator based on workflow.
    if (isolation) {
      this.updateIsolationValidations(this.props.currentState.patient, first_positive_lab);
    } else {
      this.updateExposureValidations(this.props.patient);
    }
  };

  updateExposureValidations = patient => {
    if (!patient.last_date_of_exposure && !patient.continuous_exposure) {
      schema = yup.object().shape({
        ...staticValidations,
        last_date_of_exposure: yup
          .date('Date must correspond to the "mm/dd/yyyy" format.')
          .max(moment().add(30, 'days').toDate(), 'Date can not be more than 30 days in the future.')
          .required('Please enter a Last Date of Exposure OR turn on Continuous Exposure')
          .nullable(),
        continuous_exposure: yup.bool().nullable(),
      });
    } else if (!patient.last_date_of_exposure && patient.continuous_exposure) {
      schema = yup.object().shape({
        ...staticValidations,
        last_date_of_exposure: yup.date('Date must correspond to the "mm/dd/yyyy" format.').oneOf([null, undefined]).nullable(),
        continuous_exposure: yup.bool().oneOf([true]).nullable(),
      });
    } else if (patient.last_date_of_exposure && !patient.continuous_exposure) {
      schema = yup.object().shape({
        ...staticValidations,
        last_date_of_exposure: yup
          .date('Date must correspond to the "mm/dd/yyyy" format.')
          .max(moment().add(30, 'days').toDate(), 'Date can not be more than 30 days in the future.')
          .required('Please enter a Last Date of Exposure')
          .nullable(),
        continuous_exposure: yup.bool().oneOf([null, undefined, false]).nullable(),
      });
    } else {
      schema = yup.object().shape({
        ...staticValidations,
        last_date_of_exposure: yup
          .date('Date must correspond to the "mm/dd/yyyy" format.')
          .oneOf([null, undefined], 'Please enter a Last Date of Exposure OR turn on Continuous Exposure, but not both.')
          .nullable(),
        continuous_exposure: yup.bool().nullable(),
      });
    }
    this.setState(state => {
      const errors = state.errors;
      delete errors.last_date_of_exposure;
      delete errors.continuous_exposure;
      return { errors };
    });
  };

  updateIsolationValidations = (patient, first_positive_lab) => {
    if (!patient.symptom_onset && !first_positive_lab?.specimen_collection) {
      schema = yup.object().shape({
        ...staticValidations,
        symptom_onset: yup
          .date('Date must correspond to the "mm/dd/yyyy" format.')
          .max(moment().add(30, 'days').toDate(), 'Date can not be more than 30 days in the future.')
          .required('Please enter a Symptom Onset Date AND/OR a positive lab result.')
          .nullable(),
      });
    } else if (patient.symptom_onset) {
      schema = yup.object().shape({
        ...staticValidations,
        symptom_onset: yup
          .date('Date must correspond to the "mm/dd/yyyy" format.')
          .max(moment().add(30, 'days').toDate(), 'Date can not be more than 30 days in the future.')
          .required('Please enter a Symptom Onset Date AND/OR a positive lab result.')
          .nullable(),
      });
    } else {
      schema = yup.object().shape({
        ...staticValidations,
        symptom_onset: yup
          .date('Date must correspond to the "mm/dd/yyyy" format.')
          .max(moment().add(30, 'days').toDate(), 'Date can not be more than 30 days in the future.')
          .nullable(),
      });
    }
    this.setState(state => {
      const errors = state.errors;
      delete errors.symptom_onset;
      return { errors };
    });
  };

  validate = callback => {
    let self = this;
    schema
      .validate(this.state.current.patient, { abortEarly: false })
      .then(() => {
        // No validation issues? Invoke callback (move to next step)
        self.setState({ errors: {} }, async () => {
          if (self.state.current.patient.jurisdiction_id !== self.state.originalJurisdictionId) {
            // If we set it back to the last saved value no need to confirm.
            if (self.state.current.patient.jurisdiction_id === self.state.selected_jurisdiction) {
              callback();
              return;
            }
            const originalJurisdictionPath = self.props.jurisdiction_paths[self.state.originalJurisdictionId];
            const message = `You are about to change the assigned jurisdiction from ${originalJurisdictionPath} to ${self.state.jurisdiction_path}. Are you sure you want to do this?`;
            const options = { title: 'Confirm Jurisdiction Change' };

            if (self.state.current.patient.assigned_user && self.state.current.patient.assigned_user === self.state.originalAssignedUser) {
              options.additionalNote = 'Please also consider removing or updating the assigned user if it is no longer applicable.';
            }

            if (await confirmDialog(message, options)) {
              self.setState({ selected_jurisdiction: self.state.current.patient.jurisdiction_id });
              callback();
            }
          } else {
            self.setState({ selected_jurisdiction: self.state.current.patient.jurisdiction_id });
            callback();
          }
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

  render() {
    return (
      <React.Fragment>
        <Form.Row className="pt-2 g-border-bottom-2" />
        <Form.Row className="pt-2">
          <Form.Group as={Col} className="mb-2">
            <Form.Label className="input-label">PUBLIC HEALTH RISK ASSESSMENT AND MANAGEMENT</Form.Label>
          </Form.Group>
        </Form.Row>
        <Form.Row>
          <Form.Group as={Col} md="18" className="mb-2 pt-2" controlId="jurisdiction_id">
            <Form.Label className="input-label">ASSIGNED JURISDICTION{schema?.fields?.jurisdiction_id?._exclusive?.required && ' *'}</Form.Label>
            <Form.Control
              isInvalid={this.state.errors['jurisdiction_id']}
              as="input"
              list="jurisdiction_paths"
              autoComplete="off"
              size="lg"
              className="form-square"
              onChange={this.handleChange}
              value={this.state.jurisdiction_path}
            />
            <datalist id="jurisdiction_paths">
              {this.state.sorted_jurisdiction_paths.map((jurisdiction, index) => {
                return (
                  <option value={jurisdiction} key={index}>
                    {jurisdiction}
                  </option>
                );
              })}
            </datalist>
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['jurisdiction_id']}
            </Form.Control.Feedback>
            {this.props.has_dependents &&
              this.state.current.patient.jurisdiction_id !== this.state.originalJurisdictionId &&
              Object.keys(this.props.jurisdiction_paths).includes(this.state.current.patient.jurisdiction_id.toString()) && (
                <Form.Group className="mt-2">
                  <Form.Check
                    type="switch"
                    id="update_group_member_jurisdiction_id"
                    name="jurisdiction_id"
                    label="Apply this change to the entire household that this monitoree is responsible for"
                    onChange={this.handlePropagatedFieldChange}
                    checked={this.state.current.propagatedFields.jurisdiction_id}
                  />
                </Form.Group>
              )}
          </Form.Group>
          <Form.Group as={Col} md="6" className="mb-2 pt-2" controlId="assigned_user">
            <Form.Label className="input-label">
              ASSIGNED USER{schema?.fields?.assigned_user?._exclusive?.required && ' *'}
              <InfoTooltip tooltipTextKey="assignedUser" location="top"></InfoTooltip>
            </Form.Label>
            <Form.Control
              isInvalid={this.state.errors['assigned_user']}
              as="input"
              list="assigned_users"
              autoComplete="off"
              size="lg"
              className="form-square"
              onChange={this.handleChange}
              value={this.state.current.patient.assigned_user || ''}
            />
            <datalist id="assigned_users">
              {this.state.assigned_users?.map(num => {
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
            {this.props.has_dependents &&
              this.state.current.patient.assigned_user !== this.state.originalAssignedUser &&
              (this.state.current.patient.assigned_user === null ||
                (this.state.current.patient.assigned_user > 0 && this.state.current.patient.assigned_user <= 999999)) && (
                <Form.Group className="mt-2">
                  <Form.Check
                    type="switch"
                    id="update_group_member_assigned_user"
                    name="assigned_user"
                    label="Apply this change to the entire household that this monitoree is responsible for"
                    onChange={this.handlePropagatedFieldChange}
                    checked={this.state.current.propagatedFields.assigned_user}
                  />
                </Form.Group>
              )}
          </Form.Group>
          <Form.Group as={Col} md="8" controlId="exposure_risk_assessment" className="mb-2 pt-2">
            <Form.Label className="input-label">RISK ASSESSMENT{schema?.fields?.exposure_risk_assessment?._exclusive?.required && ' *'}</Form.Label>
            <Form.Control
              isInvalid={this.state.errors['exposure_risk_assessment']}
              as="select"
              size="lg"
              className="form-square"
              onChange={this.handleChange}
              value={this.state.current.patient.exposure_risk_assessment || ''}>
              <option></option>
              <option>High</option>
              <option>Medium</option>
              <option>Low</option>
              <option>No Identified Risk</option>
            </Form.Control>
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['exposure_risk_assessment']}
            </Form.Control.Feedback>
          </Form.Group>
          <Form.Group as={Col} md="16" controlId="monitoring_plan" className="mb-2 pt-2">
            <Form.Label className="input-label">MONITORING PLAN{schema?.fields?.monitoring_plan?._exclusive?.required && ' *'}</Form.Label>
            <Form.Control
              isInvalid={this.state.errors['monitoring_plan']}
              as="select"
              size="lg"
              className="form-square"
              onChange={this.handleChange}
              value={this.state.current.patient.monitoring_plan || ''}>
              <option>None</option>
              <option>Daily active monitoring</option>
              <option>Self-monitoring with public health supervision</option>
              <option>Self-monitoring with delegated supervision</option>
              <option>Self-observation</option>
            </Form.Control>
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['monitoring_plan']}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
      </React.Fragment>
    );
  }
}

const staticValidations = {
  potential_exposure_location: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  potential_exposure_country: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  contact_of_known_case: yup.boolean().nullable(),
  contact_of_known_case_id: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  healthcare_personnel_facility_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  laboratory_personnel_facility_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  was_in_health_care_facility_with_known_cases_facility_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  member_of_a_common_exposure_cohort_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  travel_to_affected_country_or_area: yup.boolean().nullable(),
  was_in_health_care_facility_with_known_cases: yup.boolean().nullable(),
  crew_on_passenger_or_cargo_flight: yup.boolean().nullable(),
  laboratory_personnel: yup.boolean().nullable(),
  healthcare_personnel: yup.boolean().nullable(),
  exposure_risk_assessment: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  monitoring_plan: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  jurisdiction_id: yup.number().positive('Please enter a valid Assigned Jurisdiction.').required(),
  assigned_user: yup.number().positive('Please enter a valid Assigned User').nullable(),
  exposure_notes: yup.string().max(2000, 'Max length exceeded, please limit to 2000 characters.').nullable(),
};

var schema = yup.object().shape(staticValidations);

PublicHealthManagement.propTypes = {
  currentState: PropTypes.object,
  setEnrollmentState: PropTypes.func,
  previous: PropTypes.func,
  next: PropTypes.func,
  patient: PropTypes.object,
  has_dependents: PropTypes.bool,
  jurisdiction_paths: PropTypes.object,
  assigned_users: PropTypes.array,
  selected_jurisdiction: PropTypes.object,
  first_positive_lab: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default PublicHealthManagement;
