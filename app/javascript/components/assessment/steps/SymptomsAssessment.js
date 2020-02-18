import React from 'react';
import { Card, Button, Form } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class SymptomsAssessment extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props, current: { ...this.props.currentState } };
    this.handleChange = this.handleChange.bind(this);
    this.navigate = this.navigate.bind(this);
    this.anySelectedSymptoms = this.anySelectedSymptoms.bind(this);
  }

  anySelectedSymptoms() {
    return (
      this.state.current.cough ||
      this.state.current.sore_throat ||
      this.state.current.difficulty_breathing ||
      this.state.current.headaches ||
      this.state.current.muscle_aches ||
      this.state.current.abdominal_discomfort ||
      this.state.current.vomiting ||
      this.state.current.diarrhea
    );
  }

  handleChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    this.setState({ current: { ...current, [event.target.id.split('_idpre')[0]]: value } }, () => {
      this.props.setAssessmentState({ ...this.state.current });
    });
  }

  navigate() {
    if (!this.anySelectedSymptoms()) {
      this.props.goto(0);
    } else {
      this.props.submit();
    }
  }

  render() {
    return (
      <React.Fragment>
        <Card className="mx-0 card-square">
          <Card.Header as="h4">Daily Self-Assessment</Card.Header>
          <Card.Body>
            <Form.Row>
              <Form.Label className="nav-input-label">
                You previously indicated that you are experiencing symptoms. Please select all symptoms which you are experiencing.
              </Form.Label>{' '}
              <br />
            </Form.Row>
            <Form.Row>
              <Form.Group className="pt-1">
                <Form.Check
                  type="switch"
                  id={`cough${this.props.idPre ? '_idpre' + this.props.idPre : ''}`}
                  label="Cough"
                  checked={this.state.current.cough === true || false}
                  onChange={this.handleChange}
                />
                <Form.Check
                  type="switch"
                  className="pt-2"
                  id={`difficulty_breathing${this.props.idPre ? '_idpre' + this.props.idPre : ''}`}
                  label="Difficulty Breathing"
                  checked={this.state.current.difficulty_breathing === true || false}
                  onChange={this.handleChange}
                />
              </Form.Group>
            </Form.Row>
            <Form.Row className="pt-4">
              <Button variant="primary" block size="lg" className="btn-block btn-square" onClick={this.navigate}>
                {((this.state.current.cough ||
                  this.state.current.sore_throat ||
                  this.state.current.difficulty_breathing ||
                  this.state.current.headaches ||
                  this.state.current.muscle_aches ||
                  this.state.current.abdominal_discomfort ||
                  this.state.current.vomiting ||
                  this.state.current.diarrhea) &&
                  'Submit') ||
                  (!(
                    this.state.current.cough ||
                    this.state.current.sore_throat ||
                    this.state.current.difficulty_breathing ||
                    this.state.current.headaches ||
                    this.state.current.muscle_aches ||
                    this.state.current.abdominal_discomfort ||
                    this.state.current.vomiting ||
                    this.state.current.diarrhea
                  ) &&
                    'Previous')}
              </Button>
            </Form.Row>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

SymptomsAssessment.propTypes = {
  currentState: PropTypes.object,
  setAssessmentState: PropTypes.func,
  goto: PropTypes.func,
  submit: PropTypes.func,
  idPre: PropTypes.string,
};

export default SymptomsAssessment;
