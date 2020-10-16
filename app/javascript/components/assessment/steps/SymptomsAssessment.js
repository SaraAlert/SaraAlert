import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Button, Form } from 'react-bootstrap';

class SymptomsAssessment extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      current: { ...this.props.currentState },
      loading: false,
      noSymptomsCheckbox: false,
      selectedBoolSymptomCount: 0,
    };
    this.handleChange = this.handleChange.bind(this);
    this.handleNoSymptomChange = this.handleNoSymptomChange.bind(this);
    this.updateBoolSymptomCount = this.updateBoolSymptomCount.bind(this);
    this.navigate = this.navigate.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let field_id = event.target.id.split('_idpre')[0];
    Object.values(current.symptoms).find(symp => symp.name === field_id).value = value;
    this.setState({ current: { ...current } }, () => {
      this.props.setAssessmentState({ ...this.state.current });
    });
    this.updateBoolSymptomCount();
  }

  handleNoSymptomChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    this.setState({ noSymptomsCheckbox: value }, () => {
      // Make sure pre-selected options are cleared
      if (this.state.noSymptomsCheckbox) {
        let current = { ...this.state.current };
        for (const symptom in current?.symptoms) {
          if (current?.symptoms[parseInt(symptom)]?.type == 'BoolSymptom') {
            current.symptoms[parseInt(symptom)].value = false;
          }
        }
        this.setState({ current: current });
      }
    });
  }

  updateBoolSymptomCount() {
    let trueBoolSymptoms = this.state.current.symptoms.filter(s => {
      return s.type === 'BoolSymptom' && s.value;
    });
    this.setState({ selectedBoolSymptomCount: trueBoolSymptoms.length });
  }

  navigate() {
    this.setState({ loading: true }, () => {
      this.props.submit();
    });
  }

  noSymptom() {
    let noSymptomsChecked = this.state.noSymptomsCheckbox;
    let boolSymptomsSelected = this.state.selectedBoolSymptomCount > 0 ? true : false;

    return (
      <Form.Check
        type="checkbox"
        checked={noSymptomsChecked}
        disabled={boolSymptomsSelected}
        label={
          <div>
            <b>{this.props.translations[this.props.lang]['symptoms']['no-symptoms']}</b>
          </div>
        }
        className="pb-2"
        onChange={this.handleNoSymptomChange}></Form.Check>
    );
  }

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
    return (
      <Form.Row className="pt-3" key={`label_key_${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`}>
        <Form.Label className="nav-input-label" key={`label_key_${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`}>
          <b>{this.props.translations[this.props.lang]['symptoms'][symp.name]['name']}</b>{' '}
          {this.props.translations[this.props.lang]['symptoms'][symp.name]['notes']
            ? ' ' + this.props.translations[this.props.lang]['symptoms'][symp.name]['notes']
            : ''}
        </Form.Label>
        <Form.Control
          size="lg"
          id={`${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`}
          key={`key_${symp.name}${this.props.idPre ? '_idpre' + this.props.idPre : ''}`}
          className="form-square"
          value={symp.value || ''}
          type="number"
          onChange={this.handleChange}
        />
      </Form.Row>
    );
  };

  render() {
    return (
      <React.Fragment>
        <Card className="mx-0 card-square">
          <Card.Header as="h4">
            {this.props.translations[this.props.lang]['web']['title']}&nbsp;
            {this.props.patientInitials && this.props.patientAge !== null && (
              <span>
                ({this.props.patientInitials}-{this.props.patientAge})
              </span>
            )}
            {this.props.patientInitials && this.props.patientAge === null && <span>({this.props.patientInitials})</span>}
            {!this.props.patientInitials && this.props.patientAge !== null && <span>({this.props.patientAge})</span>}
          </Card.Header>
          <Card.Body>
            <Form.Row>
              <Form.Label className="nav-input-label pb-3">{this.props.translations[this.props.lang]['web']['bool-title']}</Form.Label>
            </Form.Row>
            <Form.Row>
              <Form.Group className="pt-1">
                {this.state.current.symptoms
                  .filter(x => {
                    return x.type === 'BoolSymptom';
                  })
                  .sort((a, b) => {
                    return a?.name?.localeCompare(b?.name);
                  })
                  .map(symp => this.boolSymptom(symp))}
                {this.noSymptom()}
                {this.state.current.symptoms
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
      </React.Fragment>
    );
  }
}

SymptomsAssessment.propTypes = {
  translations: PropTypes.object,
  patientInitials: PropTypes.string,
  patientAge: PropTypes.number,
  lang: PropTypes.string,
  currentState: PropTypes.object,
  setAssessmentState: PropTypes.func,
  goto: PropTypes.func,
  submit: PropTypes.func,
  idPre: PropTypes.string,
};

export default SymptomsAssessment;
