import React from 'react';
import { Card, Button, Form, Col } from 'react-bootstrap';
import { countryOptions } from '../../data';
import { PropTypes } from 'prop-types';
import * as yup from 'yup';

class Exposure extends React.Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props, current: { ...this.props.currentState }, errors: {} };
    this.handleChange = this.handleChange.bind(this);
    this.validate = this.validate.bind(this);
  }

  handleChange(event) {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
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
          <Card.Header as="h5">Subject Potential Exposure Information</Card.Header>
          <Card.Body>
            <Form>
              <Form.Row className="pt-2">
                <Form.Group as={Col} md="7" controlId="last_date_of_potential_exposure">
                  <Form.Label className="nav-input-label">
                    EXPOSURE DATE{schema?.fields?.last_date_of_potential_exposure?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['last_date_of_potential_exposure']}
                    size="lg"
                    type="date"
                    className="form-square"
                    value={this.state.current.last_date_of_potential_exposure || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['last_date_of_potential_exposure']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} md="10" controlId="potential_exposure_location">
                  <Form.Label className="nav-input-label">
                    EXPOSURE LOCATION{schema?.fields?.potential_exposure_location?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['potential_exposure_location']}
                    size="lg"
                    className="form-square"
                    value={this.state.current.potential_exposure_location || ''}
                    onChange={this.handleChange}
                  />
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['potential_exposure_location']}
                  </Form.Control.Feedback>
                </Form.Group>
                <Form.Group as={Col} md="7" controlId="potential_exposure_country">
                  <Form.Label className="nav-input-label">
                    EXPOSURE COUNTRY{schema?.fields?.potential_exposure_country?._exclusive?.required && ' *'}
                  </Form.Label>
                  <Form.Control
                    isInvalid={this.state.errors['potential_exposure_country']}
                    as="select"
                    size="lg"
                    className="form-square"
                    value={this.state.current.potential_exposure_country || ''}
                    onChange={this.handleChange}>
                    <option></option>
                    {countryOptions.map((country, index) => (
                      <option key={`country-${index}`}>{country}</option>
                    ))}
                  </Form.Control>
                  <Form.Control.Feedback className="d-block" type="invalid">
                    {this.state.errors['potential_exposure_country']}
                  </Form.Control.Feedback>
                </Form.Group>
              </Form.Row>
              <Form.Row className="pt-2 pb-4 h-100">
                <Form.Group as={Col} className="my-auto">
                  <Form.Label className="nav-input-label">EXPOSURE RISK FACTORS</Form.Label>
                  <Form.Row>
                    <Form.Group as={Col} md="auto" className="mb-0 my-auto">
                      <Form.Check
                        type="switch"
                        id="contact_of_known_case"
                        label="CONTACT OF KNOWN CASE"
                        checked={this.state.current.contact_of_known_case === true || false}
                        onChange={this.handleChange}
                      />
                    </Form.Group>
                    <Form.Group as={Col} md="auto" className="mb-0 my-auto ml-4">
                      <Form.Control
                        size="sm"
                        className="form-square"
                        id="contact_of_known_case_id"
                        placeholder="enter case ID"
                        value={this.state.current.contact_of_known_case_id || ''}
                        onChange={this.handleChange}
                      />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row>
                    <Form.Group as={Col} md="auto" className="mb-0 my-auto">
                      <Form.Check
                        className="pt-2 my-auto"
                        type="switch"
                        id="healthcare_worker"
                        label="HEALTHCARE WORKER"
                        checked={this.state.current.healthcare_worker === true || false}
                        onChange={this.handleChange}
                      />
                    </Form.Group>
                  </Form.Row>
                  <Form.Row>
                    <Form.Group as={Col} md="auto" className="mb-0 my-auto">
                      <Form.Check
                        className="pt-2 my-auto"
                        type="switch"
                        id="worked_in_health_care_facility"
                        label="WORKED IN HEALTH CARE FACILITY"
                        checked={this.state.current.worked_in_health_care_facility === true || false}
                        onChange={this.handleChange}
                      />
                    </Form.Group>
                  </Form.Row>
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
  last_date_of_potential_exposure: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
  potential_exposure_location: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
  potential_exposure_country: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
  contact_of_known_case: yup.boolean(),
  contact_of_known_case_id: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.'),
  healthcare_worker: yup.boolean(),
  worked_in_health_care_facility: yup.boolean(),
});

Exposure.propTypes = {
  currentState: PropTypes.object,
  previous: PropTypes.func,
  setEnrollmentState: PropTypes.func,
  next: PropTypes.func,
  submit: PropTypes.func,
};

export default Exposure;
