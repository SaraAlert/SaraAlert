import React from 'react';
import { Card, Button, Form, Col } from 'react-bootstrap';
import moment from 'moment';
import { PropTypes } from 'prop-types';
import * as yup from 'yup';

class Identification extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props, current: { ...this.props.currentState } };
    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let self = this;
    event.persist();
    this.setState({ current: { ...current, [event.target.id]: value } }, () => {
      self.props.setEnrollmentState({ ...this.state.current });
      let current = this.state.current;
      if (event.target.id === 'date_of_birth' && self.state.current.date_of_birth) {
        self.setState({ current: { ...current, age: 0 - moment(self.state.current.date_of_birth).diff(moment.now(), 'years') } });
      }
    });
  }

  validate() {}

  render() {
    return (
      <React.Fragment>
        <Card className="mx-2 card-square">
          <Card.Header as="h5">Subject Identification</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row className="pt-2">
                <Form.Group as={Col} controlId="first_name">
                  <Form.Label className="nav-input-label">FIRST NAME</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.first_name || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} controlId="middle_name">
                  <Form.Label className="nav-input-label">MIDDLE NAME(S)</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.middle_name || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} controlId="last_name">
                  <Form.Label className="nav-input-label">LAST NAME</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.last_name || ''} onChange={this.handleChange} />
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="auto" controlId="date_of_birth">
                  <Form.Label className="nav-input-label">DATE OF BIRTH</Form.Label>
                  <Form.Control size="lg" type="date" className="form-square" value={this.state.current.date_of_birth || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="1"></Form.Group>
                <Form.Group as={Col} controlId="age" md="auto">
                  <Form.Label className="nav-input-label">AGE</Form.Label>
                  <Form.Control placeholder="" size="lg" className="form-square" value={this.state.current.age || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="1"></Form.Group>
                <Form.Group as={Col} controlId="sex" md="auto">
                  <Form.Label className="nav-input-label">SEX</Form.Label>
                  <Form.Control as="select" size="lg" className="form-square" value={this.state.current.sex || ''} onChange={this.handleChange}>
                    <option></option>
                    <option>Female</option>
                    <option>Male</option>
                    <option>Unknown</option>
                  </Form.Control>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-1">
                <Form.Group as={Col} md="auto">
                  <Form.Label className="nav-input-label">RACE</Form.Label>
                  <Form.Check type="switch" id="white" label="WHITE" checked={this.state.current.white === true || false} onChange={this.handleChange} />
                  <Form.Check
                    className="pt-2"
                    type="switch"
                    id="black_or_african_american"
                    label="BLACK OR AFRICAN AMERICAN"
                    checked={this.state.current.black_or_african_american === true || false}
                    onChange={this.handleChange}
                  />
                  <Form.Check
                    className="pt-2"
                    type="switch"
                    id="american_indian_or_alaska_native"
                    label="AMERICAN INDIAN OR ALASKA NATIVE"
                    checked={this.state.current.american_indian_or_alaska_native === true || false}
                    onChange={this.handleChange}
                  />
                  <Form.Check
                    className="pt-2"
                    type="switch"
                    id="asian"
                    label="ASIAN"
                    checked={this.state.current.asian === true || false}
                    onChange={this.handleChange}
                  />
                  <Form.Check
                    className="pt-2"
                    type="switch"
                    id="native_hawaiian_or_other_pacific_islander"
                    label="NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER"
                    checked={this.state.current.native_hawaiian_or_other_pacific_islander === true || false}
                    onChange={this.handleChange}
                  />
                </Form.Group>
                <Form.Group as={Col} md="1"></Form.Group>
                <Form.Group as={Col} md="8" controlId="ethnicity">
                  <Form.Label className="nav-input-label">ETHNICITY</Form.Label>
                  <Form.Control as="select" size="lg" className="form-square" value={this.state.current.ethnicity || ''} onChange={this.handleChange}>
                    <option></option>
                    <option>Not Hispanic or Latino</option>
                    <option>Hispanic or Latino</option>
                  </Form.Control>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} controlId="primary_language">
                  <Form.Label className="nav-input-label">PRIMARY LANGUAGE</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.primary_language || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="1"></Form.Group>
                <Form.Group as={Col} controlId="secondary_language">
                  <Form.Label className="nav-input-label">SECONDARY LANGUAGE</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.secondary_language || ''} onChange={this.handleChange} />
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-1">
                <Form.Group as={Col}>
                  <Form.Check
                    type="switch"
                    id="interpretation_required"
                    label="INTERPRETATION REQUIRED"
                    checked={this.state.current.interpretation_required || false}
                    onChange={this.handleChange}
                  />
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

Identification.propTypes = {
  currentState: PropTypes.object,
  previous: PropTypes.func,
  next: PropTypes.func,
  submit: PropTypes.func,
};

export default Identification;
