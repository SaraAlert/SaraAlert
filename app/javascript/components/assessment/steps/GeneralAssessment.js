import React from 'react';
import { Card, Button, Form } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import * as yup from 'yup';

class GeneralAssessment extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props, current: { ...this.props.currentState }, errors: {} };
    this.state.current.experiencing_symptoms =
      this.state.current.symptoms.filter(x => {
        return x.bool_value === true;
      }).length === 0
        ? 'No'
        : 'Yes';
    // If all values are null then form has not been populated with answers so experiencing symptoms should be null
    this.state.current.experiencing_symptoms =
      this.state.current.symptoms.filter(x => {
        return x.bool_value !== null;
      }).length === 0
        ? null
        : this.state.current.experiencing_symptoms;
    this.handleChange = this.handleChange.bind(this);
    this.navigate = this.navigate.bind(this);
    this.validate = this.validate.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let field_id = event.target.id.split('_idpre')[0];
    // experiencing_symptoms dropdown is not dynamically generated, need special case for it
    if (field_id === 'experiencing_symptoms') {
      if (value === 'No') {
        current.symptoms
          .filter(x => {
            return x.field_type === 'BoolSymptom';
          })
          .forEach(x => (x.bool_value = false));
        current.experiencing_symptoms = value;
      } else if (value === 'Yes') {
        current.experiencing_symptoms = value;
      }
    } else if (current.symptoms.find(x => x.name === field_id)?.field_type === 'BoolSymptom') {
      Object.values(current.symptoms).find(symp => symp.name === field_id).bool_value = value;
    } else if (current.symptoms.find(x => x.name === field_id)?.field_type === 'FloatSymptom') {
      Object.values(current.symptoms).find(symp => symp.name === field_id).float_value = value;
    } else if (current.symptoms.find(x => x.name === field_id)?.field_type === 'IntegerSymptom') {
      Object.values(current.symptoms).find(symp => symp.name === field_id).int_value = value;
    }

    this.setState({ current: { ...current } }, () => {
      this.props.setAssessmentState({ ...this.state.current });
    });
  }

  navigate() {
    if (this.state.current.experiencing_symptoms === 'Yes') {
      this.props.goto(1);
    } else {
      this.props.submit();
    }
  }

  validate(callback) {
    let self = this;
    schema
      .validate(
        this.state.current.symptoms.find(x => x.name === 'temperature'),
        { abortEarly: false }
      )
      .then(function() {
        // No validation issues? Invoke callback (move to next step)
        self.setState({ errors: {} }, () => {
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
          self.setState({ errors: issues });
        }
      });
  }

  render() {
    return (
      <React.Fragment>
        <Card className="mx-0 card-square align-item-center">
          <Card.Header className="text-center" as="h4">
            Daily Self-Report
          </Card.Header>
          <Card.Body>
            <Form.Row className="pt-3">
              <Form.Label className="nav-input-label">
                <div>What was your temperature today?</div>
                <i className="text-secondary h6">Enter temp in C° or F° - the system will handle the unit.</i>
              </Form.Label>
              <Form.Control
                isInvalid={this.state.errors['temperature']}
                size="lg"
                id={`temperature${this.props.idPre ? '_idpre' + this.props.idPre : ''}`}
                className="form-square"
                value={this.state.current.symptoms.find(x => x.name === 'temperature').float_value || ''}
                onChange={this.handleChange}
              />
              <Form.Control.Feedback className="d-block" type="invalid">
                {this.state.errors['float_value']}
              </Form.Control.Feedback>
            </Form.Row>
            <Form.Row className="pt-3">
              <Form.Label className="nav-input-label">
                Are you experiencing any of the following symptoms{' '}
                {this.state.current.symptoms
                  .filter(x => {
                    return x.field_type === 'BoolSymptom';
                  })
                  .map(a => a.label)
                  .join(', ')}
                ?
              </Form.Label>
              <Form.Control
                as="select"
                size="lg"
                className="form-square"
                id={`experiencing_symptoms${this.props.idPre ? '_idpre' + this.props.idPre : ''}`}
                value={this.state.current.experiencing_symptoms || 'Please Select'}
                onChange={this.handleChange}>
                <option disabled>Please Select</option>
                <option>Yes</option>
                <option>No</option>
              </Form.Control>
            </Form.Row>
            <Form.Row className="pt-5">
              <Button
                variant="primary"
                id="submit_button"
                block
                size="lg"
                className="btn-block btn-square"
                disabled={!(this.state.current.experiencing_symptoms && this.state.current.symptoms.find(x => x.name === 'temperature')?.float_value)}
                onClick={() => this.validate(this.navigate)}>
                {(this.state.current.experiencing_symptoms === 'Yes' && 'Continue') || (this.state.current.experiencing_symptoms !== 'Yes' && 'Submit')}
              </Button>
            </Form.Row>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

const schema = yup.object().shape({
  float_value: yup
    .number()
    .typeError('Please enter a valid number.')
    .test('is-in-bounds', 'Temperature Out of Bounds [27 - 49C] [80 - 120F]', value => (value >= 27 && value <= 49) || (value >= 80 && value <= 120))
    .required(),
});

GeneralAssessment.propTypes = {
  currentState: PropTypes.object,
  setAssessmentState: PropTypes.func,
  goto: PropTypes.func,
  submit: PropTypes.func,
  idPre: PropTypes.string,
};

export default GeneralAssessment;
