import React from "react"
import { Card, Button, Form, Col } from 'react-bootstrap';
import countries from 'countries-list';

class AdditionalPlannedTravel extends React.Component {

  constructor(props) {
    super(props);
    let states = ['Alabama','Alaska','American Samoa','Arizona','Arkansas','California',
                  'Colorado','Connecticut','Delaware','District of Columbia','Federated States of Micronesia',
                  'Florida','Georgia','Guam','Hawaii','Idaho','Illinois','Indiana','Iowa','Kansas','Kentucky',
                  'Louisiana','Maine','Marshall Islands','Maryland','Massachusetts','Michigan','Minnesota',
                  'Mississippi','Missouri','Montana','Nebraska','Nevada','New Hampshire','New Jersey',
                  'New Mexico','New York','North Carolina','North Dakota','Northern Mariana Islands','Ohio',
                  'Oklahoma','Oregon','Palau','Pennsylvania','Puerto Rico','Rhode Island','South Carolina',
                  'South Dakota','Tennessee','Texas','Utah','Vermont','Virgin Island','Virginia','Washington',
                  'West Virginia','Wisconsin','Wyoming'];
    this.state = { ...this.props, current: {...this.props.currentState}, states, countries: Object.values(countries.countries) };
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
        <Card className="mx-4 card-square">
          <Card.Header as="h5">Additional Planned Travel</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="8" controlId="additional_planned_travel_type">
                  <Form.Label className="nav-input-label">TRAVEL TYPE</Form.Label>
                  <Form.Control as="select" size="lg" className="form-square" value={this.state.current.additional_planned_travel_type || ''} onChange={this.handleChange}>
                    <option disabled></option>
                    <option>Domestic</option>
                    <option>International</option>
                  </Form.Control>
                </Form.Group>
                <Form.Group as={Col} md="8" controlId="additional_planned_travel_destination">
                  <Form.Label className="nav-input-label">DESTINATION</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.additional_planned_travel_destination || ''} onChange={this.handleChange} />
                </Form.Group>
                {(this.state.current.additional_planned_travel_type && this.state.current.additional_planned_travel_type === "International") && (
                  <Form.Group as={Col} md="8" controlId="additional_planned_travel_destination_country">
                    <Form.Label className="nav-input-label">DESTINATION COUNTRY</Form.Label>
                    <Form.Control as="select" size="lg" className="form-square" value={this.state.current.additional_planned_travel_destination_country || ''} onChange={this.handleChange}>
                      <option disabled></option>
                      {this.state.countries.map((country, index) => (
                        <option key={`country-${index}`}>{country.name}</option>
                      ))}
                    </Form.Control>
                  </Form.Group>
                )}
                {!(this.state.current.additional_planned_travel_type && this.state.current.additional_planned_travel_type === "International") && (
                  <Form.Group as={Col} md="8" controlId="additional_planned_travel_destination_state">
                    <Form.Label className="nav-input-label">DESTINATION STATE</Form.Label>
                    <Form.Control as="select" size="lg" className="form-square" placeholder="Please enter state..." value={this.state.current.additional_planned_travel_destination_state || ''} onChange={this.handleChange}>
                      <option disabled></option>
                      {this.state.states.map((state, index) => (
                        <option key={`state-${index}`}>{state}</option>
                      ))}
                    </Form.Control>
                  </Form.Group>
                )}
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="8" controlId="additional_planned_travel_port_of_departure">
                  <Form.Label className="nav-input-label">PORT OF DEPARTURE</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.additional_planned_travel_port_of_departure || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="6" controlId="additional_planned_travel_start_date">
                  <Form.Label className="nav-input-label">START DATE</Form.Label>
                  <Form.Control size="lg" type="date" className="form-square" value={this.state.current.additional_planned_travel_start_date || today} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="6" controlId="additional_planned_travel_end_date">
                  <Form.Label className="nav-input-label">END DATE</Form.Label>
                  <Form.Control size="lg" type="date" className="form-square" value={this.state.current.additional_planned_travel_end_date || today} onChange={this.handleChange} />
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2 pb-3">
                <Form.Group as={Col} md="24" controlId="additional_planned_travel_related_notes">
                  <Form.Label className="nav-input-label">ADDITIONAL PLANNED TRAVEL NOTES</Form.Label>
                  <Form.Control as="textarea" rows="5" size="lg" className="form-square" placeholder="enter additional information about subject’s planned travel (e.g. additional destinations, planned activities/social interactions, etc...)" value={this.state.current.additional_planned_travel_related_notes || ''} onChange={this.handleChange} />
                </Form.Group>
              </Form.Row>
            </Form>
            {this.props.previous && <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>Previous</Button>}
            {this.props.next && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.next}>{!!this.props.lastIndex && "Back"}{!!!this.props.lastIndex && "Next"}</Button>}
            {this.props.submit && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.submit}>Finish</Button>}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

export default AdditionalPlannedTravel