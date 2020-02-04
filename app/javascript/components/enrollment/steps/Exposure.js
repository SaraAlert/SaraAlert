import React from "react"
import { Card, Button, Form, Col } from 'react-bootstrap';
import { countryOptions } from '../../data';

class Exposure extends React.Component {

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
    let today = new Date().toISOString().substr(0, 10);
    return (
      <React.Fragment>
        <Card className="mx-2 card-square">
          <Card.Header as="h5">Subject Potential Exposure Information</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="7" controlId="last_date_of_potential_exposure">
                  <Form.Label className="nav-input-label">EXPOSURE DATE</Form.Label>
                  <Form.Control size="lg" type="date" className="form-square" value={this.state.current.last_date_of_potential_exposure || today} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="10" controlId="potential_exposure_location">
                  <Form.Label className="nav-input-label">EXPOSURE LOCATION</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.potential_exposure_location || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="7" controlId="potential_exposure_country">
                  <Form.Label className="nav-input-label">EXPOSURE COUNTRY</Form.Label>
                  <Form.Control as="select" size="lg" className="form-square" value={this.state.current.potential_exposure_country || ''} onChange={this.handleChange}>
                    <option></option>
                    {countryOptions.map((country, index) => (
                      <option key={`country-${index}`}>{country}</option>
                    ))}
                  </Form.Control>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2 pb-4 h-100">
                <Form.Group as={Col} className="my-auto">
                  <Form.Label className="nav-input-label">EXPOSURE RISK FACTORS</Form.Label>
                  <Form.Row>
                    <Form.Group as={Col} md="auto" className="mb-0 my-auto">
                      <Form.Check type="switch" id="contact_of_known_case" label="CONTACT OF KNOWN CASE" checked={this.state.current.contact_of_known_case === true || false} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} md="auto" className="mb-0 my-auto ml-4">
                      <Form.Control size="sm" className="form-square" id="contact_of_known_case_id" placeholder="enter case ID" value={this.state.current.contact_of_known_case_id || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row>
                    <Form.Group as={Col} md="auto" className="mb-0 my-auto">
                      <Form.Check className="pt-2 my-auto" type="switch" id="healthcare_worker" label="HEALTHCARE WORKER" checked={this.state.current.healthcare_worker === true || false} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row>
                    <Form.Group as={Col} md="auto" className="mb-0 my-auto">
                      <Form.Check className="pt-2 my-auto" type="switch" id="worked_in_health_care_facility" label="WORKED IN HEALTH CARE FACILITY" checked={this.state.current.worked_in_health_care_facility === true || false} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                </Form.Group>
              </Form.Row>
            </Form>
            {this.props.previous && <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>Previous</Button>}
            {this.props.next && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.next}>Next</Button>}
            {this.props.submit && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.submit}>Finish</Button>}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

export default Exposure