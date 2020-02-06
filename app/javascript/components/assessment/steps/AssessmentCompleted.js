import React from "react"
import { Card, Form } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class AssessmentCompleted extends React.Component {

  constructor(props) {
    super(props);
    this.state = { ...this.props, ...this.props.currentState };
    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === "checkbox" ? event.target.checked : event.target.value;
    this.setState({[event.target.id]: value}, () => {
      this.props.setAssessmentState({ ...this.state });
    });
  }

  render () {
    return (
     <React.Fragment>
        <Card className="mx-0 card-square align-item-center">
          <Card.Header className="text-center" as="h4">Daily Self-Assessment</Card.Header>
          <Card.Body className="text-center">
                <Form.Label className="text-center pt-1">Thank You For Completing Your Self Assesement</Form.Label><br />
                <Form.Label className="fas fa-thumbs-up fa-10x text-center pt-2"> </Form.Label>
         </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

AssessmentCompleted.propTypes = {
  currentState: PropTypes.object,
  setAssessmentState: PropTypes.func
};

export default AssessmentCompleted