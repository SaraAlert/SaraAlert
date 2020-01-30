import React from "react"
import { Card, Button, Form, Col } from 'react-bootstrap';

class Arrival extends React.Component {

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
        <Card className="mx-4 card-square">
          <Card.Header as="h5">Subject Arrival Information</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="8" controlId="port_of_origin">
                  <Form.Label className="nav-input-label">PORT OF ORIGIN</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.port_of_origin || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="6" controlId="date_of_departure">
                  <Form.Label className="nav-input-label">DATE OF DEPARTURE</Form.Label>
                  <Form.Control size="lg" type="date" className="form-square" value={this.state.current.date_of_departure || today} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="2"></Form.Group>
                <Form.Group as={Col} md="8" controlId="source_of_report">
                  <Form.Label className="nav-input-label">SOURCE OF REPORT</Form.Label>
                  <Form.Control as="select" size="lg" className="form-square" value={this.state.current.source_of_report || ''} onChange={this.handleChange}>
                    <option disabled></option>
                    <option>Self-Identified</option>
                    <option>CDC</option>
                    <option>Other</option>
                  </Form.Control>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="8" controlId="flight_or_vessel_number">
                  <Form.Label className="nav-input-label">FLIGHT OR VESSEL NUMBER</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.flight_or_vessel_number || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="7" controlId="flight_or_vessel_carrier">
                  <Form.Label className="nav-input-label">CARRIER</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.flight_or_vessel_carrier || ''} onChange={this.handleChange} />
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="8" controlId="port_of_entry_into_usa">
                  <Form.Label className="nav-input-label">PORT OF ENTRY INTO USA</Form.Label>
                  <Form.Control size="lg" className="form-square" value={this.state.current.port_of_entry_into_usa || ''} onChange={this.handleChange} />
                </Form.Group>
                <Form.Group as={Col} md="6" controlId="date_of_arrival">
                  <Form.Label className="nav-input-label">DATE OF ARRIVAL</Form.Label>
                  <Form.Control size="lg" type="date" className="form-square" value={this.state.current.date_of_arrival || today} onChange={this.handleChange} />
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2 pb-3">
                <Form.Group as={Col} md="24" controlId="travel_related_notes">
                  <Form.Label className="nav-input-label">TRAVEL RELATED NOTES</Form.Label>
                  <Form.Control as="textarea" rows="5" size="lg" className="form-square" placeholder="enter additional information about subject’s travel history (e.g. visited farm, sick relative, original country departed from, etc.)" value={this.state.current.travel_related_notes || ''} onChange={this.handleChange} />
                </Form.Group>
              </Form.Row>
            </Form>
            {this.props.previous && <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>Previous</Button>}
            {this.props.next && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.next}>{!!this.props.lastIndex && "Back"}{!!!this.props.lastIndex && "Next"}</Button>}
            {this.props.finish && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.finish}>Finish</Button>}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

export default Arrival