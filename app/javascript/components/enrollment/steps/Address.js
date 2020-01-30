import React from "react"
import { Card, Button, Tabs, Tab, Form, Col } from 'react-bootstrap';
import countries from 'countries-list';

class Address extends React.Component {

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
    this.state = { ...this.props, current: {...this.props.currentState}, states, countries: Object.values(countries.countries)};
    this.handleChange = this.handleChange.bind(this);
    this.whereMonitoredSameAsHome = this.whereMonitoredSameAsHome.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === "checkbox" ? event.target.checked : event.target.value;
    let current = this.state.current;
    this.setState({current: {...current, [event.target.id]: value}}, () => {
      this.props.setEnrollmentState({ ...this.state.current });
    });
  }

  whereMonitoredSameAsHome() {
    let currentState = this.state.current;
    this.setState({ current: { ...currentState,
      monitored_address_line_1: currentState.address_line_1,
      monitored_address_city: currentState.address_city,
      monitored_address_state: currentState.address_state,
      monitored_address_line_2: currentState.address_line_2,
      monitored_address_zip: currentState.address_zip,
      monitored_address_county: currentState.address_county
    } }, () => {
      this.props.setEnrollmentState({ ...this.state.current });
    });
  }

  render () {
    return (
      <React.Fragment>
        <Card className="mx-4 card-square">
          <Card.Header as="h5">Subject Address</Card.Header>
          <Card.Body>
            <Tabs defaultActiveKey="within" id="patient_address" className="g-border-bottom">
              <Tab eventKey="within" title="Home Address Within USA">
                <Form>
                  <Form.Row className="h-100">
                    <Form.Group as={Col} md={12} className="my-auto">
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-4">
                    <Form.Group as={Col} controlId="address_line_1">
                      <Form.Label className="nav-input-label">ADDRESS 1</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.address_line_1 || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} controlId="address_city">
                      <Form.Label className="nav-input-label">TOWN/CITY</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.address_city || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} controlId="address_state">
                      <Form.Label className="nav-input-label">STATE</Form.Label>
                      <Form.Control as="select" size="lg" className="form-square" value={this.state.current.address_state || ''} onChange={this.handleChange}>
                        <option disabled></option>
                        {this.state.states.map((state, index) => (
                          <option key={`state-${index}`}>{state}</option>
                        ))}
                      </Form.Control>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="address_line_2">
                      <Form.Label className="nav-input-label">ADDRESS 2</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.address_line_2 || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} md={4} controlId="address_zip">
                      <Form.Label className="nav-input-label">ZIP</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.address_zip || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="address_county">
                      <Form.Label className="nav-input-label">COUNTY</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.address_county || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row><hr/></Form.Row>
                  <Form.Row className="h-100">
                    <Form.Group as={Col} className="my-auto">
                      <h5>Address at Destination in USA Where Monitored<Button size="md" variant="outline-primary" className="ml-4 btn-square px-3" onClick={this.whereMonitoredSameAsHome}>Set to Home Address</Button></h5>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-1 pb-2">
                    <Form.Group as={Col} md={24} className="my-auto">
                      <span className="font-weight-light">(If subject is planning on travel within the US, enter the <b>first</b> location where they may be contacted)</span>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-3">
                    <Form.Group as={Col} controlId="monitored_address_line_1">
                      <Form.Label className="nav-input-label">ADDRESS 1</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.monitored_address_line_1 || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} controlId="monitored_address_city">
                      <Form.Label className="nav-input-label">TOWN/CITY</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.monitored_address_city || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} controlId="monitored_address_state">
                      <Form.Label className="nav-input-label">STATE</Form.Label>
                      <Form.Control as="select" size="lg" className="form-square" value={this.state.current.monitored_address_state || ''} onChange={this.handleChange}>
                        <option disabled></option>
                        {this.state.states.map((state, index) => (
                          <option key={`state-${index}`}>{state}</option>
                        ))}
                      </Form.Control>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="monitored_address_line_2">
                      <Form.Label className="nav-input-label">ADDRESS 2</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.monitored_address_line_2 || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} md={4} controlId="monitored_address_zip">
                      <Form.Label className="nav-input-label">ZIP</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.monitored_address_zip || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2 pb-3">
                    <Form.Group as={Col} md={8} controlId="monitored_address_county">
                      <Form.Label className="nav-input-label">COUNTY</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.monitored_address_county || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                </Form>
              </Tab>
              <Tab eventKey="outside" title="Home Address Outside USA (Foreign)">
                <Form>
                  <Form.Row className="h-100">
                    <Form.Group as={Col} md={12} className="my-auto">
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-4">
                    <Form.Group as={Col} controlId="foreign_address_line_1">
                      <Form.Label className="nav-input-label">ADDRESS 1</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.foreign_address_line_1 || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} controlId="foreign_address_city">
                      <Form.Label className="nav-input-label">TOWN/CITY</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.foreign_address_city || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} controlId="foreign_address_country">
                      <Form.Label className="nav-input-label">COUNTRY</Form.Label>
                      <Form.Control as="select" size="lg" className="form-square" value={this.state.current.foreign_address_country || ''} onChange={this.handleChange}>
                        <option disabled></option>
                        {this.state.countries.map((country, index) => (
                          <option key={`country-${index}`}>{country.name}</option>
                        ))}
                      </Form.Control>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="foreign_address_line_2">
                      <Form.Label className="nav-input-label">ADDRESS 2</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.foreign_address_line_2 || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} md={4} controlId="foreign_address_zip">
                      <Form.Label className="nav-input-label">POSTAL CODE</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.foreign_address_zip || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="foreign_address_line_3">
                      <Form.Label className="nav-input-label">ADDRESS 3</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.foreign_address_line_3 || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} md={4} controlId="foreign_address_state">
                      <Form.Label className="nav-input-label">STATE/PROVINCE</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.foreign_address_state || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row><hr/></Form.Row>
                  <Form.Row className="h-100">
                    <Form.Group as={Col} md={24} className="my-auto">
                      <h5>Address at Destination in USA Where Monitored</h5>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2 pb-2">
                    <Form.Group as={Col} md={24} className="my-auto">
                      <span className="font-weight-light">(If subject is planning on travel within the US, enter the <b>first</b> location where they may be contacted)</span>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-3">
                    <Form.Group as={Col} controlId="foreign_monitored_address_line_1">
                      <Form.Label className="nav-input-label">ADDRESS 1</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.foreign_monitored_address_line_1 || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} controlId="foreign_monitored_address_city">
                      <Form.Label className="nav-input-label">TOWN/CITY</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.foreign_monitored_address_city || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} controlId="foreign_monitored_address_state">
                      <Form.Label className="nav-input-label">STATE</Form.Label>
                      <Form.Control as="select" size="lg" className="form-square" value={this.state.current.foreign_monitored_address_state || ''} onChange={this.handleChange}>
                        <option disabled></option>
                        {this.state.states.map((state, index) => (
                          <option key={`state-${index}`}>{state}</option>
                        ))}
                      </Form.Control>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="foreign_monitored_address_line_2">
                      <Form.Label className="nav-input-label">ADDRESS 2</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.foreign_monitored_address_line_2 || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} md={4} controlId="foreign_monitored_address_zip">
                      <Form.Label className="nav-input-label">ZIP</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.foreign_monitored_address_zip || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2 pb-3">
                    <Form.Group as={Col} md={8} controlId="foreign_monitored_address_county">
                      <Form.Label className="nav-input-label">COUNTY</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.current.foreign_monitored_address_county || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                </Form>
              </Tab>
            </Tabs>
            {this.props.previous && <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>Previous</Button>}
            {this.props.next && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.next}>{!!this.props.lastIndex && "Back"}{!!!this.props.lastIndex && "Next"}</Button>}
            {this.props.submit && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.submit}>Finish</Button>}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

export default Address