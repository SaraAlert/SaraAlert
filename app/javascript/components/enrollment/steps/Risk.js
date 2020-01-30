import React from "react"
import { Card, Button, Form, Col } from 'react-bootstrap';

class Risk extends React.Component {

  constructor(props) {
    super(props);
    this.state = { ...this.props, current: {...this.props.currentState} };
    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === "checkbox" ? event.target.checked : event.target.value;
    let current = this.state.current;
    this.setState({current: {...current, [event.target.id]: value}}, () => {
      this.props.setEnrollmentState({ ...this.state.current });
    });
  }

  render () {
    return (
      <React.Fragment>
        <Card className="mx-4 card-square">
          <Card.Header as="h5">Subject Risk Factor Information</Card.Header>
          <Card.Body>

            {this.props.previous && <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>Previous</Button>}
            {this.props.next && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.next}>{!!this.props.lastIndex && "Back"}{!!!this.props.lastIndex && "Next"}</Button>}
            {this.props.submit && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.submit}>Finish</Button>}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

export default Risk