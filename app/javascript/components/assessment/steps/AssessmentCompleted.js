import React from 'react';
import { Card, Form } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class AssessmentCompleted extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props, ...this.props.currentState };
    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    this.setState({ [event.target.id]: value }, () => {
      this.props.setAssessmentState({ ...this.state });
    });
  }

  render() {
    return (
      <React.Fragment>
        <Card className="mx-0 card-square align-item-center">
          <Card.Header className="text-center" as="h4">
            Daily Self-Report
          </Card.Header>
          <Card.Body className="text-center">
            <Form.Label className="text-center pt-1">
              <b>Thank you for your submission!</b>
            </Form.Label>
            <br />
            <Form.Label className="text-left pt-1">
              <br />• If you did not report any symptoms, please continue to follow the recommendations provided by your local health department.
              <br />
              <br />• If you reported any symptoms, your local health department will be reaching out soon. If you have any immediate concerns, please call your
              medical provider or local health department. Avoid close contact with other people and stay at home.
              <br />
              <br />• If you are experiencing a medical emergency, please call 911 and let them know you are being monitored by the health department.
            </Form.Label>
            <br />
            <Form.Label className="fas fa-check fa-10x text-center pt-2"> </Form.Label>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

AssessmentCompleted.propTypes = {
  currentState: PropTypes.object,
  setAssessmentState: PropTypes.func,
};

export default AssessmentCompleted;
