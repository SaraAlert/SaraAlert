import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card, Col, Form } from 'react-bootstrap';
import * as yup from 'yup';
import axios from 'axios';
import moment from 'moment';
import _ from 'lodash';

import confirmDialog from '../../util/ConfirmDialog';
import DateInput from '../../util/DateInput';
import InfoTooltip from '../../util/InfoTooltip';
import { countryOptions } from '../../../data/countryOptions';
import PublicHealthManagement from './PublicHealthManagement';

class ExposureInformation extends React.Component {
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
    this.updateStaticValidations();
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

  handleLDEChange = date => {
    let current = this.state.current;
    let modified = this.state.modified;

    // turn off CE if LDE is populated
    if (date) {
      current.patient.continuous_exposure = false;
      modified = { patient: { ...modified.patient, continuous_exposure: false } };
    }
    this.updateExposureValidations({ ...current.patient, last_date_of_exposure: date });
    this.setState(
      {
        current: { ...current, patient: { ...current.patient, last_date_of_exposure: date } },
        modified: { ...modified, patient: { ...modified.patient, last_date_of_exposure: date } },
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

  updateStaticValidations = () => {
    this.updateExposureValidations(this.props.patient);
  };

  updateExposureValidations = patient => {
    if (!patient.last_date_of_exposure && !patient.continuous_exposure && !this.props.currentState.isolation) {
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

  renderExposureFields = () => {
    return (
      <React.Fragment>
        <Form.Row className="mb-2">
          <Form.Group
            as={Col}
            lg={{ span: 7, order: 1 }}
            md={{ span: 12, order: 1 }}
            xs={{ span: 24, order: 1 }}
            controlId="last_date_of_exposure"
            className="mb-2">
            <Form.Label className="input-label">
              LAST DATE OF EXPOSURE{schema?.fields?.last_date_of_exposure?._exclusive?.required && ' *'}
              <InfoTooltip tooltipTextKey="lastDateOfExposure" location="right"></InfoTooltip>
            </Form.Label>
            <DateInput
              id="last_date_of_exposure"
              aria-label="Last Date of Exposure"
              date={this.state.current.patient.last_date_of_exposure}
              minDate={'2020-01-01'}
              maxDate={moment().add(30, 'days').format('YYYY-MM-DD')}
              onChange={date => this.handleLDEChange(date)}
              placement="bottom"
              isInvalid={!!this.state.errors['last_date_of_exposure']}
              customClass="form-control-lg"
              ariaLabel="Last Date of Exposure Input"
              isClearable
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['last_date_of_exposure']}
            </Form.Control.Feedback>
          </Form.Group>
          <Form.Group
            as={Col}
            lg={{ span: 10, order: 2 }}
            md={{ span: 12, order: 2 }}
            xs={{ span: 24, order: 3 }}
            controlId="potential_exposure_location"
            className="mb-2">
            <Form.Label className="input-label">EXPOSURE LOCATION{schema?.fields?.potential_exposure_location?._exclusive?.required && ' *'}</Form.Label>
            <Form.Control
              isInvalid={this.state.errors['potential_exposure_location']}
              size="lg"
              className="form-square"
              value={this.state.current.patient.potential_exposure_location || ''}
              onChange={this.handleChange}
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['potential_exposure_location']}
            </Form.Control.Feedback>
          </Form.Group>
          <Form.Group
            as={Col}
            lg={{ span: 7, order: 3 }}
            md={{ span: 12, order: 4 }}
            xs={{ span: 24, order: 4 }}
            controlId="potential_exposure_country"
            className="mb-2">
            <Form.Label className="input-label">EXPOSURE COUNTRY{schema?.fields?.potential_exposure_country?._exclusive?.required && ' *'}</Form.Label>
            <Form.Control
              isInvalid={this.state.errors['potential_exposure_country']}
              as="select"
              size="lg"
              className="form-square"
              aria-label="Potential Exposure Country Select"
              value={this.state.current.patient.potential_exposure_country || ''}
              onChange={this.handleChange}>
              <option></option>
              {countryOptions.map((country, index) => (
                <option key={`country-${index}`}>{country}</option>
              ))}
            </Form.Control>
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['potential_exposure_country']}
            </Form.Control.Feedback>
          </Form.Group>
          <Form.Group as={Col} lg={{ span: 8, order: 4 }} md={{ span: 12, order: 3 }} xs={{ span: 24, order: 2 }} className="pl-1">
            <Form.Check
              size="lg"
              label={`CONTINUOUS EXPOSURE${schema?.fields?.continuous_exposure?._whitelist?.list?.has(true) ? ' *' : ''}`}
              id="continuous_exposure"
              className="ml-1 d-inline"
              checked={!!this.state.current.patient.continuous_exposure}
              onChange={this.handleChange}
            />
            <InfoTooltip tooltipTextKey="continuousExposure" location="right"></InfoTooltip>
          </Form.Group>
        </Form.Row>
        <Form.Label className="input-label pb-1">EXPOSURE RISK FACTORS (USE COMMAS TO SEPARATE MULTIPLE SPECIFIED VALUES)</Form.Label>
        <Form.Row>
          <Form.Group as={Col} md="auto" className="mb-0 my-auto pb-2">
            <Form.Check
              type="switch"
              id="contact_of_known_case"
              label="CLOSE CONTACT WITH A KNOWN CASE"
              checked={this.state.current.patient.contact_of_known_case || false}
              onChange={this.handleChange}
            />
          </Form.Group>
          <Form.Group as={Col} md="auto" className="mb-0 my-auto ml-4">
            <Form.Control
              size="sm"
              className="form-square"
              id="contact_of_known_case_id"
              placeholder="enter case ID"
              value={this.state.current.patient.contact_of_known_case_id || ''}
              onChange={this.handleChange}
              aria-label="Enter Case Id"
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['contact_of_known_case_id']}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
        <Form.Row>
          <Form.Group as={Col} md="auto" className="mb-0 my-auto pb-2">
            <Form.Check
              className="pt-2 my-auto"
              type="switch"
              id="travel_to_affected_country_or_area"
              label="TRAVEL FROM AFFECTED COUNTRY OR AREA"
              checked={this.state.current.patient.travel_to_affected_country_or_area || false}
              onChange={this.handleChange}
            />
          </Form.Group>
        </Form.Row>
        <Form.Row>
          <Form.Group as={Col} md="auto" className="mb-0 my-auto pb-2">
            <Form.Check
              className="pt-2 my-auto"
              type="switch"
              id="was_in_health_care_facility_with_known_cases"
              label="WAS IN HEALTHCARE FACILITY WITH KNOWN CASES"
              checked={this.state.current.patient.was_in_health_care_facility_with_known_cases || false}
              onChange={this.handleChange}
            />
          </Form.Group>
          <Form.Group as={Col} md="auto" className="mb-0 my-auto ml-4">
            <Form.Control
              size="sm"
              className="form-square"
              id="was_in_health_care_facility_with_known_cases_facility_name"
              placeholder="enter facility name"
              value={this.state.current.patient.was_in_health_care_facility_with_known_cases_facility_name || ''}
              onChange={this.handleChange}
              aria-label="Enter Facility Name"
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['was_in_health_care_facility_with_known_cases_facility_name']}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
        <Form.Row>
          <Form.Group as={Col} md="auto" className="mb-0 my-auto pb-2">
            <Form.Check
              className="pt-2 my-auto"
              type="switch"
              id="laboratory_personnel"
              label="LABORATORY PERSONNEL"
              checked={this.state.current.patient.laboratory_personnel || false}
              onChange={this.handleChange}
            />
          </Form.Group>
          <Form.Group as={Col} md="auto" className="mb-0 my-auto ml-4">
            <Form.Control
              size="sm"
              className="form-square"
              id="laboratory_personnel_facility_name"
              placeholder="enter facility name"
              value={this.state.current.patient.laboratory_personnel_facility_name || ''}
              onChange={this.handleChange}
              aria-label="Enter Laboratory Facility Name"
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['laboratory_personnel_facility_name']}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
        <Form.Row>
          <Form.Group as={Col} md="auto" className="mb-0 my-auto pb-2">
            <Form.Check
              className="pt-2 my-auto"
              type="switch"
              id="healthcare_personnel"
              label="HEALTHCARE PERSONNEL"
              checked={this.state.current.patient.healthcare_personnel || false}
              onChange={this.handleChange}
            />
          </Form.Group>
          <Form.Group as={Col} md="auto" className="mb-0 my-auto ml-4">
            <Form.Control
              size="sm"
              className="form-square"
              id="healthcare_personnel_facility_name"
              placeholder="enter facility name"
              value={this.state.current.patient.healthcare_personnel_facility_name || ''}
              onChange={this.handleChange}
              aria-label="Enter Healthcare Facility Name"
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['healthcare_personnel_facility_name']}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
        <Form.Row>
          <Form.Group as={Col} md="auto" className="mb-0 my-auto pb-2">
            <Form.Check
              className="pt-2 my-auto"
              type="switch"
              id="crew_on_passenger_or_cargo_flight"
              label="CREW ON PASSENGER OR CARGO FLIGHT"
              checked={this.state.current.patient.crew_on_passenger_or_cargo_flight || false}
              onChange={this.handleChange}
            />
          </Form.Group>
        </Form.Row>
        <Form.Row>
          <Form.Group as={Col} md="auto" className="mb-0 my-auto pb-2">
            <Form.Check
              className="pt-2 my-auto"
              type="switch"
              id="member_of_a_common_exposure_cohort"
              label="MEMBER OF A COMMON EXPOSURE COHORT"
              checked={this.state.current.patient.member_of_a_common_exposure_cohort || false}
              onChange={this.handleChange}
            />
          </Form.Group>
          <Form.Group as={Col} md="auto" className="mb-0 my-auto ml-4">
            <Form.Control
              size="sm"
              className="form-square"
              id="member_of_a_common_exposure_cohort_type"
              placeholder="enter description"
              value={this.state.current.patient.member_of_a_common_exposure_cohort_type || ''}
              onChange={this.handleChange}
              aria-label="Enter Cohort Description"
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['member_of_a_common_exposure_cohort_type']}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
        {!this.props.patient.isolation && (
          <Form.Row>
            <Form.Group as={Col} md="24" controlId="exposure_notes" className="pt-3 mb-2">
              <Form.Label className="input-label">NOTES{schema?.fields?.exposure_notes?._exclusive?.required && ' *'}</Form.Label>
              <Form.Control
                isInvalid={this.state.errors['exposure_notes']}
                as="textarea"
                rows="4"
                size="lg"
                className="form-square"
                placeholder="enter additional information about monitoree’s potential exposure"
                maxLength="2000"
                value={this.state.current.patient.exposure_notes || ''}
                onChange={this.handleChange}
              />
              <div className="character-limit-text">{2000 - (this.state.current.patient.exposure_notes || '').length} characters remaining</div>
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['exposure_notes']}
              </Form.Control.Feedback>
            </Form.Group>
          </Form.Row>
        )}
      </React.Fragment>
    );
  };

  render() {
    return (
      <React.Fragment>
        <h1 className="sr-only">Monitoree Potential Exposure Information</h1>
        <Card className="mx-2 card-square">
          <Card.Header className="h5">Monitoree Potential Exposure Information</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row className="pb-3 h-100">
                <Form.Group as={Col} className="my-auto">
                  {this.renderExposureFields()}
                  {!this.props.patient.isolation && (
                    <PublicHealthManagement
                      currentState={this.state.current}
                      setEnrollmentState={this.props.setEnrollmentState}
                      previous={this.previous}
                      next={this.next}
                      patient={this.props.patient}
                      has_dependents={this.props.has_dependents}
                      jurisdiction_paths={this.props.jurisdiction_paths}
                      assigned_users={this.props.assigned_users}
                      first_positive_lab={this.props.first_positive_lab}
                      authenticity_token={this.props.authenticity_token}
                    />
                  )}
                </Form.Group>
              </Form.Row>
            </Form>
            {this.props.previous && !this.props.hidePreviousButton && (
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

ExposureInformation.propTypes = {
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
  hidePreviousButton: PropTypes.bool,
  authenticity_token: PropTypes.string,
};

export default ExposureInformation;
