import React from 'react';
import { Card, Button, Form, Col } from 'react-bootstrap';
import { stateOptions, countryOptions } from '../../data';
import { PropTypes } from 'prop-types';
import * as yup from 'yup';

class AdditionalPlannedTravel extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props, current: { ...this.props.currentState }, modified: {}, errors: {} };
    this.handleChange = this.handleChange.bind(this);
    this.validate = this.validate.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let modified = this.state.modified;
    value =
      (event.target.id === 'additional_planned_travel_start_date' || event.target.id === 'additional_planned_travel_end_date') && value === ''
        ? undefined
        : value;
    this.setState({ current: { ...current, [event.target.id]: value }, modified: { ...modified, [event.target.id]: value } }, () => {
      this.props.setEnrollmentState({ ...this.state.modified });
    });
  }

  validate(callback) {
    let self = this;
    schema
      .validate(this.state.current, { abortEarly: false })
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

  render() {
    return (
      <React.Fragment>
        <Card className="mx-2 card-square">
          <Card.Header as="h5">Additional Planned Travel</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="8" controlId="additional_planned_travel_type">
                  <Form.Label className="nav-input-label">TRAVEL TYPE{schema?.fields?.additional_planned_travel_type?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['additional_planned_travel_type']}
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.additional_planned_travel_type || ''}
                    onChange={this.handleChange}>
                    <option></option>
                    <option>Domestic</option>
                    <option>International</option>
                  </Form.Control>
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['additional_planned_travel_type']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} md="8" controlId="additional_planned_travel_destination">
                  <Form.Label className="nav-input-label">
                    DESTINATION{schema?.fields?.additional_planned_travel_destination?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['additional_planned_travel_destination']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.additional_planned_travel_destination || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['additional_planned_travel_destination']}
                  </Form.Control.Feedback>
                </Form.Group>
                {this.state.current.additional_planned_travel_type && this.state.current.additional_planned_travel_type === 'International' && (
                  <Form.Group as={Col} md="8" controlId="additional_planned_travel_destination_country">
                    <Form.Label className="nav-input-label">
                      DESTINATION COUNTRY{schema?.fields?.additional_planned_travel_destination_country?._exclusive?.required && ' *'}
                    </Form.Label>
                    <Form.Control
                      isInvalid={this.state.errors['additional_planned_travel_destination_country']}
                      as="select"
                      size="lg"
                      className="form-square"
                      value={this.state.current.additional_planned_travel_destination_country || ''}
                      onChange={this.handleChange}>
                      <option></option>
                      {countryOptions.map((country, index) => (
                        <option key={`country-${index}`}>{country}</option>
                      ))}
                    </Form.Control>
                    <Form.Control.Feedback className="d-block" type="invalid">
                      {this.state.errors['additional_planned_travel_destination_country']}
                    </Form.Control.Feedback>
                  </Form.Group>
                )}
                {!(this.state.current.additional_planned_travel_type && this.state.current.additional_planned_travel_type === 'International') && (
                  <Form.Group as={Col} md="8" controlId="additional_planned_travel_destination_state">
                    <Form.Label className="nav-input-label">
                      DESTINATION STATE{schema?.fields?.additional_planned_travel_destination_state?._exclusive?.required && ' *'}
                    </Form.Label>
                    <Form.Control
                      isInvalid={this.state.errors['additional_planned_travel_destination_state']}
                      as="select"
                      size="lg"
                      className="form-square"
                      placeholder="Please enter state..."
                      value={this.state.current.additional_planned_travel_destination_state || ''}
                      onChange={this.handleChange}>
                      <option></option>
                      {stateOptions.map((state, index) => (
                        <option key={`state-${index}`} value={state.name}>
                          {state.name}
                        </option>
                      ))}
                    </Form.Control>
                    <Form.Control.Feedback className="d-block" type="invalid">
                      {this.state.errors['additional_planned_travel_destination_state']}
                    </Form.Control.Feedback>
                  </Form.Group>
                )}
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="8" controlId="additional_planned_travel_port_of_departure">
                  <Form.Label className="nav-input-label">
                    PORT OF DEPARTURE{schema?.fields?.additional_planned_travel_port_of_departure?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['additional_planned_travel_port_of_departure']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.additional_planned_travel_port_of_departure || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['additional_planned_travel_port_of_departure']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} md="6" controlId="additional_planned_travel_start_date">
                  <Form.Label className="nav-input-label">
                    START DATE{schema?.fields?.additional_planned_travel_start_date?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['additional_planned_travel_start_date']}
                    size="lg"
                    type="date"
                    className="form-square"
                    value={this.state.current.additional_planned_travel_start_date || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['additional_planned_travel_start_date']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} md="6" controlId="additional_planned_travel_end_date">
                  <Form.Label className="nav-input-label">
                    END DATE{schema?.fields?.additional_planned_travel_end_date?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['additional_planned_travel_end_date']}
                    size="lg"
                    type="date"
                    className="form-square"
                    value={this.state.current.additional_planned_travel_end_date || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['additional_planned_travel_end_date']}
                  </Form.Control.Feedback>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2 pb-3">
                <Form.Group as={Col} md="24" controlId="additional_planned_travel_related_notes">
                  <Form.Label className="nav-input-label">
                    ADDITIONAL PLANNED TRAVEL NOTES{schema?.fields?.additional_planned_travel_related_notes?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['additional_planned_travel_related_notes']}
                    as="textarea"
                    rows="5"
                    size="lg"
                    className="form-square"
                    placeholder="enter additional information about monitoree's planned travel (e.g. additional destinations, planned activities/social interactions, etc...)"
                    value={this.state.current.additional_planned_travel_related_notes || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['additional_planned_travel_related_notes']}
                  </Form.Control.Feedback>
                </Form.Group>
              </Form.Row>
            </Form>
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

const schema = yup.object().shape({
  additional_planned_travel_type: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  additional_planned_travel_destination: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  additional_planned_travel_destination_country: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  additional_planned_travel_destination_state: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  additional_planned_travel_port_of_departure: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  additional_planned_travel_start_date: yup.date('Date must correspond to the "mm/dd/yyyy" format.').nullable(),
  additional_planned_travel_end_date: yup
    .date('Date must correspond to the "mm/dd/yyyy" format.')
    .when('additional_planned_travel_start_date', sd => {
      if (sd && sd instanceof Date) {
        return yup.date().min(sd, 'End Date must occur after the Start Date.');
      }
    })
    .nullable(),
  additional_planned_travel_related_notes: yup
    .string()
    .max(2000, 'Max length exceeded, please limit to 2000 characters.')
    .nullable(),
});

AdditionalPlannedTravel.propTypes = {
  currentState: PropTypes.object,
  previous: PropTypes.func,
  setEnrollmentState: PropTypes.func,
  next: PropTypes.func,
  submit: PropTypes.func,
};

export default AdditionalPlannedTravel;
