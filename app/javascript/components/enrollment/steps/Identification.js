import React from "react"
import { Card, Button, Form, Col } from 'react-bootstrap';
import moment from 'moment';

class Identification extends React.Component {

  constructor(props) {
    super(props);
    this.state = { ...this.props, current: {...this.props.currentState} };
    this.handleChange = this.handleChange.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === "checkbox" ? event.target.checked : event.target.value;
    let current = this.state.current;
    let self = this;
    event.persist();
    this.setState({current: {...current, [event.target.id]: value}}, () => {
      self.props.setEnrollmentState({ ...this.state.current });
      let current = this.state.current;
      if ((event.target.id === "dob_day" || event.target.id === "dob_month" || event.target.id === "dob_year") &&
          (self.state.current.dob_day && self.state.current.dob_month && self.state.current.dob_year && self.state.current.dob_year.length === 4)) {
        self.setState({current: {...current, age: 0 - moment(`${self.state.current.dob_year}-${self.state.current.dob_month.padStart(2, 0)}-${self.state.current.dob_day.padStart(2, '0')}`).diff(moment.now(), 'years')}});
      }
    });
  }

  render () {
    return (
      <React.Fragment>
        <Card className="mx-4 card-square">
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
                <Form.Group as={Col} md="12">
                  <Form.Label className="nav-input-label">DATE OF BIRTH</Form.Label>
                  <Form.Row>
                    <Form.Group as={Col}><Form.Control placeholder="month" size="lg" className="form-square" id="dob_month" value={this.state.current.dob_month || ''} onChange={this.handleChange} /></Form.Group>
                    <Form.Group as={Col}><Form.Control placeholder="day" size="lg" className="form-square" id="dob_day" value={this.state.current.dob_day || ''} onChange={this.handleChange} /></Form.Group>
                    <Form.Group as={Col}><Form.Control placeholder="year" size="lg" className="form-square" id="dob_year" value={this.state.current.dob_year || ''} onChange={this.handleChange} /></Form.Group>
                  </Form.Row>
                </Form.Group>
                <Form.Group as={Col} md="1"></Form.Group>
                <Form.Group as={Col} controlId="age" md="4">
                  <Form.Label className="nav-input-label">AGE</Form.Label>
                  <Form.Control placeholder="" size="lg" className="form-square" value={this.state.current.age || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="1"></Form.Group>
                <Form.Group as={Col} controlId="sex" md="6">
                  <Form.Label className="nav-input-label">SEX</Form.Label>
                  <Form.Control as="select" size="lg" className="form-square" value={this.state.current.sex || ''} onChange={this.handleChange}>
                    <option disabled></option>
                    <option>Female</option>
                    <option>Male</option>
                    <option>Unknown</option>
                  </Form.Control>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-1">
                <Form.Group as={Col} md="13">
                  <Form.Label className="nav-input-label">RACE</Form.Label>
                  <Form.Check type="switch" id="white" label="WHITE" checked={this.state.current.white === true || false} onChange={this.handleChange} />
                  <Form.Check className="pt-2" type="switch" id="black_or_african_american" label="BLACK OR AFRICAN AMERICAN" checked={this.state.current.black_or_african_american === true || false} onChange={this.handleChange} />
                  <Form.Check className="pt-2" type="switch" id="american_indian_or_alaska_native" label="AMERICAN INDIAN OR ALASKA NATIVE" checked={this.state.current.american_indian_or_alaska_native === true || false} onChange={this.handleChange} />
                  <Form.Check className="pt-2" type="switch" id="asian" label="ASIAN" checked={this.state.current.asian === true || false} onChange={this.handleChange} />
                  <Form.Check className="pt-2" type="switch" id="native_hawaiian_or_other_pacific_islander" label="NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER" checked={this.state.current.native_hawaiian_or_other_pacific_islander === true || false} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="11" controlId="ethnicity">
                  <Form.Label className="nav-input-label">ETHNICITY</Form.Label>
                  <Form.Control as="select" size="lg" className="form-square" value={this.state.current.ethnicity || ''} onChange={this.handleChange}>
                    <option disabled></option>
                    <option>Not Hispanic or Latino</option>
                    <option>Hispanic or Latino</option>
                  </Form.Control>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="8" controlId="primary_language">
                  <Form.Label className="nav-input-label">PRIMARY LANGUAGE</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.primary_language || ''} onChange={this.handleChange}  />
                </Form.Group>
                <Form.Group as={Col} md="1"></Form.Group>
                <Form.Group as={Col} md="8" controlId="secondary_language">
                  <Form.Label className="nav-input-label">SECONDARY LANGUAGE</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.secondary_language || ''} onChange={this.handleChange} />
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-1">
                <Form.Group as={Col}>
                  <Form.Check type="switch" id="interpretation_required" label="INTERPRETATION REQUIRED" checked={this.state.current.interpretation_required || false} onChange={this.handleChange} />
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