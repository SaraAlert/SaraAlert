import React from 'react';
import { PropTypes } from 'prop-types';
import { Alert, Button, Card, Col, Form } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import axios from 'axios';
import * as yup from 'yup';
import moment from 'moment';
import _ from 'lodash';

import confirmDialog from '../../util/ConfirmDialog';
import DateInput from '../../util/DateInput';
import InfoTooltip from '../../util/InfoTooltip';
import FirstPositiveLaboratory from '../../patient/laboratory/FirstPositiveLaboratory';

class CaseInformation extends React.Component {
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

      // trim call included since there is a bug with yup validation for numbers that allows whitespace entry
      value = _.trim(event.target.value) === '' ? null : parseInt(event.target.value);
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

  updateStaticValidations = first_positive_lab => {
    this.updateIsolationValidations(this.props.currentState.patient, first_positive_lab);
  };

  updateIsolationValidations = (patient, first_positive_lab) => {
    if (!patient.symptom_onset && !first_positive_lab?.specimen_collection) {
      schema = yup.object().shape({
        ...staticValidations,
        symptom_onset: yup
          .date('Date must correspond to the "mm/dd/yyyy" format.')
          .max(moment().toDate(), 'Date can not be in the future.')
          .required('Please enter a Symptom Onset Date AND/OR a positive lab result.')
          .nullable(),
      });
    } else if (patient.symptom_onset) {
      schema = yup.object().shape({
        ...staticValidations,
        symptom_onset: yup
          .date('Date must correspond to the "mm/dd/yyyy" format.')
          .max(moment().toDate(), 'Date can not be in the future.')
          .required('Please enter a Symptom Onset Date AND/OR a positive lab result.')
          .nullable(),
      });
    } else {
      schema = yup.object().shape({
        ...staticValidations,
        symptom_onset: yup.date('Date must correspond to the "mm/dd/yyyy" format.').max(moment().toDate(), 'Date can not be in the future.').nullable(),
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
            if (self.state.jurisdiction_path === self.state.selected_jurisdiction) {
              callback();
              return;
            }
            const originalJurisdictionPath = self.props.jurisdiction_paths[self.state.originalJurisdictionId];
            const message = `You are about to change the Assigned Jurisdiction from ${originalJurisdictionPath} to ${self.state.jurisdiction_path}. Are you sure you want to do this?`;
            const options = { title: 'Confirm Jurisdiction Change' };

            if (self.state.current.patient.assigned_user && self.state.current.patient.assigned_user === self.state.originalAssignedUser) {
              options.additionalNote = 'Please also consider removing or updating the Assigned User if it is no longer applicable.';
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
            <FirstPositiveLaboratory lab={this.state.current.first_positive_lab} onChange={this.handleLabChange} size="lg" displayedLabClass="mx-1 mb-2" />
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

  /**
   * Due to how the validation works, these fields are defined in both the CaseInformation and ExposureInformation components instead of broken out into a new component.
   * If you update this render method or related functionality, be sure to update in the ExposureInformation component as well.
   */
  renderPublicHealthManagementFields = () => {
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
                    checked={this.state.current.propagatedFields.jurisdiction_id || false}
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
                    checked={this.state.current.propagatedFields.assigned_user || false}
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
              <option></option>
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
                  {this.renderPublicHealthManagementFields()}
                </Form.Group>
              </Form.Row>
            </Form>
            {this.props.previous && !this.props.hidePreviousButton && (
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
  hidePreviousButton: PropTypes.bool,
  authenticity_token: PropTypes.string,
  edit_mode: PropTypes.bool,
};

export default CaseInformation;
