import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Button, Form } from 'react-bootstrap';
import _ from 'lodash';
import confirmDialog from '../../util/ConfirmDialog';

class SymptomsAssessment extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      assessmentState: { symptoms: this.props.symptoms },
      loading: false,
      noSymptomsCheckbox: false,
      selectedBoolSymptomCount: 0,
    };
  }

  setAssessmentState = assessmentState => {
    let currentAssessmentState = this.state.assessmentState;
    this.setState({ assessmentState: { ...currentAssessmentState, ...assessmentState } });
  };

  handleChange = event => {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let assessment = this.state.assessmentState;
    let field_id = event.target.id.split('_idpre')[0];
    Object.values(assessment.symptoms).find(symp => symp.name === field_id).value = value;
    this.setAssessmentState({ ...this.state.assessmentState });
    this.updateBoolSymptomCount();
  };

  handleNoSymptomChange = event => {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    this.setState({ noSymptomsCheckbox: value }, () => {
      // Make sure pre-selected options are cleared
      if (this.state.noSymptomsCheckbox) {
        let assessment = { ...this.state.assessmentState };
        for (const symptom in assessment?.symptoms) {
          if (assessment?.symptoms[parseInt(symptom)]?.type == 'BoolSymptom') {
            assessment.symptoms[parseInt(symptom)].value = false;
          }
        }
        this.setAssessmentState({ ...this.state.assessmentState });
      }
    });
  };

  updateBoolSymptomCount = () => {
    let trueBoolSymptoms = this.state.assessmentState.symptoms.filter(s => {
      return s.type === 'BoolSymptom' && s.value;
    });
    this.setState({ selectedBoolSymptomCount: trueBoolSymptoms.length });
  };

  // TODO: This needs to use generic symptoms lists and not be hard-coded
  hasChanges = () => {
    let currentAssessment = _.cloneDeep(this.props.assessment);
    let symptoms = ['cough', 'difficulty_breathing', 'symptomatic'];
    // Having falsey values on them causes the comparison to fail.
    symptoms.forEach(symptom => {
      if (currentAssessment[parseInt(symptom)] === false) {
        delete currentAssessment[parseInt(symptom)];
      }
    });
    return !_.isEqual(this.state.assessmentState, currentAssessment);
  };

  fieldIsEmptyOrNew = object => {
    const keysToIgnore = ['who_reported'];
    let allFieldsEmpty = true;
    _.map(object, (value, key) => {
      if (object[String(key)] !== null && !keysToIgnore.includes(key)) {
        allFieldsEmpty = false;
      }
    });
    if (allFieldsEmpty || _.isEmpty(this.props.assessment)) {
      return true;
    } else {
      return false;
    }
  };

  navigate = () => {
    this.setState({ loading: true }, () => {
      this.handleSubmit();
    });
  };

  handleSubmit = async () => {
    if (this.fieldIsEmptyOrNew(this.props.assessment)) {
      this.props.submit(this.state.assessmentState);
    } else {
      if (this.hasChanges()) {
        if (await confirmDialog("Are you sure you'd like to modify this report?")) {
          this.props.submit(this.state.assessmentState);
        } else {
          this.setState({ loading: false });
          // to do: reset modal??
        }
      } else {
        this.props.submit(this.state.assessmentState);
      }
    }
  };

  noSymptom = () => {
    let noSymptomsChecked = this.state.noSymptomsCheckbox;
    let boolSymptomsSelected = this.state.selectedBoolSymptomCount > 0 ? true : false;

    return (
      <Form.Check
        type="checkbox"
        checked={noSymptomsChecked}
        disabled={boolSymptomsSelected}
        aria-label="No Symptoms check"
        label={
          <div>
            <b>{this.props.translations[this.props.lang]['symptoms']['no-symptoms']}</b>
          </div>
        }
        className="pb-2"
        onChange={this.handleNoSymptomChange}></Form.Check>
    );
  };

  boolSymptom = symp => {
    // null bool values will default to false
    symp.value = symp.value === true;
    let noSymptomsChecked = this.state.noSymptomsCheckbox;

    return (
      <Form.Check
        type="checkbox"
        id={`${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`}
        key={`key_${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`}
        checked={symp.value}
        disabled={noSymptomsChecked}
        aria-label={`${symp.name} Symptom Check`}
        label={
          <div>
            <b>{this.props.translations[this.props.lang]['symptoms'][symp.name]['name']}</b>{' '}
            {this.props.translations[this.props.lang]['symptoms'][symp.name]['notes']
              ? ' ' + this.props.translations[this.props.lang]['symptoms'][symp.name]['notes']
              : ''}
          </div>
        }
        className="pb-2"
        onChange={this.handleChange}></Form.Check>
    );
  };

  floatSymptom = symp => {
    const key = `key_${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`;
    const id = `${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`;
    return (
      <Form.Row className="pt-3" key={key}>
        <Form.Label className="nav-input-label" key={key} htmlFor={id}>
          <b>{this.props.translations[this.props.lang]['symptoms'][symp.name]['name']}</b>{' '}
          {this.props.translations[this.props.lang]['symptoms'][symp.name]['notes']
            ? ' ' + this.props.translations[this.props.lang]['symptoms'][symp.name]['notes']
            : ''}
        </Form.Label>
        <Form.Control size="lg" id={id} key={key} className="form-square" value={symp.value || ''} type="number" onChange={this.handleChange} />
      </Form.Row>
    );
  };

  render() {
    return (
      <Card className="mx-0 card-square">
        <Card.Header className="h4">
          {this.props.translations[this.props.lang]['web']['title']}&nbsp;
          {this.props.patient_initials && this.props.patient_age !== null && (
            <span>
              ({this.props.patient_initials}-{this.props.patient_age})
            </span>
          )}
          {this.props.patient_initials && this.props.patient_age === null && <span>({this.props.patient_initials})</span>}
          {!this.props.patient_initials && this.props.patient_age !== null && <span>({this.props.patient_age})</span>}
        </Card.Header>
        <Card.Body>
          <Form.Row>
            <Form.Label className="nav-input-label pb-3">{this.props.translations[this.props.lang]['web']['bool-title']}</Form.Label>
          </Form.Row>
          <Form.Row>
            <Form.Group className="pt-1">
              {this.state.assessmentState.symptoms
                .filter(x => {
                  return x.type === 'BoolSymptom';
                })
                .sort((a, b) => {
                  return a?.name?.localeCompare(b?.name);
                })
                .map(symp => this.boolSymptom(symp))}
              {this.noSymptom()}
              {this.state.assessmentState.symptoms
                .filter(x => {
                  return x.type === 'FloatSymptom';
                })
                .map(symp => this.floatSymptom(symp))}
            </Form.Group>
          </Form.Row>
          <Form.Row className="pt-4">
            <Button variant="primary" block size="lg" className="btn-block btn-square" disabled={this.state.loading} onClick={this.navigate}>
              {this.state.loading && (
                <React.Fragment>
                  <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
                </React.Fragment>
              )}
              {this.props.translations[this.props.lang]['web']['submit']}
            </Button>
          </Form.Row>
        </Card.Body>
      </Card>
    );
  }
}

SymptomsAssessment.propTypes = {
  assessment: PropTypes.object,
  symptoms: PropTypes.array,
  translations: PropTypes.object,
  patient_initials: PropTypes.string,
  patient_age: PropTypes.number,
  lang: PropTypes.string,
  submit: PropTypes.func,
  idPre: PropTypes.string,
};

export default SymptomsAssessment;
