import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Button, Form } from 'react-bootstrap';
import _ from 'lodash';
import confirmDialog from '../../../util/ConfirmDialog';

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

  handleIntChange = event => {
    const validInputs = ['', '-'];
    const value = event?.target?.value;
    // Ensure (1) the value is defined or an empty string && meets the condintions of (2) or (3)
    //        (2.a) the value is a number & the user is prevented from inputting non-numerical characters after inputting a number (ex. '43test')
    //        (2.b) the value can be parsed as an integer
    //        (2.c) the user is prevented from inputting '.' characters (since parseInt() would allow that as an input)
    //        (3) if the value is not a valid number, check if it is an acceptable character input
    if (
      (value || value === '') &&
      ((!isNaN(event.target.value) && !isNaN(parseInt(event.target.value)) && !event?.target?.value.includes('.')) || validInputs.includes(value))
    ) {
      this.handleChange(event, event.target.value);
    }
  };

  handleFloatChange = event => {
    const validInputs = ['', '.', '-', '-.'];
    const value = event?.target?.value;
    // Ensure (1) the value is defined or an empty string && meets the condintions of (2) or (3)
    //        (2.a) the value is a number & the user is prevented from inputting non-numerical characters after inputting a number (ex. '4.3test')
    //        (2.b) the value can be parsed as an float
    //        (3) if the value is not a valid number, check if it is an acceptable character input
    if ((value || value === '') && ((!isNaN(event.target.value) && !isNaN(parseFloat(event.target.value))) || validInputs.includes(value))) {
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
    const reportState = this.formattedReportState();
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

  // Converts all FloatSymptoms and IntegerSymptoms to numerical values and nulls out any non-numerical values provided (such as '-', '.', and '-.')
  formattedReportState = () => {
    let reportState = this.state.reportState;
    for (const key in this.state.reportState['symptoms']) {
      if (parseInt(key)) {
        let symptom = reportState['symptoms'][parseInt(key)];
        if (symptom.type === 'FloatSymptom' && !isNaN(parseFloat(symptom.value))) {
          symptom.value = parseFloat(symptom.value);
        } else if (symptom.type === 'IntegerSymptom' && !isNaN(parseInt(symptom.value))) {
          symptom.value = parseInt(symptom.value);
        } else if (symptom.type === 'IntegerSymptom' || symptom.type === 'FloatSymptom') {
          symptom.value = null;
        }
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
            <b>{this.props.translations[this.props.lang]['symptoms'][symp.name]?.name || symp.name}</b>{' '}
            {this.props.translations[this.props.lang]['symptoms'][symp.name]?.notes
              ? ' ' + this.props.translations[this.props.lang]['symptoms'][symp.name]?.notes
              : ''}
          </div>
        }
        className="pb-2"
        onChange={this.handleBoolChange}></Form.Check>
    );
  };

  integerSymptom = symp => {
    const key = `key_${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`;
    const id = `${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`;
    return (
      <Form.Control size="lg" id={id} key={key + '_control'} className="form-square" value={symp.value || ''} maxLength="9" onChange={this.handleIntChange} />
    );
  };

  floatSymptom = symp => {
    const key = `key_${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`;
    const id = `${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`;
    return (
      <Form.Control
        size="lg"
        id={id}
        key={key + '_control'}
        className="form-square"
        value={symp.value || ''}
        maxLength="35"
        onChange={this.handleFloatChange}
      />
    );
  };

  intOrFloatSymptom = symp => {
    const key = `key_${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`;
    const id = `${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`;
    return (
      <Form.Row className="pt-3" key={key}>
        <Form.Label className="input-label" key={key + '_label'} htmlFor={id}>
          <b>{this.props.translations[this.props.lang]['symptoms'][symp.name]?.name || symp.name}</b>{' '}
          {this.props.translations[this.props.lang]['symptoms'][symp.name]?.notes
            ? ' ' + this.props.translations[this.props.lang]['symptoms'][symp.name]?.notes
            : ''}
        </Form.Label>
        {symp.type === 'IntegerSymptom' && this.integerSymptom(symp)}
        {symp.type === 'FloatSymptom' && this.floatSymptom(symp)}
      </Form.Row>
    );
  };

  render() {
    return (
      <Card className="mx-0 card-square">
        <Card.Header className="h4">
          {this.props.translations[this.props.lang]['html']['weblink']['title']}{' '}
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
            <Form.Label className="input-label pb-3">{this.props.translations[this.props.lang]['html']['weblink']['bool-title']}</Form.Label>
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
                  return x.type === 'IntegerSymptom';
                })
                .map(symp => this.intOrFloatSymptom(symp))}
              {this.state.reportState.symptoms
                .filter(x => {
                  return x.type === 'FloatSymptom';
                })
                .map(symp => this.intOrFloatSymptom(symp))}
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
              <span>{this.props.translations[this.props.lang]['html']['weblink']['submit']}</span>
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
