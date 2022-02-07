import React from 'react';
import { PropTypes } from 'prop-types';
import { Alert, Button, Card, Col, Form } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import * as yup from 'yup';
import moment from 'moment';
import _ from 'lodash';

import PublicHealthManagement from './PublicHealthManagement';
import FirstPositiveLaboratory from '../../patient/laboratory/FirstPositiveLaboratory';
import confirmDialog from '../../util/ConfirmDialog';
import DateInput from '../../util/DateInput';

class CaseInformation extends React.Component {
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
    };
  }

  componentDidMount() {
    this.updateStaticValidations(this.props.first_positive_lab);
  }

  componentDidUpdate(prevProps) {
    if (prevProps.currentState.isolation !== this.props.currentState.isolation) {
      this.updateStaticValidations(this.props.first_positive_lab);
    }
  }

  handleChange = event => {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let modified = this.state.modified;
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

  handleSymptomOnsetChange = date => {
    let current = this.state.current;
    let modified = this.state.modified;
    this.updateIsolationValidations({ ...current.patient, symptom_onset: date }, this.state.current.first_positive_lab);
    this.setState(
      {
        current: { ...current, patient: { ...current.patient, symptom_onset: date } },
        modified: { ...modified, patient: { ...modified.patient, symptom_onset: date } },
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

  updateStaticValidations = first_positive_lab => {
    this.updateIsolationValidations(this.props.currentState.patient, first_positive_lab);
  };

  updateIsolationValidations = (patient, first_positive_lab) => {
    if (!patient.symptom_onset && !first_positive_lab?.specimen_collection) {
      schema = yup.object().shape({
        ...staticValidations,
        symptom_onset: yup
          .date('Date must correspond to the "mm/dd/yyyy" format.')
          .max(moment().toDate(), 'Date cannot be in the future.')
          .required('Please enter a Symptom Onset Date AND/OR a positive lab result.')
          .nullable(),
      });
    } else if (patient.symptom_onset) {
      schema = yup.object().shape({
        ...staticValidations,
        symptom_onset: yup
          .date('Date must correspond to the "mm/dd/yyyy" format.')
          .max(moment().toDate(), 'Date cannot be in the future.')
          .required('Please enter a Symptom Onset Date AND/OR a positive lab result.')
          .nullable(),
      });
    } else {
      schema = yup.object().shape({
        ...staticValidations,
        symptom_onset: yup.date('Date must correspond to the "mm/dd/yyyy" format.').max(moment().toDate(), 'Date cannot be in the future.').nullable(),
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

  renderIsolationFields = () => {
    return (
      <React.Fragment>
        {!this.state.current.patient.symptom_onset && !this.state.current.first_positive_lab && (
          <Alert variant="warning" className="alert-warning-text">
            You must enter a Symptom Onset Date AND/OR a <b style={{ fontWeight: 800 }}>positive</b> lab result (with a Specimen Collection Date) to enroll this
            case.
          </Alert>
        )}
        <Form.Row>
          <Form.Group as={Col} md={12} xs={24} controlId="symptom_onset" className="mb-2">
            <Form.Label className="input-label">
              SYMPTOM ONSET DATE
              {this.props.patient.symptom_onset && this.state.current.patient.symptom_onset && (
                <div style={{ display: 'inline' }}>
                  <span data-for="user_defined_symptom_onset_tooltip" data-tip="" className="ml-2">
                    {this.props.patient.user_defined_symptom_onset ? <i className="fas fa-user"></i> : <i className="fas fa-desktop"></i>}
                  </span>
                  <ReactTooltip id="user_defined_symptom_onset_tooltip" multiline={true} place="right" type="dark" effect="solid" className="tooltip-container">
                    {this.props.patient.user_defined_symptom_onset ? (
                      <span>This date was set by a user</span>
                    ) : (
                      <span>
                        This date is auto-populated by the system as the date of the earliest report flagged as symptomatic (red highlight) in the reports
                        table. Field is blank when there are no symptomatic reports.
                      </span>
                    )}
                  </ReactTooltip>
                </div>
              )}
            </Form.Label>
            <DateInput
              id="symptom_onset"
              aria-label="Symptom Onset Date"
              date={this.state.current.patient.symptom_onset}
              minDate={'2020-01-01'}
              maxDate={moment().format('YYYY-MM-DD')}
              onChange={this.handleSymptomOnsetChange}
              placement="bottom"
              isInvalid={!!this.state.errors['symptom_onset']}
              isClearable={!!this.props.patient.user_defined_symptom_onset || !this.props.patient.symptom_onset}
              customClass="form-control-lg"
              ariaLabel="Symptom Onset Date Input"
            />
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['symptom_onset']}
            </Form.Control.Feedback>
          </Form.Group>
          <Form.Group as={Col} md={12} xs={24} controlId="first_positive_lab" className="mb-2">
            <FirstPositiveLaboratory
              lab={this.state.current.first_positive_lab}
              preventDelete={this.props.first_positive_lab != null}
              onChange={this.handleLabChange}
              size="lg"
              displayedLabClass="mx-1 mb-2"
            />
          </Form.Group>
          <Form.Group as={Col} md={12} xs={24} controlId="case_status" className="mb-2">
            <Form.Label className="input-label">CASE STATUS{schema?.fields?.case_status?._exclusive?.required && ' *'}</Form.Label>
            <Form.Control
              isInvalid={this.state.errors['case_status']}
              as="select"
              size="lg"
              className="form-square"
              aria-label="Case Status Select"
              onChange={this.handleChange}
              value={this.state.current.patient.case_status || ''}>
              <option></option>
              <option>Confirmed</option>
              <option>Probable</option>
            </Form.Control>
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['case_status']}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
        <Form.Row>
          <Form.Group as={Col} md="24" controlId="exposure_notes" className="mb-2">
            <Form.Label className="input-label ml-1">NOTES{schema?.fields?.exposure_notes?._exclusive?.required && ' *'}</Form.Label>
            <Form.Control
              isInvalid={this.state.errors['exposure_notes']}
              as="textarea"
              rows="4"
              size="lg"
              className="form-square"
              placeholder="enter additional information about case"
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
      </React.Fragment>
    );
  };

  render() {
    return (
      <React.Fragment>
        <h1 className="sr-only">Monitoree Case Information</h1>
        <Card className="mx-2 card-square">
          <Card.Header className="h5">Monitoree Case Information</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row className="pb-3 h-100">
                <Form.Group as={Col} className="my-auto">
                  {this.renderIsolationFields()}
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

CaseInformation.propTypes = {
  currentState: PropTypes.object,
  setEnrollmentState: PropTypes.func,
  previous: PropTypes.func,
  next: PropTypes.func,
  patient: PropTypes.object,
  has_dependents: PropTypes.bool,
  jurisdiction_paths: PropTypes.object,
  assigned_users: PropTypes.array,
  first_positive_lab: PropTypes.object,
  showPreviousButton: PropTypes.bool,
  authenticity_token: PropTypes.string,
  edit_mode: PropTypes.bool,
};

export default CaseInformation;
