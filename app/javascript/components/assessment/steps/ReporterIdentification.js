import React from 'react';
import { Card, Button, Form } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class ReporterIdentification extends React.Component {
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
        <Card className="mx-0 card-square">
          <Card.Header as="h4">Daily Self-Report</Card.Header>
          <Card.Body>
            <Form>
              <Form.Label className="nav-input-label">Are You Reporting For Yourself Or Somebody Else?</Form.Label>
            </Form>
            <Form.Row className="pt-3">
              <Button variant="primary" block size="lg" className="float-center" onClick={() => {}}>
                Report For Myself
              </Button>
            </Form.Row>
            <Form.Row className="pt-3">
              <Button variant="primary" block size="lg" className="float-center" onClick={() => {}}>
                Report For Somebody Else
              </Button>
            </Form.Row>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

ReporterIdentification.propTypes = {
  currentState: PropTypes.object,
  setAssessmentState: PropTypes.func,
};

export default ReporterIdentification;
