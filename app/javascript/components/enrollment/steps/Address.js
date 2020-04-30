import React from 'react';
import { Card, Button, Tabs, Tab, Form, Col } from 'react-bootstrap';
import { stateOptions, countryOptions } from '../../data';
import { PropTypes } from 'prop-types';
import * as yup from 'yup';

class Address extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props, current: { ...this.props.currentState }, errors: {}, modified: {}, selectedTab: 'domestic' };
    if (typeof this.props.currentState.monitored_address_state !== 'undefined') {
      // When viewing existing patients, the `monitored_address_state` needs to be reverse mapped back to the abbreviation
      this.state.current.patient.monitored_address_state = stateOptions.find(state => state.name === this.props.currentState.monitored_address_state)?.abbrv;
    }
    this.handleChange = this.handleChange.bind(this);
    this.whereMonitoredSameAsHome = this.whereMonitoredSameAsHome.bind(this);
    this.validate = this.validate.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let modified = this.state.modified;
    this.setState(
      {
        current: { ...current, patient: { ...current.patient, [event.target.id]: value } },
        modified: { ...modified, patient: { ...modified.patient, [event.target.id]: value } },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  }

  whereMonitoredSameAsHome() {
    let current = this.state.current;
    this.setState(
      {
        current: {
          ...current,
          patient: {
            ...current.patient,
            monitored_address_line_1: current.patient.address_line_1,
            monitored_address_city: current.patient.address_city,
            monitored_address_state: current.patient.address_state,
            monitored_address_line_2: current.patient.address_line_2,
            monitored_address_zip: current.patient.address_zip,
            monitored_address_county: current.patient.address_county,
          },
        },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.current });
      }
    );
  }

  validate(callback) {
    let self = this;
    if (this.state.selectedTab === 'domestic') {
      schemaDomestic
        .validate(this.state.current.patient, { abortEarly: false })
        .then(function() {
          // No validation issues? Invoke callback (move to next step)
          self.setState({ errors: {} }, () => {
            callback();
          });
        })
        .catch(err => {
          // Validation errors, update state to display to user
          if (err && err.inner) {
            let issues = {};
            for (var issue of err.inner) {
              issues[issue['path']] = issue['errors'];
            }
            self.setState({ errors: issues });
          }
        });
    } else if (this.state.selectedTab === 'foreign') {
      schemaForeign
        .validate(this.state.current.patient, { abortEarly: false })
        .then(function() {
          // No validation issues? Invoke callback (move to next step)
          self.setState({ errors: {} }, () => {
            callback();
          });
        })
        .catch(err => {
          // Validation errors, update state to display to user
          if (err && err.inner) {
            let issues = {};
            for (var issue of err.inner) {
              issues[issue['path']] = issue['errors'];
            }
            self.setState({ errors: issues });
          }
        });
    }
  }

  render() {
    return (
      <React.Fragment>
        <Card className="mx-2 card-square">
          <Card.Header as="h5">Monitoree Address</Card.Header>
          <Card.Body>
            <Tabs
              defaultActiveKey={this.state.selectedTab}
              id="patient_address"
              className="g-border-bottom"
              onSelect={() => {
                this.setState({ selectedTab: this.state.selectedTab === 'domestic' ? 'foreign' : 'domestic' });
              }}>
              <Tab eventKey="domestic" title="Home Address Within USA">
                <Form>
                  <Form.Row className="h-100">
                    <Form.Group as={Col} md={12} className="my-auto"></Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-4">
                    <Form.Group as={Col} controlId="address_line_1">
                      <Form.Label className="nav-input-label">ADDRESS 1{schemaDomestic?.fields?.address_line_1?._exclusive?.required && ' *'}</Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['address_line_1']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.address_line_1 || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['address_line_1']}
                      </Form.Control.Feedback>
                    </Form.Group>
                    <Form.Group as={Col} controlId="address_city">
                      <Form.Label className="nav-input-label">TOWN/CITY{schemaDomestic?.fields?.address_city?._exclusive?.required && ' *'}</Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['address_city']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.address_city || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['address_city']}
                      </Form.Control.Feedback>
                    </Form.Group>
                    <Form.Group as={Col} controlId="address_state">
                      <Form.Label className="nav-input-label">STATE{schemaDomestic?.fields?.address_state?._exclusive?.required && ' *'}</Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['address_state']}
                        as="select"
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.address_state || ''}
                        onChange={this.handleChange}>
                        <option></option>
                        {stateOptions.map((state, index) => (
                          <option key={`state-${index}`} value={state.name}>
                            {state.name}
                          </option>
                        ))}
                      </Form.Control>
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['address_state']}
                      </Form.Control.Feedback>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="address_line_2">
                      <Form.Label className="nav-input-label">ADDRESS 2{schemaDomestic?.fields?.address_line_2?._exclusive?.required && ' *'}</Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['address_line_2']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.address_line_2 || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['address_line_2']}
                      </Form.Control.Feedback>
                    </Form.Group>
                    <Form.Group as={Col} md={4} controlId="address_zip">
                      <Form.Label className="nav-input-label">ZIP{schemaDomestic?.fields?.address_zip?._exclusive?.required && ' *'}</Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['address_zip']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.address_zip || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['address_zip']}
                      </Form.Control.Feedback>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="address_county">
                      <Form.Label className="nav-input-label">
                        COUNTY (DISTRICT) {schemaDomestic?.fields?.address_county?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['address_county']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.address_county || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['address_county']}
                      </Form.Control.Feedback>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row>
                    <hr />
                  </Form.Row>
                  <Form.Row className="h-100">
                    <Form.Group as={Col} className="my-auto">
                      <h5>
                        Address at Destination in USA Where Monitored
                        <Button size="md" variant="outline-primary" className="ml-4 btn-square px-3" onClick={this.whereMonitoredSameAsHome}>
                          Copy from Home Address
                        </Button>
                      </h5>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-1 pb-2">
                    <Form.Group as={Col} md={24} className="my-auto">
                      <span className="font-weight-light">
                        (If monitoree is planning on travel within the US, enter the <b>first</b> location where they may be contacted)
                      </span>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-3">
                    <Form.Group as={Col} controlId="monitored_address_line_1">
                      <Form.Label className="nav-input-label">
                        ADDRESS 1{schemaDomestic?.fields?.monitored_address_line_1?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['monitored_address_line_1']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.monitored_address_line_1 || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['monitored_address_line_1']}
                      </Form.Control.Feedback>
                    </Form.Group>
                    <Form.Group as={Col} controlId="monitored_address_city">
                      <Form.Label className="nav-input-label">
                        TOWN/CITY{schemaDomestic?.fields?.monitored_address_city?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['monitored_address_city']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.monitored_address_city || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['monitored_address_city']}
                      </Form.Control.Feedback>
                    </Form.Group>
                    <Form.Group as={Col} controlId="monitored_address_state">
                      <Form.Label className="nav-input-label">STATE{schemaDomestic?.fields?.monitored_address_state?._exclusive?.required && ' *'}</Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['monitored_address_state']}
                        as="select"
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.monitored_address_state || ''}
                        onChange={this.handleChange}>
                        <option></option>
                        {stateOptions.map((state, index) => (
                          <option key={`state-${index}`} value={state.name}>
                            {state.name}
                          </option>
                        ))}
                      </Form.Control>
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['monitored_address_state']}
                      </Form.Control.Feedback>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="monitored_address_line_2">
                      <Form.Label className="nav-input-label">
                        ADDRESS 2{schemaDomestic?.fields?.monitored_address_line_2?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['monitored_address_line_2']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.monitored_address_line_2 || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['monitored_address_line_2']}
                      </Form.Control.Feedback>
                    </Form.Group>
                    <Form.Group as={Col} md={4} controlId="monitored_address_zip">
                      <Form.Label className="nav-input-label">ZIP{schemaDomestic?.fields?.monitored_address_zip?._exclusive?.required && ' *'}</Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['monitored_address_zip']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.monitored_address_zip || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['monitored_address_zip']}
                      </Form.Control.Feedback>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2 pb-3">
                    <Form.Group as={Col} md={8} controlId="monitored_address_county">
                      <Form.Label className="nav-input-label">
                        COUNTY (DISTRICT) {schemaDomestic?.fields?.monitored_address_county?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['monitored_address_county']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.monitored_address_county || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['monitored_address_county']}
                      </Form.Control.Feedback>
                    </Form.Group>
                  </Form.Row>
                </Form>
              </Tab>
              <Tab eventKey="foreign" title="Home Address Outside USA (Foreign)">
                <Form>
                  <Form.Row className="h-100">
                    <Form.Group as={Col} md={12} className="my-auto"></Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-4">
                    <Form.Group as={Col} controlId="foreign_address_line_1">
                      <Form.Label className="nav-input-label">
                        ADDRESS 1{schemaForeign?.fields?.foreign_address_line_1?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['foreign_address_line_1']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.foreign_address_line_1 || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['foreign_address_line_1']}
                      </Form.Control.Feedback>
                    </Form.Group>
                    <Form.Group as={Col} controlId="foreign_address_city">
                      <Form.Label className="nav-input-label">TOWN/CITY{schemaForeign?.fields?.foreign_address_city?._exclusive?.required && ' *'}</Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['foreign_address_city']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.foreign_address_city || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['foreign_address_city']}
                      </Form.Control.Feedback>
                    </Form.Group>
                    <Form.Group as={Col} controlId="foreign_address_country">
                      <Form.Label className="nav-input-label">COUNTRY{schemaForeign?.fields?.foreign_address_country?._exclusive?.required && ' *'}</Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['foreign_address_country']}
                        as="select"
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.foreign_address_country || ''}
                        onChange={this.handleChange}>
                        <option></option>
                        {countryOptions.map((country, index) => (
                          <option key={`country-${index}`}>{country}</option>
                        ))}
                      </Form.Control>
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['foreign_address_country']}
                      </Form.Control.Feedback>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="foreign_address_line_2">
                      <Form.Label className="nav-input-label">
                        ADDRESS 2{schemaForeign?.fields?.foreign_address_line_2?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['foreign_address_line_2']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.foreign_address_line_2 || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['foreign_address_line_2']}
                      </Form.Control.Feedback>
                    </Form.Group>
                    <Form.Group as={Col} md={4} controlId="foreign_address_zip">
                      <Form.Label className="nav-input-label">POSTAL CODE{schemaForeign?.fields?.foreign_address_zip?._exclusive?.required && ' *'}</Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['foreign_address_zip']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.foreign_address_zip || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['foreign_address_zip']}
                      </Form.Control.Feedback>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="foreign_address_line_3">
                      <Form.Label className="nav-input-label">
                        ADDRESS 3{schemaForeign?.fields?.foreign_address_line_3?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['foreign_address_line_3']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.foreign_address_line_3 || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['foreign_address_line_3']}
                      </Form.Control.Feedback>
                    </Form.Group>
                    <Form.Group as={Col} md={4} controlId="foreign_address_state">
                      <Form.Label className="nav-input-label">
                        STATE/PROVINCE{schemaForeign?.fields?.foreign_address_state?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['foreign_address_state']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.foreign_address_state || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['foreign_address_state']}
                      </Form.Control.Feedback>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row>
                    <hr />
                  </Form.Row>
                  <Form.Row className="h-100">
                    <Form.Group as={Col} md={24} className="my-auto">
                      <h5>Address at Destination in USA Where Monitored</h5>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2 pb-2">
                    <Form.Group as={Col} md={24} className="my-auto">
                      <span className="font-weight-light">
                        (If monitoree is planning on travel within the US, enter the <b>first</b> location where they may be contacted)
                      </span>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-3">
                    <Form.Group as={Col} controlId="foreign_monitored_address_line_1">
                      <Form.Label className="nav-input-label">
                        ADDRESS 1{schemaForeign?.fields?.foreign_monitored_address_line_1?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['foreign_monitored_address_line_1']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.foreign_monitored_address_line_1 || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['foreign_monitored_address_line_1']}
                      </Form.Control.Feedback>
                    </Form.Group>
                    <Form.Group as={Col} controlId="foreign_monitored_address_city">
                      <Form.Label className="nav-input-label">
                        TOWN/CITY{schemaForeign?.fields?.foreign_monitored_address_city?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['foreign_monitored_address_city']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.foreign_monitored_address_city || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['foreign_monitored_address_city']}
                      </Form.Control.Feedback>
                    </Form.Group>
                    <Form.Group as={Col} controlId="foreign_monitored_address_state">
                      <Form.Label className="nav-input-label">
                        STATE{schemaForeign?.fields?.foreign_monitored_address_state?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['foreign_monitored_address_state']}
                        as="select"
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.foreign_monitored_address_state || ''}
                        onChange={this.handleChange}>
                        <option></option>
                        {stateOptions.map((state, index) => (
                          <option key={`state-${index}`} value={state.name}>
                            {state.name}
                          </option>
                        ))}
                      </Form.Control>
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['foreign_monitored_address_state']}
                      </Form.Control.Feedback>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2">
                    <Form.Group as={Col} md={8} controlId="foreign_monitored_address_line_2">
                      <Form.Label className="nav-input-label">
                        ADDRESS 2{schemaForeign?.fields?.foreign_monitored_address_line_2?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['foreign_monitored_address_line_2']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.foreign_monitored_address_line_2 || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['foreign_monitored_address_line_2']}
                      </Form.Control.Feedback>
                    </Form.Group>
                    <Form.Group as={Col} md={4} controlId="foreign_monitored_address_zip">
                      <Form.Label className="nav-input-label">
                        ZIP{schemaForeign?.fields?.foreign_monitored_address_zip?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['foreign_monitored_address_zip']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.foreign_monitored_address_zip || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['foreign_monitored_address_zip']}
                      </Form.Control.Feedback>
                    </Form.Group>
                  </Form.Row>
                  <Form.Row className="pt-2 pb-3">
                    <Form.Group as={Col} md={8} controlId="foreign_monitored_address_county">
                      <Form.Label className="nav-input-label">
                        COUNTY (DISTRICT) {schemaForeign?.fields?.foreign_monitored_address_county?._exclusive?.required && ' *'}
                      </Form.Label>
                      <Form.Control
                        isInvalid={this.state.errors['foreign_monitored_address_county']}
                        size="lg"
                        className="form-square"
                        value={this.state.current.patient.foreign_monitored_address_county || ''}
                        onChange={this.handleChange}
                      />
                      <Form.Control.Feedback className="d-block" type="invalid">
                        {this.state.errors['foreign_monitored_address_county']}
                      </Form.Control.Feedback>
                    </Form.Group>
                  </Form.Row>
                </Form>
              </Tab>
            </Tabs>
            {this.props.previous && (
              <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>
                Previous
              </Button>
            )}
            {this.props.next && (
              <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={() => this.validate(this.props.next)}>
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

const schemaDomestic = yup.object().shape({
  address_line_1: yup
    .string()
    .required('Please enter first line of address.')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  address_city: yup
    .string()
    .required('Please enter city of address.')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  address_state: yup
    .string()
    .required('Please enter state of address.')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  address_line_2: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  address_zip: yup
    .string()
    .required('Please enter zip code of address.')
    .matches(/^$|(^\d{5}$)|(^\d{5}-\d{4}$)/, 'Invalid zip-code format')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  address_county: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  monitored_address_line_1: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  monitored_address_city: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  monitored_address_state: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  monitored_address_line_2: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  monitored_address_zip: yup
    .string()
    .matches(/^$|(^\d{5}$)|(^\d{5}-\d{4}$)/, 'Invalid zip-code format')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  monitored_address_county: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
});

const schemaForeign = yup.object().shape({
  foreign_address_line_1: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  foreign_address_city: yup
    .string()
    .required('Please enter city of address.')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  foreign_address_country: yup
    .string()
    .required('Please enter country of address.')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  foreign_address_line_2: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  foreign_address_zip: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  foreign_address_line_3: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  foreign_address_state: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  foreign_monitored_address_line_1: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  foreign_monitored_address_city: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  foreign_monitored_address_state: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  foreign_monitored_address_line_2: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  foreign_monitored_address_zip: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  foreign_monitored_address_county: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
});

Address.propTypes = {
  currentState: PropTypes.object,
  previous: PropTypes.func,
  setEnrollmentState: PropTypes.func,
  next: PropTypes.func,
  submit: PropTypes.func,
};

export default Address;
