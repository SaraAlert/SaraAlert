import React from 'react';
import { PropTypes } from 'prop-types';
import { Alert, Button, Card, Col, Form } from 'react-bootstrap';
import Select from 'react-select';
import { bootstrapSelectTheme, cursorPointerStyleLg } from '../../../packs/stylesheets/ReactSelectStyling';

import _ from 'lodash';
import * as yup from 'yup';
import moment from 'moment-timezone';

import DateInput from '../../util/DateInput';
import InfoTooltip from '../../util/InfoTooltip';
import { getLanguageData } from '../../../utils/Languages';

let workflow_options;

// the terms 'contact' and 'case' are used commonly in public health settings,
// so we want to include them here in the UI for clarity
let publicHealthTerms = {
  exposure: 'Exposure (contact)',
  isolation: 'Isolation (case)',
};

class Identification extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      current: { ...this.props.currentState },
      errors: {},
      modified: {},
      primaryLanguageData: {},
      secondaryLanguageData: {},
      languageOptions: [], // store these on state so the component re-renders when they are returned asynchronously
    };
    workflow_options = props.available_workflows.map(wf => ({ value: wf.name, label: publicHealthTerms[`${wf.name}`] }));
  }

  componentDidMount() {
    getLanguageData(this.props.authenticity_token, languageData => {
      const langOptions = languageData.map(lang => {
        const fullySupported = lang.supported.sms && lang.supported.email && lang.supported.phone;
        const langLabel = fullySupported ? lang.display : lang.display + '*';
        return { value: lang.code, label: langLabel };
      });

      // lodash's 'remove()' actually removes the values from the object
      let supportedLangCodes = languageData.filter(l => l.supported.sms || l.supported.email || l.supported.phone).map(x => x.code);
      const supportedLangsFormatted = _.remove(langOptions, n => supportedLangCodes.includes(n.value));
      const unsupportedLangsFormatted = langOptions;

      // For each language, get the support options
      const groupedOptions = [
        {
          label: 'Supported Languages',
          options: supportedLangsFormatted,
        },
        {
          label: 'Unsupported Languages',
          options: unsupportedLangsFormatted,
        },
      ];
      let primaryLanguageData = {},
        secondaryLanguageData = {};

      let primaryLanguageRef = languageData.find(x => x.code === this.state.current.patient.primary_language);
      if (primaryLanguageRef) {
        primaryLanguageData.code = primaryLanguageRef?.code;
        primaryLanguageData.display = primaryLanguageRef?.display;
        primaryLanguageData.supported = primaryLanguageRef?.supported;
      }
      let secondaryLanguageRef = languageData.find(x => x.code === this.state.current.patient.secondary_language);
      if (secondaryLanguageRef) {
        secondaryLanguageData.code = secondaryLanguageRef?.code;
        secondaryLanguageData.display = secondaryLanguageRef?.display;
        secondaryLanguageData.supported = secondaryLanguageRef?.display;
      }
      this.setState({ languageData, languageOptions: groupedOptions, primaryLanguageData, secondaryLanguageData });
    });
  }

  handleChange = event => {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let modified = this.state.modified;
    event.persist();
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

  // Special function for handling race selection: If an exclusive race value (e.g. "unknown" or "refused to answer")
  // is selected, unselects all other checkboxes, and if a standard race value (e.g. "white, black or african american", "other")
  // is selected, unselects all exclusive checkboxes.
  handleRaceChange = event => {
    let value = event.target.checked;
    let modified_races = {};
    let current = this.state.current;
    let modified = this.state.modified;
    event.persist();

    if (value) {
      // Reset exclusive races if any option is selected
      let races_to_reset = this.props.race_options.exclusive;

      // Reset all races if exclusive option is selected
      if (this.props.race_options.exclusive.map(options => options.race).includes(event.target.id)) {
        races_to_reset = races_to_reset.concat(this.props.race_options.non_exclusive);
      }

      races_to_reset.forEach(option => {
        modified_races[`${option.race}`] = false;
      });
    }

    // Set race to value
    modified_races[`${event.target.id}`] = value;
    this.setState(
      {
        current: { ...current, patient: { ...current.patient, ...modified_races } },
        modified: { ...modified, patient: { ...current.patient, ...modified_races } },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };

  handleWorkflowChange = event => {
    const value = event.value;
    const current = this.state.current;
    const modified = this.state.modified;
    const isIsolation = value === 'isolation';
    this.setState(
      {
        current: { ...current, isolation: isIsolation, patient: { ...current.patient, isolation: isIsolation } },
        modified: { ...modified, isolation: isIsolation, patient: { ...modified.patient, isolation: isIsolation } },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };
  // At the current moment, it is assumed that at least one of `isolation` and `exposure` will be an available workflow option.
  getWorkflowValue = () =>
    this.state.current.isolation ? workflow_options.find(wf => wf.value === 'isolation') : workflow_options.find(wf => wf.value === 'exposure');

  handleDOBChange = date => {
    const date_of_birth = date;
    let age;

    // If date is undefined, age will stay undefined (which nulls out the age field)
    if (date_of_birth) {
      age = moment().diff(moment(date_of_birth), 'years');
      age = age >= 0 ? age : this.state.age;
    }

    this.setState(
      state => {
        return {
          current: { ...state.current, patient: { ...state.current.patient, date_of_birth, age } },
          modified: { ...state.modified, patient: { ...state.modified.patient, date_of_birth, age } },
        };
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };

  /**
   * @param {Object} event - In the structure of {value: 'eng', label: 'English'}
   * @param {Boolean} isPrimary - whether to handle the change of the primary or secondary language
   */
  handleLanguageChange = (event, isPrimary) => {
    const current = this.state.current;
    const modified = this.state.modified;
    const languageType = isPrimary ? 'primary_language' : 'secondary_language';
    const languageData = isPrimary ? 'primaryLanguageData' : 'secondaryLanguageData';

    let langRef = event === null ? null : this.state.languageData.find(x => x.code === event.value);
    let primaryLanguageData = langRef ? { code: langRef.code, display: langRef.display, supported: langRef.supported } : {};
    this.setState(
      {
        current: { ...current, patient: { ...current.patient, [languageType]: primaryLanguageData.code || null } },
        modified: { ...modified, patient: { ...modified.patient, [languageType]: primaryLanguageData.code || null } },
        [languageData]: primaryLanguageData,
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };

  validate = callback => {
    schema
      .validate(this.state.current.patient, { abortEarly: false })
      .then(() => {
        // No validation issues? Invoke callback (move to next step)
        this.setState({ errors: {} }, () => {
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
          this.setState({ errors: issues });
        }
      });
  };

  renderWarningBanner = message => {
    return (
      <Alert variant="warning" className="mt-2 mb-0 px-3 py-2">
        <i>
          <b>Warning:</b> {message}
        </i>
      </Alert>
    );
  };

  renderPrimaryLanguageSupportMessage = () => {
    let selectedLanguage = this.state.primaryLanguageData;
    if (!_.isEmpty(selectedLanguage)) {
      const sms = selectedLanguage.supported.sms;
      const email = selectedLanguage.supported.email;
      const phone = selectedLanguage.supported.phone;
      const fullySupported = sms && email && phone;

      if (!fullySupported) {
        let message = selectedLanguage.display;
        if (!sms && !email && !phone) {
          message += ' is not currently supported by Sara Alert. Any messages sent to this monitoree will be in English.';
        } else if (!sms && !email && phone) {
          message +=
            ' is supported for the telephone call method only. If email or an SMS text reporting method is selected as the preferred reporting method, messages will be in English.';
        } else if (!sms && email && !phone) {
          message +=
            ' is supported for the email weblink method only. If telephone call or an SMS text reporting method is selected as the preferred reporting method, messages will be in English.';
        } else if (!sms && email && phone) {
          message +=
            ' is supported for telephone call and email reporting methods only. If an SMS text reporting method is selected as the preferred reporting method, the text will be in English.';
        } else if (sms && !email && !phone) {
          message +=
            ' is supported for SMS text reporting methods only. If telephone call or email is selected as the preferred reporting method, messages will be in English.';
        } else if (sms && !email && phone) {
          message +=
            ' is supported for telephone call and SMS text reporting methods only. If email is selected as the preferred reporting method, the email will be in English.';
        } else if (sms && email && !phone) {
          message +=
            ' is supported for email and SMS text reporting methods only. If telephone call is selected as the preferred reporting method, the call will be in English.';
        }
        return this.renderWarningBanner(message);
      }
    }
  };

  /**
   *
   * @param {*} isPrimary - whether to render the primary or secondary language Select
   */
  renderLanguageSelect = isPrimary => {
    let inputId, value;
    if (isPrimary) {
      inputId = 'primary-language-select';
      value = { label: this.state.primaryLanguageData.display, value: this.state.primaryLanguageData.code };
    } else {
      inputId = 'secondary-language-select';
      value = { label: this.state.secondaryLanguageData.display, value: this.state.secondaryLanguageData.code };
    }
    return (
      <Select
        inputId={inputId}
        isClearable={value.value}
        value={value}
        options={this.state.languageOptions}
        onChange={e => this.handleLanguageChange(e, isPrimary)}
        placeholder=""
        styles={cursorPointerStyleLg}
        theme={theme => bootstrapSelectTheme(theme, 'lg')}
      />
    );
  };

  render() {
    const exclusive_race_selected = !!this.state.current.patient.race_unknown || !!this.state.current.patient.race_refused_to_answer;
    return (
      <React.Fragment>
        <h1 className="sr-only">Monitoree Identification</h1>
        <Card className="mx-2 card-square">
          <Card.Header className="h5">Monitoree Identification</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row>
                <Form.Group as={Col} id="workflow_wrapper">
                  <Form.Label htmlFor="workflow-select" className="input-label">
                    WORKFLOW *
                  </Form.Label>
                  <Select
                    inputId="workflow-select"
                    styles={cursorPointerStyleLg}
                    value={this.getWorkflowValue()}
                    options={workflow_options}
                    onChange={e => this.handleWorkflowChange(e)}
                    placeholder=""
                    theme={theme => bootstrapSelectTheme(theme, 'lg')}
                  />
                </Form.Group>
              </Form.Row>
              <Form.Row>
                <Form.Group as={Col} controlId="first_name">
                  <Form.Label className="input-label">FIRST NAME{schema?.fields?.first_name?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['first_name']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.first_name || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['first_name']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} controlId="middle_name">
                  <Form.Label className="input-label">MIDDLE NAME(S){schema?.fields?.middle_name?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['middle_name']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.middle_name || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['middle_name']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} controlId="last_name">
                  <Form.Label className="input-label">LAST NAME{schema?.fields?.last_name?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['last_name']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.last_name || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['last_name']}
                  </Form.Control.Feedback>
                </Form.Group>
              </Form.Row>
              <Form.Row>
                <Form.Group as={Col} md="auto" controlId="date_of_birth">
                  <Form.Label className="input-label">DATE OF BIRTH{schema?.fields?.date_of_birth?._exclusive?.required && ' *'}</Form.Label>
                  <DateInput
                    id="date_of_birth"
                    date={this.state.current.patient.date_of_birth}
                    minDate={'1900-01-01'}
                    maxDate={moment().format('YYYY-MM-DD')}
                    onChange={this.handleDOBChange}
                    placement="bottom"
                    isInvalid={!!this.state.errors['date_of_birth']}
                    clearInvalid={true}
                    customClass="form-control-lg"
                    ariaLabel="Date of Birth Input"
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['date_of_birth']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} md="1"></Form.Group>
                <Form.Group as={Col} controlId="age" md="auto">
                  <Form.Label className="input-label">AGE{schema?.fields?.age?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['age']}
                    placeholder=""
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.age === undefined ? '' : this.state.current.patient.age}
                    onChange={this.handleChange}
                    disabled
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['age']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} md="1"></Form.Group>
                <Form.Group as={Col} controlId="sex" md="auto">
                  <Form.Label className="input-label">SEX AT BIRTH{schema?.fields?.sex?._exclusive?.required && ' *'}</Form.Label>
                  <InfoTooltip tooltipTextKey="sexAtBirth" location="right"></InfoTooltip>
                  <Form.Control
                    isInvalid={this.state.errors['sex']}
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.sex || ''}
                    onChange={this.handleChange}>
                    <option></option>
                    <option>Female</option>
                    <option>Male</option>
                    <option>Unknown</option>
                  </Form.Control>
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['sex']}
                  </Form.Control.Feedback>
                </Form.Group>
              </Form.Row>
              <Form.Row>
                <Form.Group as={Col} controlId="gender_identity" md="auto">
                  <Form.Label className="input-label">GENDER IDENTITY{schema?.fields?.gender_identity?._exclusive?.required && ' *'}</Form.Label>
                  <InfoTooltip tooltipTextKey="genderIdentity" location="right"></InfoTooltip>
                  <Form.Control
                    isInvalid={this.state.errors['gender_identity']}
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.gender_identity || ''}
                    onChange={this.handleChange}>
                    <option></option>
                    <option>Male (Identifies as male)</option>
                    <option>Female (Identifies as female)</option>
                    <option>Transgender Male (Female-to-Male [FTM])</option>
                    <option>Transgender Female (Male-to-Female [MTF])</option>
                    <option>Genderqueer / gender nonconforming (neither exclusively male nor female)</option>
                    <option>Another</option>
                    <option>Chose not to disclose</option>
                  </Form.Control>
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['gender_identity']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} controlId="sexual_orientation" md="auto">
                  <Form.Label className="input-label">SEXUAL ORIENTATION{schema?.fields?.sexual_orientation?._exclusive?.required && ' *'}</Form.Label>
                  <InfoTooltip tooltipTextKey="sexualOrientation" location="right"></InfoTooltip>
                  <Form.Control
                    isInvalid={this.state.errors['sexual_orientation']}
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.sexual_orientation || ''}
                    onChange={this.handleChange}>
                    <option></option>
                    <option>Straight or Heterosexual</option>
                    <option>Lesbian, Gay, or Homosexual</option>
                    <option>Bisexual</option>
                    <option>Another</option>
                    <option>Choose not to disclose</option>
                    <option>Don’t know</option>
                  </Form.Control>
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['sexual_orientation']}
                  </Form.Control.Feedback>
                </Form.Group>
              </Form.Row>
              <Form.Row>
                <Form.Group as={Col} md="auto">
                  <Form.Label className="input-label">
                    RACE (SELECT ALL THAT APPLY)<InfoTooltip tooltipTextKey="race" location="right"></InfoTooltip>
                  </Form.Label>
                  {this.props.race_options.non_exclusive.map(option => {
                    return (
                      <Form.Check
                        className="py-1"
                        type="checkbox"
                        id={option.race}
                        label={option.label}
                        checked={!!this.state.current.patient[`${option.race}`]}
                        disabled={exclusive_race_selected}
                        onChange={this.handleRaceChange}
                        key={option.race}
                      />
                    );
                  })}
                  {this.props.race_options.exclusive.map(option => {
                    return (
                      <Form.Check
                        className="py-1"
                        type="checkbox"
                        id={option.race}
                        label={option.label}
                        checked={!!this.state.current.patient[`${option.race}`]}
                        disabled={exclusive_race_selected && !this.state.current.patient[`${option.race}`]}
                        onChange={this.handleRaceChange}
                        key={option.race}
                      />
                    );
                  })}
                </Form.Group>
                <Form.Group as={Col} md="8" controlId="ethnicity">
                  <Form.Label className="input-label">ETHNICITY{schema?.fields?.ethnicity?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control as="select" size="lg" className="form-square" value={this.state.current.patient.ethnicity || ''} onChange={this.handleChange}>
                    <option></option>
                    <option>Not Hispanic or Latino</option>
                    <option>Hispanic or Latino</option>
                    <option>Unknown</option>
                    <option>Refused to Answer</option>
                  </Form.Control>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-3 ml-0 mb-0">
                <div className="input-label">LANGUAGE</div>
              </Form.Row>
              <Form.Row className="pb-3 ml-0">Languages that are not fully supported are indicated by a (*) in the below list.</Form.Row>
              <Form.Row>
                <Form.Group as={Col} sm={24} md={12} id="primary_language_wrapper" className="pr-md-1 mb-3">
                  <Form.Label htmlFor="primary-language-select" className="input-label">
                    PRIMARY LANGUAGE{schema?.fields?.primary_language?._exclusive?.required && ' *'}
                    <InfoTooltip tooltipTextKey="primaryLanguage" location="right"></InfoTooltip>
                  </Form.Label>
                  {this.renderLanguageSelect(true)}
                  {this.renderPrimaryLanguageSupportMessage()}
                </Form.Group>
                <Form.Group as={Col} sm={24} md={12} id="secondary_language_wrapper" className="pl-md-1 mb-3">
                  <Form.Label htmlFor="secondary-language-select" className="input-label">
                    SECONDARY LANGUAGE{schema?.fields?.secondary_language?._exclusive?.required && ' *'}
                    <InfoTooltip tooltipTextKey="secondaryLanguage" location="right"></InfoTooltip>
                  </Form.Label>
                  {this.renderLanguageSelect(false)}
                  {this.state.current.patient.secondary_language &&
                    this.renderWarningBanner('Not used to determine which language the system sends messages to the monitoree in.')}
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-1">
                <Form.Group as={Col}>
                  <Form.Check
                    type="switch"
                    id="interpretation_required"
                    label="INTERPRETATION REQUIRED"
                    checked={this.state.current.patient.interpretation_required || false}
                    onChange={this.handleChange}
                  />
                </Form.Group>
              </Form.Row>
              <Form.Row>
                <Form.Group as={Col} md={12} controlId="nationality">
                  <Form.Label className="input-label">NATIONALITY{schema?.fields?.nationality?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['nationality']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.nationality || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['nationality']}
                  </Form.Control.Feedback>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pb-2">
                <Form.Group as={Col} md={8} controlId="user_defined_id_statelocal">
                  <Form.Label className="input-label">STATE/LOCAL ID{schema?.fields?.user_defined_id_statelocal?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['user_defined_id_statelocal']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.user_defined_id_statelocal || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['user_defined_id_statelocal']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} md={8} controlId="user_defined_id_cdc">
                  <Form.Label className="input-label">CDC ID{schema?.fields?.user_defined_id_cdc?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['user_defined_id_cdc']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.user_defined_id_cdc || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['user_defined_id_cdc']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} md={8} controlId="user_defined_id_nndss">
                  <Form.Label className="input-label">
                    NNDSS LOC. REC. ID/CASE ID{schema?.fields?.user_defined_id_nndss?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['user_defined_id_nndss']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.patient.user_defined_id_nndss || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['user_defined_id_nndss']}
                  </Form.Control.Feedback>
                </Form.Group>
              </Form.Row>
            </Form>
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

const schema = yup.object().shape({
  first_name: yup
    .string()
    .required('Please enter a First Name.')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  middle_name: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  last_name: yup
    .string()
    .required('Please enter a Last Name.')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  date_of_birth: yup
    .date('Date must correspond to the "mm/dd/yyyy" format.')
    .required('Please enter a Date of Birth.')
    .max(new Date(), 'Date can not be in the future.')
    .nullable(),
  age: yup.number().nullable(),
  sex: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  white: yup.boolean().nullable(),
  black_or_african_american: yup.boolean().nullable(),
  american_indian_or_alaska_native: yup.boolean().nullable(),
  asian: yup.boolean().nullable(),
  native_hawaiian_or_other_pacific_islander: yup.boolean().nullable(),
  ethnicity: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  primary_language: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  secondary_language: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  interpretation_required: yup.boolean().nullable(),
  nationality: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  user_defined_id: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
});

Identification.propTypes = {
  currentState: PropTypes.object,
  race_options: PropTypes.object,
  next: PropTypes.func,
  setEnrollmentState: PropTypes.func,
  authenticity_token: PropTypes.string,
  available_workflows: PropTypes.array,
};

export default Identification;
