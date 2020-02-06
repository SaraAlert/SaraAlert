import React from 'react';
import { Card, Button, Form, Col } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class Contact extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props, current: { ...this.props.currentState } };
    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    this.setState({ current: { ...current, [event.target.id]: value } }, () => {
      this.props.setEnrollmentState({ ...this.state.current });
    });
  }

  render() {
    return (
      <React.Fragment>
        <Card className="mx-2 card-square">
          <Card.Header as="h5">Subject Contact Information</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="11" controlId="primary_telephone">
                  <Form.Label className="nav-input-label">PRIMARY TELEPHONE NUMBER</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.primary_telephone || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="2"></Form.Group>
                <Form.Group as={Col} md="11" controlId="secondary_telephone">
                  <Form.Label className="nav-input-label">SECONDARY TELEPHONE NUMBER</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.secondary_telephone || ''} onChange={this.handleChange} />
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="11" controlId="primary_telephone_type">
                  <Form.Label className="nav-input-label">PRIMARY PHONE TYPE</Form.Label>
                  <Form.Control
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.primary_telephone_type || ''}
                    onChange={this.handleChange}>
                    <option></option>
                    <option>Smartphone</option>
                    <option>Plain Cell</option>
                    <option>Landline</option>
                  </Form.Control>
                </Form.Group>
                <Form.Group as={Col} md="2"></Form.Group>
                <Form.Group as={Col} md="11" controlId="secondary_telephone_type">
                  <Form.Label className="nav-input-label">SECONDARY PHONE TYPE</Form.Label>
                  <Form.Control
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.secondary_telephone_type || ''}
                    onChange={this.handleChange}>
                    <option></option>
                    <option>Smartphone</option>
                    <option>Plain Cell</option>
                    <option>Landline</option>
                  </Form.Control>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="auto">
                  Smartphone
                  <br />
                  Plain Cell
                  <br />
                  Landline
                </Form.Group>
                <Form.Group as={Col} md="auto">
                  <span className="font-weight-light">Phone capable of accessing web-based assessment tool</span>
                  <br />
                  <span className="font-weight-light">Phone capable of SMS messaging</span>
                  <br />
                  <span className="font-weight-light">Has telephone but cannot use SMS or web-based assessment tool</span>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-3">
                <Form.Group as={Col} md="8" controlId="email">
                  <Form.Label className="nav-input-label">E-MAIL ADDRESS</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.email || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="8" controlId="confirm_email">
                  <Form.Label className="nav-input-label">CONFIRM E-MAIL ADDRESS</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.confirm_email || ''} onChange={this.handleChange} />
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-3 pb-3">
                <Form.Group as={Col} md="8" controlId="preferred_contact_method">
                  <Form.Label className="nav-input-label">PREFERRED CONTACT METHOD</Form.Label>
                  <Form.Control
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.preferred_contact_method || ''}
                    onChange={this.handleChange}>
                    <option></option>
                    <option>E-mail</option>
                    <option>Telephone call</option>
                    <option>SMS Text-message</option>
                  </Form.Control>
                </Form.Group>
              </Form.Row>
            </Form>
            {this.props.previous && (
              <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>
                Previous
              </Button>
            )}
            {this.props.next && (
              <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.next}>
                Next
              </Button>
            )}
            {this.props.submit && (
              <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.submit}>
                Finish
              </Button>
            )}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

Contact.propTypes = {
  currentState: PropTypes.object,
  previous: PropTypes.func,
  setEnrollmentState: PropTypes.func,
  next: PropTypes.func,
  submit: PropTypes.func,
};

export default Contact;
