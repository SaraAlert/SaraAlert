import React from "react"
import { Card, Button, Form, Col, InputGroup } from 'react-bootstrap';

class Identification extends React.Component {

  constructor(props) {
    super(props);
    this.state = { ...this.props };
    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(event) {
    debugger
    let value = event.target.type === "checkbox" ? event.target.checked : event.target.value;
    this.setState({[event.target.id]: value}, () => {
      this.props.setEnrollmentState({ ...this.state });
    });
  }

  render () {
    return (
      <React.Fragment>
        <Card className="mx-5 card-square">
          <Card.Header as="h4">Patient Identification</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row className="pt-2">
                <Form.Group as={Col} controlId="first_name">
                  <Form.Label className="nav-input-label">FIRST NAME</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.first_name || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} controlId="middle_name">
                  <Form.Label className="nav-input-label">MIDDLE NAME(S)</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.middle_name || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} controlId="last_name">
                  <Form.Label className="nav-input-label">LAST NAME</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.last_name || ''} onChange={this.handleChange} />
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="12">
                  <Form.Label className="nav-input-label">DATE OF BIRTH</Form.Label>
                  <Form.Row>
                    <Form.Group as={Col}><Form.Control placeholder="day" size="lg" className="form-square" id="dob_day" value={this.state.dob_day || ''} onChange={this.handleChange} /></Form.Group>
                    <Form.Group as={Col}><Form.Control placeholder="month" size="lg" className="form-square" id="dob_month" value={this.state.dob_month || ''} onChange={this.handleChange} /></Form.Group>
                    <Form.Group as={Col}><Form.Control placeholder="year" size="lg" className="form-square" id="dob_year" value={this.state.dob_year || ''} onChange={this.handleChange} /></Form.Group>
                  </Form.Row>
                </Form.Group>
                <Form.Group as={Col} md="1"></Form.Group>
                <Form.Group as={Col} controlId="age" md="4">
                  <Form.Label className="nav-input-label">AGE</Form.Label>
                  <Form.Control placeholder="" size="lg" className="form-square" value={this.state.age || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="1"></Form.Group>
                <Form.Group as={Col} controlId="sex" md="6">
                  <Form.Label className="nav-input-label">SEX</Form.Label>
                  <Form.Control as="select" size="lg" className="form-square" value={this.state.sex || 'Female'} onChange={this.handleChange}>
                    <option>Female</option>
                    <option>Male</option>
                    <option>Unknown</option>
                  </Form.Control>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="13">
                  <Form.Label className="nav-input-label">RACE</Form.Label>
                  <Form.Check type="switch" id="white" label="White" checked={this.state.white === true || false} onChange={this.handleChange} />
                  <Form.Check type="switch" id="black_or_african_american" label="Black or African American" checked={this.state.black_or_african_american === true || false} onChange={this.handleChange} />
                  <Form.Check type="switch" id="american_indian_or_alaska_native" label="American Indian or Alaska Native" checked={this.state.american_indian_or_alaska_native === true || false} onChange={this.handleChange} />
                  <Form.Check type="switch" id="asian" label="Asian" checked={this.state.asian === true || false} onChange={this.handleChange} />
                  <Form.Check type="switch" id="native_hawaiian_or_other_pacific_islander" label="Native Hawaiian or Other Pacific Islander" checked={this.state.native_hawaiian_or_other_pacific_islander === true || false} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="11" controlId="ethnicity">
                  <Form.Label className="nav-input-label">ETHNICITY</Form.Label>
                  <Form.Control as="select" size="lg" className="form-square" value={this.state.ethnicity || 'Not Hispanic or Latino'} onChange={this.handleChange}>
                    <option>Not Hispanic or Latino</option>
                    <option>Hispanic or Latino</option>
                  </Form.Control>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="8" controlId="primary_language">
                  <Form.Label className="nav-input-label">PRIMARY LANGUAGE</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.primary_language || ''} onChange={this.handleChange}  />
                </Form.Group>
                <Form.Group as={Col} md="1"></Form.Group>
                <Form.Group as={Col} md="8" controlId="secondary_language">
                  <Form.Label className="nav-input-label">SECONDARY LANGUAGE</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.secondary_language || ''} onChange={this.handleChange} />
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-1">
                <Form.Group as={Col}>
                  <Form.Check type="switch" id="interpretation_required" label="INTERPRETATION REQUIRED" checked={this.state.interpretation_required || false} onChange={this.handleChange} />
                </Form.Group>
              </Form.Row>
            </Form>
            {this.props.previous && <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>Previous</Button>}
            {this.props.next && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.next}>Next</Button>}
            {this.props.finish && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.finish}>Finish</Button>}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

export default Identification