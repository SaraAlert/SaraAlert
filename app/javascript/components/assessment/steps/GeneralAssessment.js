import React from 'react';
import { Card, Button, Form } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class GeneralAssessment extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props, current: { ...this.props.currentState } };
    this.handleChange = this.handleChange.bind(this);
    this.navigate = this.navigate.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    this.setState({ current: { ...current, [event.target.id]: value } }, () => {
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

  render() {
    return (
      <React.Fragment>
        <Card className="mx-0 card-square align-item-center">
          <Card.Header className="text-center" as="h4">
            Daily Self-Assessment
          </Card.Header>
          <Card.Body>
            <Form.Row className="pt-3">
              <Form.Label className="nav-input-label">What was your temperature today (°F)?</Form.Label>
              <Form.Control size="lg" id="temperature" className="form-square" value={this.state.current.temperature || ''} onChange={this.handleChange} />
            </Form.Row>
            <Form.Row className="pt-3">
              <Form.Label className="nav-input-label">Are you experiencing any symptoms including cough or difficulty breathing?</Form.Label>
              <Form.Control
                as="select"
                size="lg"
                className="form-square"
                id="experiencing_symptoms"
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
                disabled={!(this.state.current.experiencing_symptoms && this.state.current.temperature)}
                onClick={this.navigate}>
                {(this.state.current.experiencing_symptoms === 'Yes' && 'Continue') || (this.state.current.experiencing_symptoms !== 'Yes' && 'Submit')}
              </Button>
            </Form.Row>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

GeneralAssessment.propTypes = {
  currentState: PropTypes.object,
  setAssessmentState: PropTypes.func,
  goto: PropTypes.func,
  submit: PropTypes.func,
};

export default GeneralAssessment;
