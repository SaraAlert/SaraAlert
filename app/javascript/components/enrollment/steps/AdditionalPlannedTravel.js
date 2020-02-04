import React from "react"
import { Card, Button, Form, Col } from 'react-bootstrap';
import { stateOptions, countryOptions } from '../../data';

class AdditionalPlannedTravel extends React.Component {

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
          <Card.Header as="h5">Additional Planned Travel</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="8" controlId="additional_planned_travel_type">
                  <Form.Label className="nav-input-label">TRAVEL TYPE</Form.Label>
                  <Form.Control as="select" size="lg" className="form-square" value={this.state.current.additional_planned_travel_type || ''} onChange={this.handleChange}>
                    <option></option>
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
                      <option></option>
                      {countryOptions.map((country, index) => (
                        <option key={`country-${index}`}>{country}</option>
                      ))}
                    </Form.Control>
                  </Form.Group>
                )}
                {!(this.state.current.additional_planned_travel_type && this.state.current.additional_planned_travel_type === "International") && (
                  <Form.Group as={Col} md="8" controlId="additional_planned_travel_destination_state">
                    <Form.Label className="nav-input-label">DESTINATION STATE</Form.Label>
                    <Form.Control as="select" size="lg" className="form-square" placeholder="Please enter state..." value={this.state.current.additional_planned_travel_destination_state || ''} onChange={this.handleChange}>
                        <option></option>
                        {stateOptions.map((state, index) => (
                          <option key={`state-${index}`} value={state.abbrv}>{state.name}</option>
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
            {this.props.next && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.next}>Next</Button>}
            {this.props.submit && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.submit}>Finish</Button>}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

export default AdditionalPlannedTravel