import React from 'react';
import { PropTypes } from 'prop-types';
import { Col, Form } from 'react-bootstrap';
import axios from 'axios';
import _ from 'lodash';
import InfoTooltip from '../../util/InfoTooltip';

class PublicHealthManagement extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      current: this.props.currentState,
      errors: {},
      modified: {},
      sorted_jurisdiction_paths: _.values(this.props.jurisdiction_paths).sort((a, b) => a.localeCompare(b)),
      jurisdiction_path: this.props.jurisdiction_paths[this.props.currentState.patient.jurisdiction_id],
      originalJurisdictionId: this.props.currentState.patient.jurisdiction_id,
      assigned_users: this.props.assigned_users,
      originalAssignedUser: this.props.currentState.patient.assigned_user,
    };
  }

  componentDidMount() {
    this.props.updateValidations(this.props.currentState.isolation);
  }

  componentDidUpdate(prevProps) {
    if (prevProps.currentState.isolation !== this.props.currentState.isolation) {
      this.props.updateValidations(this.props.currentState.isolation);
    }
  }

  handleChange = event => {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let modified = this.state.modified;
    if (event?.target?.id && event.target.id === 'jurisdiction_id') {
      this.setState({ jurisdiction_path: event.target.value });
      let jurisdiction_id = parseInt(Object.keys(this.props.jurisdiction_paths).find(id => this.props.jurisdiction_paths[parseInt(id)] === event.target.value));
      if (jurisdiction_id) {
        value = jurisdiction_id;
        axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
        axios
          .post(window.BASE_PATH + '/jurisdictions/assigned_users', {
            query: {
              jurisdiction: jurisdiction_id,
              scope: 'exact',
            },
          })
          .catch(() => {})
          .then(response => {
            if (response?.data?.assigned_users) {
              this.setState({ assigned_users: response.data.assigned_users });
            }
          });
      } else {
        value = -1;
      }
    } else if (event?.target?.id && event.target.id === 'assigned_user') {
      if (isNaN(event.target.value) || parseInt(event.target.value) > 999999) return;

      // trim() call included since there is a bug with yup validation for numbers that allows whitespace entry
      value = event.target.value.trim() === '' ? null : parseInt(event.target.value);
    }
    this.setState(
      {
        current: { ...current, patient: { ...current.patient, [event.target.id]: value } },
        modified: { ...modified, patient: { ...modified.patient, [event.target.id]: value } },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };

  handlePropagatedFieldChange = event => {
    const current = this.state.current;
    const modified = this.state.modified;
    this.setState(
      {
        current: { ...current, propagatedFields: { ...current.propagatedFields, [event.target.name]: event.target.checked } },
        modified: { ...modified, propagatedFields: { ...current.propagatedFields, [event.target.name]: event.target.checked } },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };

  render() {
    return (
      <React.Fragment>
        <Form.Row className="pt-2 g-border-bottom-2" />
        <Form.Row className="pt-2">
          <Form.Group as={Col} className="mb-2">
            <Form.Label className="input-label">PUBLIC HEALTH RISK ASSESSMENT AND MANAGEMENT</Form.Label>
          </Form.Group>
        </Form.Row>
        <Form.Row>
          <Form.Group as={Col} md="18" className="mb-2 pt-2" controlId="jurisdiction_id">
            <Form.Label className="input-label">ASSIGNED JURISDICTION{this.props.schema?.fields?.jurisdiction_id?._exclusive?.required && ' *'}</Form.Label>
            <Form.Control
              isInvalid={this.state.errors['jurisdiction_id']}
              as="input"
              list="jurisdiction_paths"
              autoComplete="off"
              size="lg"
              className="form-square"
              onChange={this.handleChange}
              value={this.state.jurisdiction_path}
            />
            <datalist id="jurisdiction_paths">
              {this.state.sorted_jurisdiction_paths.map((jurisdiction, index) => {
                return (
                  <option value={jurisdiction} key={index}>
                    {jurisdiction}
                  </option>
                );
              })}
            </datalist>
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['jurisdiction_id']}
            </Form.Control.Feedback>
            {this.props.has_dependents &&
              this.state.current.patient.jurisdiction_id !== this.state.originalJurisdictionId &&
              Object.keys(this.props.jurisdiction_paths).includes(this.state.current.patient.jurisdiction_id.toString()) && (
                <Form.Group className="mt-2">
                  <Form.Check
                    type="switch"
                    id="update_group_member_jurisdiction_id"
                    name="jurisdiction_id"
                    label="Apply this change to the entire household that this monitoree is responsible for"
                    onChange={this.handlePropagatedFieldChange}
                    checked={this.state.current.propagatedFields.jurisdiction_id || false}
                  />
                </Form.Group>
              )}
          </Form.Group>
          <Form.Group as={Col} md="6" className="mb-2 pt-2" controlId="assigned_user">
            <Form.Label className="input-label">
              ASSIGNED USER{this.props.schema?.fields?.assigned_user?._exclusive?.required && ' *'}
              <InfoTooltip tooltipTextKey="assignedUser" location="top"></InfoTooltip>
            </Form.Label>
            <Form.Control
              isInvalid={this.state.errors['assigned_user']}
              as="input"
              list="assigned_users"
              autoComplete="off"
              size="lg"
              className="form-square"
              onChange={this.handleChange}
              value={this.state.current.patient.assigned_user || ''}
            />
            <datalist id="assigned_users">
              {this.state.assigned_users?.map(num => {
                return (
                  <option value={num} key={num}>
                    {num}
                  </option>
                );
              })}
            </datalist>
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['assigned_user']}
            </Form.Control.Feedback>
            {this.props.has_dependents &&
              this.state.current.patient.assigned_user !== this.state.originalAssignedUser &&
              (this.state.current.patient.assigned_user === null ||
                (this.state.current.patient.assigned_user > 0 && this.state.current.patient.assigned_user <= 999999)) && (
                <Form.Group className="mt-2">
                  <Form.Check
                    type="switch"
                    id="update_group_member_assigned_user"
                    name="assigned_user"
                    label="Apply this change to the entire household that this monitoree is responsible for"
                    onChange={this.handlePropagatedFieldChange}
                    checked={this.state.current.propagatedFields.assigned_user || false}
                  />
                </Form.Group>
              )}
          </Form.Group>
          <Form.Group as={Col} md="8" controlId="exposure_risk_assessment" className="mb-2 pt-2">
            <Form.Label className="input-label">RISK ASSESSMENT{this.props.schema?.fields?.exposure_risk_assessment?._exclusive?.required && ' *'}</Form.Label>
            <Form.Control
              isInvalid={this.state.errors['exposure_risk_assessment']}
              as="select"
              size="lg"
              className="form-square"
              onChange={this.handleChange}
              value={this.state.current.patient.exposure_risk_assessment || ''}>
              <option></option>
              <option>High</option>
              <option>Medium</option>
              <option>Low</option>
              <option>No Identified Risk</option>
            </Form.Control>
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['exposure_risk_assessment']}
            </Form.Control.Feedback>
          </Form.Group>
          <Form.Group as={Col} md="16" controlId="monitoring_plan" className="mb-2 pt-2">
            <Form.Label className="input-label">MONITORING PLAN{this.props.schema?.fields?.monitoring_plan?._exclusive?.required && ' *'}</Form.Label>
            <Form.Control
              isInvalid={this.state.errors['monitoring_plan']}
              as="select"
              size="lg"
              className="form-square"
              onChange={this.handleChange}
              value={this.state.current.patient.monitoring_plan || ''}>
              <option></option>
              <option>None</option>
              <option>Daily active monitoring</option>
              <option>Self-monitoring with public health supervision</option>
              <option>Self-monitoring with delegated supervision</option>
              <option>Self-observation</option>
            </Form.Control>
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.state.errors['monitoring_plan']}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
      </React.Fragment>
    );
  }
}

PublicHealthManagement.propTypes = {
  currentState: PropTypes.object,
  setEnrollmentState: PropTypes.func,
  updateValidations: PropTypes.func,
  previous: PropTypes.func,
  next: PropTypes.func,
  patient: PropTypes.object,
  has_dependents: PropTypes.bool,
  jurisdiction_paths: PropTypes.object,
  assigned_users: PropTypes.array,
  authenticity_token: PropTypes.string,
  schema: PropTypes.object,
};

export default PublicHealthManagement;
