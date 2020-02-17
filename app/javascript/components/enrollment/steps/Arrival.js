import React from 'react';
import { Card, Button, Form, Col } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import * as yup from 'yup';

class Arrival extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props, current: { ...this.props.currentState }, errors: {} };
    this.handleChange = this.handleChange.bind(this);
    this.validate = this.validate.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    value = (event.target.id === 'date_of_departure' || event.target.id === 'date_of_arrival') && value === '' ? undefined : value;
    this.setState({ current: { ...current, [event.target.id]: value } }, () => {
      this.props.setEnrollmentState({ ...this.state.current });
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
      .catch(function(err) {
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
          <Card.Header as="h5">Subject Arrival Information</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="8" controlId="port_of_origin">
                  <Form.Label className="nav-input-label">PORT OF ORIGIN{schema?.fields?.port_of_origin?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['port_of_origin']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.port_of_origin || ''}
                    onChange={this.handleChange}
                  />
                </Form.Group>
                <Form.Group as={Col} md="6" controlId="date_of_departure">
                  <Form.Label className="nav-input-label">DATE OF DEPARTURE{schema?.fields?.date_of_departure?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['date_of_departure']}
                    size="lg"
                    type="date"
                    className="form-square"
                    value={this.state.current.date_of_departure || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['port_of_origin']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} md="2"></Form.Group>
                <Form.Group as={Col} md="8" controlId="source_of_report">
                  <Form.Label className="nav-input-label">SOURCE OF REPORT{schema?.fields?.source_of_report?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['source_of_report']}
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.source_of_report || ''}
                    onChange={this.handleChange}>
                    <option></option>
                    <option>Self-Identified</option>
                    <option>CDC</option>
                    <option>Other</option>
                  </Form.Control>
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['source_of_report']}
                  </Form.Control.Feedback>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="8" controlId="flight_or_vessel_number">
                  <Form.Label className="nav-input-label">
                    FLIGHT OR VESSEL NUMBER{schema?.fields?.flight_or_vessel_number?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['flight_or_vessel_number']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.flight_or_vessel_number || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['flight_or_vessel_number']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} md="7" controlId="flight_or_vessel_carrier">
                  <Form.Label className="nav-input-label">CARRIER{schema?.fields?.flight_or_vessel_carrier?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['flight_or_vessel_carrier']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.flight_or_vessel_carrier || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['flight_or_vessel_carrier']}
                  </Form.Control.Feedback>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="8" controlId="port_of_entry_into_usa">
                  <Form.Label className="nav-input-label">
                    PORT OF ENTRY INTO USA{schema?.fields?.port_of_entry_into_usa?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['port_of_entry_into_usa']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.port_of_entry_into_usa || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['port_of_entry_into_usa']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} md="6" controlId="date_of_arrival">
                  <Form.Label className="nav-input-label">DATE OF ARRIVAL{schema?.fields?.date_of_arrival?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['date_of_arrival']}
                    size="lg"
                    type="date"
                    className="form-square"
                    value={this.state.current.date_of_arrival || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['date_of_arrival']}
                  </Form.Control.Feedback>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2 pb-3">
                <Form.Group as={Col} md="24" controlId="travel_related_notes">
                  <Form.Label className="nav-input-label">TRAVEL RELATED NOTES{schema?.fields?.travel_related_notes?._exclusive?.required && ' *'}</Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['travel_related_notes']}
                    as="textarea"
                    rows="5"
                    size="lg"
                    className="form-square"
                    placeholder="enter additional information about subject’s travel history (e.g. visited farm, sick relative, original country departed from, etc.)"
                    value={this.state.current.travel_related_notes || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['travel_related_notes']}
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
  port_of_origin: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  date_of_departure: yup
    .date('Date must correspond to the "mm/dd/yyyy" format.')
    .max(new Date(), 'Date can not be in the future.')
    .nullable(),
  source_of_report: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  flight_or_vessel_number: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  flight_or_vessel_carrier: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  port_of_entry_into_usa: yup
    .string()
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  date_of_arrival: yup
    .date('Date must correspond to the "mm/dd/yyyy" format.')
    .max(new Date(), 'Date can not be in the future.')
    .when('date_of_departure', dod => {
      if (dod && dod instanceof Date) {
        return yup.date().min(dod, 'Date of Arrival must occur after the Date of Departure.');
      }
    })
    .nullable(),
  travel_related_notes: yup
    .string()
    .max(2000, 'Max length exceeded, please limit to 2000 characters.')
    .nullable(),
});

Arrival.propTypes = {
  currentState: PropTypes.object,
  previous: PropTypes.func,
  setEnrollmentState: PropTypes.func,
  next: PropTypes.func,
  submit: PropTypes.func,
};

export default Arrival;
