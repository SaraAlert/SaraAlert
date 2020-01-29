import React from "react"
import { Card, Button, Tabs, Tab, Form, Col } from 'react-bootstrap';

class Address extends React.Component {

  constructor(props) {
    super(props);
    this.state = { ...this.props, ...this.props.currentState };
    this.handleChange = this.handleChange.bind(this);
    this.whereMonitoredSameAsHome = this.whereMonitoredSameAsHome.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === "checkbox" ? event.target.checked : event.target.value;
    this.setState({[event.target.id]: value}, () => {
      this.props.setEnrollmentState({ ...this.state });
    });
  }

  whereMonitoredSameAsHome() {
    let currentState = this.state;
    this.setState({
      monitored_address_line_1: currentState.address_line_1,
      monitored_address_city: currentState.address_city,
      monitored_address_state: currentState.address_state,
      monitored_address_line_2: currentState.address_line_2,
      monitored_address_zip: currentState.address_zip,
      monitored_address_county: currentState.address_county
    });
  }

  render () {
    return (
      <React.Fragment>
        <Card className="mx-5 card-square">
          <Card.Header as="h4">Subject Address</Card.Header>
          <Card.Body>
            <Tabs defaultActiveKey="within" id="patient_address" transition={false} className="pb-5">
              <Tab eventKey="within" title="Home Address Within USA">
                <Form>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} controlId="address_line_1">
                      <Form.Label className="nav-input-label">ADDRESS 1</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.address_line_1 || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} controlId="address_city">
                      <Form.Label className="nav-input-label">TOWN/CITY</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.address_city || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} controlId="address_state">
                      <Form.Label className="nav-input-label">STATE</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.address_state || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="address_line_2">
                      <Form.Label className="nav-input-label">ADDRESS 2</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.address_line_2 || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} md={4} controlId="address_zip">
                      <Form.Label className="nav-input-label">ZIP</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.address_zip || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="address_county">
                      <Form.Label className="nav-input-label">COUNTY</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.address_county || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-5 h-100">
                    <Form.Group as={Col} md={8} className="my-auto">
                      <Form.Label className="nav-input-label">Address at Destination Where Monitored</Form.Label>
                    </Form.Group>
                    <Form.Group as={Col} md={16} className="my-auto">
                      <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.whereMonitoredSameAsHome}>Same as Home Address</Button>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-4">
                    <Form.Group as={Col} controlId="monitored_address_line_1">
                      <Form.Label className="nav-input-label">ADDRESS 1</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.monitored_address_line_1 || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} controlId="monitored_address_city">
                      <Form.Label className="nav-input-label">TOWN/CITY</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.monitored_address_city || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} controlId="monitored_address_state">
                      <Form.Label className="nav-input-label">STATE</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.monitored_address_state || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="monitored_address_line_2">
                      <Form.Label className="nav-input-label">ADDRESS 2</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.monitored_address_line_2 || ''} onChange={this.handleChange} />
                    </Form.Group>
                    <Form.Group as={Col} md={4} controlId="monitored_address_zip">
                      <Form.Label className="nav-input-label">ZIP</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.monitored_address_zip || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2 pb-3">
                    <Form.Group as={Col} md={8} controlId="monitored_address_county">
                      <Form.Label className="nav-input-label">COUNTY</Form.Label>
                      <Form.Control size="lg" className="form-square" value={this.state.monitored_address_county || ''} onChange={this.handleChange} />
                    </Form.Group>
                  </Form.Row>
                </Form>
              </Tab>
              <Tab eventKey="outside" title="Home Address Outside USA">
                blah
              </Tab>
            </Tabs>
            {this.props.previous && <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>Previous</Button>}
            {this.props.next && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.next}>Next</Button>}
            {this.props.finish && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.finish}>Finish</Button>}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

export default Address