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
      reportState: { symptoms: _.cloneDeep(this.props.symptoms) },
      loading: false,
      noSymptomsCheckbox: false,
      // ensure this is updated when editing a report
      selectedBoolSymptomCount: this.props.symptoms.filter(x => {
        return x.type === 'BoolSymptom' && x.value;
      }).length,
    };
  }

  handleChange = (event, value) => {
    let report = this.state.reportState;
    let field_id = event.target.id.split('_idpre')[0];
    Object.values(report.symptoms).find(symp => symp.name === field_id).value = value;
    this.setState({ reportState: report });
    this.updateBoolSymptomCount();
  };

  handleBoolChange = event => {
    let value = event.target.checked;
    this.handleChange(event, value);
  };

  handleFloatChange = event => {
    if (
      event?.target?.value === '' ||
      event?.target?.value === '.' ||
      (event?.target?.value && !isNaN(event.target.value) && !isNaN(parseFloat(event.target.value)))
    ) {
      // To prevent the user from just submitting a period character
      if (event.target.value === '.') {
        event.target.value = '0.';
      }
      this.handleChange(event, event.target.value);
    }
  };

  handleNoSymptomChange = event => {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    this.setState({ noSymptomsCheckbox: value }, () => {
      // Make sure pre-selected options are cleared
      if (this.state.noSymptomsCheckbox) {
        let report = { ...this.state.reportState };
        for (const symptom in report?.symptoms) {
          if (report?.symptoms[parseInt(symptom)]?.type == 'BoolSymptom') {
            report.symptoms[parseInt(symptom)].value = false;
          }
        }
        this.setState({ reportState: report });
      }
    });
  };

  updateBoolSymptomCount = () => {
    let trueBoolSymptoms = this.state.reportState.symptoms.filter(s => {
      return s.type === 'BoolSymptom' && s.value;
    });
    this.setState({ selectedBoolSymptomCount: trueBoolSymptoms.length });
  };

  hasChanges = () => {
    return !_.isEqual(this.state.reportState.symptoms, this.props.symptoms);
  };

  fieldIsEmptyOrNew = object => {
    const keysToIgnore = ['who_reported'];
    let allFieldsEmpty = true;
    _.map(object, (value, key) => {
      if (object[String(key)] !== null && object[String(key)] !== undefined && !keysToIgnore.includes(key)) {
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
    const reportState = this.formatedReportState();
    if (this.fieldIsEmptyOrNew(this.props.assessment)) {
      this.props.submit(reportState);
    } else {
      if (this.hasChanges()) {
        if (await confirmDialog("Are you sure you'd like to modify this report?")) {
          this.props.submit(reportState);
        } else {
          this.setState({ loading: false });
        }
      } else {
        this.props.submit(reportState);
      }
    }
  };

  // Converts all FloatSymptoms to be floating point values
  // Specifically needed for the case of input "0." so an error doesn't occurr on submission
  formatedReportState = () => {
    let reportState = this.state.reportState;
    for (const key in this.state.reportState['symptoms']) {
      if (parseInt(key) && reportState['symptoms'][parseInt(key)].type == 'FloatSymptom' && !isNaN(parseFloat(reportState['symptoms'][parseInt(key)].value))) {
        reportState['symptoms'][parseInt(key)].value = parseFloat(reportState['symptoms'][parseInt(key)].value);
      }
    }
    return reportState;
  };

  noSymptom = () => {
    let noSymptomsChecked = this.state.noSymptomsCheckbox;
    let boolSymptomsSelected = this.state.selectedBoolSymptomCount > 0 ? true : false;

    return (
      <Form.Check
        type="checkbox"
        id="no-symptoms-check"
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
        onChange={this.handleBoolChange}></Form.Check>
    );
  };

  floatSymptom = symp => {
    const key = `key_${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`;
    const id = `${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`;
    return (
      <Form.Row className="pt-3" key={key}>
        <Form.Label className="nav-input-label" key={key + '_label'} htmlFor={id}>
          <b>{this.props.translations[this.props.lang]['symptoms'][symp.name]['name']}</b>{' '}
          {this.props.translations[this.props.lang]['symptoms'][symp.name]['notes']
            ? ' ' + this.props.translations[this.props.lang]['symptoms'][symp.name]['notes']
            : ''}
        </Form.Label>
        <Form.Control size="lg" id={id} key={key + '_control'} className="form-square" value={symp.value || ''} maxlength="35" onChange={this.handleFloatChange} />
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
              {this.state.reportState.symptoms
                .filter(x => {
                  return x.type === 'BoolSymptom';
                })
                .sort((a, b) => {
                  return a?.name?.localeCompare(b?.name);
                })
                .map(symp => this.boolSymptom(symp))}
              {this.noSymptom()}
              {this.state.reportState.symptoms
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
              {/* The following <span> tags cannot be removed. They prevent Google Translate from confusing the react node-tree when translated */}
              <span>{this.props.translations[this.props.lang]['web']['submit']}</span>
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
