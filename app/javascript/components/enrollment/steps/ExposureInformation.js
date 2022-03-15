import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card, Col, Form } from 'react-bootstrap';
import Switch from 'react-switch';
import ReactTooltip from 'react-tooltip';
import * as yup from 'yup';
import moment from 'moment';
import _ from 'lodash';
import axios from 'axios';

import PublicHealthManagement from './PublicHealthManagement';
import CommonExposureCohortModal from '../../patient/common_exposure_cohorts/CommonExposureCohortModal';
import CommonExposureCohortsTable from '../../patient/common_exposure_cohorts/CommonExposureCohortsTable';
import confirmDialog from '../../util/ConfirmDialog';
import DateInput from '../../util/DateInput';
import InfoTooltip from '../../util/InfoTooltip';
import { countryOptions } from '../../../data/countryOptions';

class ExposureInformation extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      current: this.props.currentState,
      errors: {},
      modified: {},
      sorted_jurisdiction_paths: _.values(this.props.jurisdiction_paths).sort((a, b) => a.localeCompare(b)),
      originalJurisdictionId: this.props.currentState.patient.jurisdiction_id,
      originalAssignedUser: this.props.currentState.patient.assigned_user,
      showCommonExposureCohortModal: false,
    };
  }

  componentDidMount() {
    this.updateStaticValidations();
    axios
      .post(window.BASE_PATH + '/jurisdictions/common_exposure_cohorts', {
        query: {
          jurisdiction: this.props.current_user.jurisdiction_id,
          scope: 'all',
        },
      })
      .catch(() => {})
      .then(response => {
        if (response?.data?.cohort_names || response?.data?.cohort_locations) {
          this.setState({ cohort_names: response.data.cohort_names, cohort_locations: response.data.cohort_locations });
        }
      });
  }

  componentDidUpdate(prevProps) {
    if (prevProps.currentState.isolation !== this.props.currentState.isolation) {
      this.updateStaticValidations(this.props.currentState.isolation);
    }
  }

  handleChange = event => {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let modified = this.state.modified;
    if (event?.target?.id && event.target.id === 'continuous_exposure') {
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
      modified = { ...modified, patient: { ...modified.patient, continuous_exposure: false } };
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

  handleRiskFactorToggle = (field, value) => {
    let current = this.state.current;
    let modified = this.state.modified;
    this.setState(
      {
        current: { ...current, patient: { ...current.patient, [field]: value } },
        modified: { ...modified, patient: { ...modified.patient, [field]: value } },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };

  handleRiskFactorChange = event => {
    let field = event.target.id;
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let toggleField = field.replace('_id', '').replace('_facility_name', '');
    let toggleValue = value?.length > 0 ? true : this.state.current.patient[String(toggleField)];
    let current = this.state.current;
    let modified = this.state.modified;
    this.setState(
      {
        current: { ...current, patient: { ...current.patient, [field]: value, [toggleField]: toggleValue } },
        modified: { ...modified, patient: { ...modified.patient, [field]: value, [toggleField]: toggleValue } },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };

  handlePublicHealthManagementChange = (value, field) => {
    let current = this.state.current;
    let modified = this.state.modified;
    this.setState(
      {
        current: { ...current, patient: { ...current.patient, [field]: value } },
        modified: { ...modified, patient: { ...modified.patient, [field]: value } },
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

  handleCohortChange = (common_exposure_cohort, common_exposure_cohort_index) => {
    const current = this.state.current;
    const modified = this.state.modified;
    let common_exposure_cohorts = this.state.current.common_exposure_cohorts;
    // Need to compare with undefined because index value of 0 evaluates to false
    if (common_exposure_cohort_index === undefined) {
      // Add new cohort to table
      common_exposure_cohorts = common_exposure_cohorts ? common_exposure_cohorts.concat([common_exposure_cohort]) : [common_exposure_cohort];
    } else {
      // Update existing cohort from table
      common_exposure_cohorts[`${common_exposure_cohort_index}`] = common_exposure_cohort;
    }
    const toggle = common_exposure_cohorts?.length > 0 ? true : this.state.current.patient.member_of_a_common_exposure_cohort;

    // TODO: prevent adding duplicate cohorts
    this.setState(
      {
        current: { ...current, common_exposure_cohorts, patient: { ...current.patient, member_of_a_common_exposure_cohort: toggle } },
        modified: { ...modified, common_exposure_cohorts, patient: { ...modified.patient, member_of_a_common_exposure_cohort: toggle } },
        showCommonExposureCohortModal: false,
        common_exposure_cohort: null,
        common_exposure_cohort_index: null,
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };

  handleCohortDelete = index => {
    const self = this;
    self.setState(
      state => {
        const common_exposure_cohorts = state.current.common_exposure_cohorts;
        common_exposure_cohorts.splice(index, 1);
        return {
          current: { ...state.current, common_exposure_cohorts },
          modified: { ...state.modified, common_exposure_cohorts },
        };
      },
      () => {
        self.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };

  toggleCommonExposureCohortModal = (showCommonExposureCohortModal, common_exposure_cohort, common_exposure_cohort_index) => {
    this.setState({ showCommonExposureCohortModal, common_exposure_cohort, common_exposure_cohort_index });
  };

  toggleCohortDeleteDialog = async index => {
    if (await confirmDialog('Are you sure you want to delete this common exposure cohort for this monitoree?', { title: 'Delete Common Exposure Cohort' })) {
      this.handleCohortDelete(index);
    }
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
          .max(moment().add(30, 'days').toDate(), 'Date cannot be more than 30 days in the future.')
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
          .max(moment().add(30, 'days').toDate(), 'Date cannot be more than 30 days in the future.')
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
            if (self.state.current.patient.jurisdiction_id === self.state.selected_jurisdiction_id) {
              callback();
              return;
            }

            const originalJurisdictionPath = self.props.jurisdiction_paths[self.state.originalJurisdictionId];
            const newJurisdictionPath = self.props.jurisdiction_paths[self.state.current.patient.jurisdiction_id];
            const message = `You are about to change the Assigned Jurisdiction from ${originalJurisdictionPath} to ${newJurisdictionPath}. Are you sure you want to do this?`;
            const options = { title: 'Confirm Jurisdiction Change' };

            if (self.state.current.patient.assigned_user && self.state.current.patient.assigned_user === self.state.originalAssignedUser) {
              options.additionalNote = 'Please also consider removing or updating the Assigned User if it is no longer applicable.';
            }

            if (await confirmDialog(message, options)) {
              self.setState({ selected_jurisdiction_id: self.state.current.patient.jurisdiction_id });
              callback();
            }
          } else {
            self.setState({ selected_jurisdiction_id: self.state.current.patient.jurisdiction_id });
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

  renderRiskFactorToggle = (toggleField, toggleLabel, disabled, tooltipText) => {
    const tooltipId = `${toggleField}-tooltip`;
    return (
      <React.Fragment>
        <span data-for={tooltipId} data-tip="">
          <Switch
            id={toggleField}
            checked={this.state.current.patient[String(toggleField)] || false}
            disabled={disabled}
            onChange={value => {
              this.handleRiskFactorToggle(toggleField, value);
            }}
            onColor="#226891"
            offColor="#ADB5BD"
            uncheckedIcon={false}
            checkedIcon={false}
            height={15}
            width={30}
            className="pr-2"
          />
        </span>
        {disabled && (
          <ReactTooltip id={tooltipId} multiline={true} place="right" type="dark" effect="solid">
            <span>{tooltipText}</span>
          </ReactTooltip>
        )}
        <Form.Label htmlFor={toggleField} className="mb-0">
          {toggleLabel}
        </Form.Label>
      </React.Fragment>
    );
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
              onChange={this.handleLDEChange}
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
              disabled={this.state.current.patient.isolation}
            />
            <InfoTooltip tooltipTextKey={this.state.current.patient.isolation ? 'continuousExposureDisabled' : 'continuousExposure'} location="right" />
          </Form.Group>
        </Form.Row>
        <Form.Label className="input-label pb-1">EXPOSURE RISK FACTORS (USE COMMAS TO SEPARATE MULTIPLE SPECIFIED VALUES)</Form.Label>
        <Form.Row className="risk-factor-row mb-1">
          <Form.Group as={Col} md="auto" className="mb-0">
            {this.renderRiskFactorToggle(
              'contact_of_known_case',
              'CLOSE CONTACT WITH A KNOWN CASE',
              this.state.current.patient.contact_of_known_case_id?.length > 0,
              'The Case ID field must be cleared to de-toggle'
            )}
          </Form.Group>
          <Form.Group as={Col} md="auto" className="mb-0 ml-4 pt-1">
            <Form.Control
              size="sm"
              className="form-square"
              id="contact_of_known_case_id"
              placeholder="enter case ID"
              value={this.state.current.patient.contact_of_known_case_id || ''}
              onChange={this.handleRiskFactorChange}
              aria-label="Enter Case Id"
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['contact_of_known_case_id']}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
        <Form.Row className="risk-factor-row mb-1">
          <Form.Group as={Col} md="auto" className="mb-0">
            {this.renderRiskFactorToggle('travel_to_affected_country_or_area', 'TRAVEL FROM AFFECTED COUNTRY OR AREA')}
          </Form.Group>
        </Form.Row>
        <Form.Row className="risk-factor-row mb-1">
          <Form.Group as={Col} md="auto" className="mb-0">
            {this.renderRiskFactorToggle(
              'was_in_health_care_facility_with_known_cases',
              'WAS IN HEALTHCARE FACILITY WITH KNOWN CASES',
              this.state.current.patient.was_in_health_care_facility_with_known_cases_facility_name?.length > 0,
              'The Facility Name field must be cleared to de-toggle'
            )}
          </Form.Group>
          <Form.Group as={Col} md="auto" className="mb-0 ml-4 pt-1">
            <Form.Control
              size="sm"
              className="form-square"
              id="was_in_health_care_facility_with_known_cases_facility_name"
              placeholder="enter facility name"
              value={this.state.current.patient.was_in_health_care_facility_with_known_cases_facility_name || ''}
              onChange={this.handleRiskFactorChange}
              aria-label="Enter Facility Name"
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['was_in_health_care_facility_with_known_cases_facility_name']}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
        <Form.Row className="risk-factor-row mb-1">
          <Form.Group as={Col} md="auto" className="mb-0">
            {this.renderRiskFactorToggle(
              'laboratory_personnel',
              'LABORATORY PERSONNEL',
              this.state.current.patient.laboratory_personnel_facility_name?.length > 0,
              'The Facility Name field must be cleared to de-toggle'
            )}
          </Form.Group>
          <Form.Group as={Col} md="auto" className="mb-0 ml-4 pt-1">
            <Form.Control
              size="sm"
              className="form-square"
              id="laboratory_personnel_facility_name"
              placeholder="enter facility name"
              value={this.state.current.patient.laboratory_personnel_facility_name || ''}
              onChange={this.handleRiskFactorChange}
              aria-label="Enter Laboratory Facility Name"
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['laboratory_personnel_facility_name']}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
        <Form.Row className="risk-factor-row mb-1">
          <Form.Group as={Col} md="auto" className="mb-0">
            {this.renderRiskFactorToggle(
              'healthcare_personnel',
              'HEALTHCARE PERSONNEL',
              this.state.current.patient.healthcare_personnel_facility_name?.length > 0,
              'The Facility Name field must be cleared to de-toggle'
            )}
          </Form.Group>
          <Form.Group as={Col} md="auto" className="mb-0 ml-4 pt-1">
            <Form.Control
              size="sm"
              className="form-square"
              id="healthcare_personnel_facility_name"
              placeholder="enter facility name"
              value={this.state.current.patient.healthcare_personnel_facility_name || ''}
              onChange={this.handleRiskFactorChange}
              aria-label="Enter Healthcare Facility Name"
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['healthcare_personnel_facility_name']}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
        <Form.Row className="risk-factor-row mb-1">
          <Form.Group as={Col} md="auto" className="mb-0">
            {this.renderRiskFactorToggle('crew_on_passenger_or_cargo_flight', 'CREW ON PASSENGER OR CARGO FLIGHT')}
          </Form.Group>
        </Form.Row>
        <Form.Row className="risk-factor-row">
          <Form.Group as={Col} md="auto" className="mb-0">
            {this.renderRiskFactorToggle(
              'member_of_a_common_exposure_cohort',
              'MEMBER OF A COMMON EXPOSURE COHORT',
              this.state.current.common_exposure_cohorts?.length > 0,
              'All cohorts must be deleted to de-toggle'
            )}
          </Form.Group>
        </Form.Row>
        {this.state.current.common_exposure_cohorts?.length > 0 && (
          <div className="enrollment-common-exposure-cohorts-table-wrapper">
            <CommonExposureCohortsTable
              common_exposure_cohorts={this.state.current.common_exposure_cohorts}
              isEditable={true}
              onEditCohort={index => this.toggleCommonExposureCohortModal(true, this.state.current.common_exposure_cohorts[`${index}`], index)}
              onDeleteCohort={this.toggleCohortDeleteDialog}
            />
          </div>
        )}
        <span data-for="add_new_cohort_disable_reason" data-tip="">
          <Button
            id="add-new-cohort-button"
            variant="outline-primary"
            size="md"
            className="btn-square add-new-cohort-button"
            disabled={this.state.current.common_exposure_cohorts?.length >= 10}
            onClick={() => this.toggleCommonExposureCohortModal(true)}>
            Add New Cohort
          </Button>
        </span>
        {this.state.current.common_exposure_cohorts?.length >= 10 && (
          <ReactTooltip id="add_new_cohort_disable_reason" multiline={true} place="right" type="dark" effect="solid" className="tooltip-container">
            <span>You may only add up to 10 cohorts</span>
          </ReactTooltip>
        )}
        {this.state.showCommonExposureCohortModal && (
          <CommonExposureCohortModal
            common_exposure_cohort={this.state.common_exposure_cohort}
            common_exposure_cohort_index={this.state.common_exposure_cohort_index}
            cohort_names={this.state.cohort_names}
            cohort_locations={this.state.cohort_locations}
            onChange={this.handleCohortChange}
            onHide={() => this.toggleCommonExposureCohortModal(false)}
          />
        )}
        {!this.props.currentState.isolation && (
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
                  {!this.props.currentState.isolation && (
                    <PublicHealthManagement
                      currentState={this.state.current}
                      onChange={this.handlePublicHealthManagementChange}
                      onPropagatedFieldChange={this.handlePropagatedFieldChange}
                      patient={this.props.patient}
                      has_dependents={this.props.has_dependents}
                      jurisdiction_paths={this.props.jurisdiction_paths}
                      assigned_users={this.props.assigned_users}
                      schema={schema}
                      errors={this.state.errors}
                      authenticity_token={this.props.authenticity_token}
                    />
                  )}
                </Form.Group>
              </Form.Row>
            </Form>
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
  showPreviousButton: PropTypes.bool,
  authenticity_token: PropTypes.string,
  current_user: PropTypes.object,
};

export default ExposureInformation;
