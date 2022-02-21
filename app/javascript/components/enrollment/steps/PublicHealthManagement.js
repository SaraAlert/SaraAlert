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
      modified: {},
      sorted_jurisdiction_paths: _.values(this.props.jurisdiction_paths).sort((a, b) => a.localeCompare(b)),
      jurisdiction_path: this.props.jurisdiction_paths[this.props.currentState.patient.jurisdiction_id],
      originalJurisdictionId: this.props.currentState.patient.jurisdiction_id,
      originalAssignedUser: this.props.currentState.patient.assigned_user,
    };
  }

  handleChange = event => {
    let field = event?.target?.id;
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let modified = this.state.modified;
    if (field === 'jurisdiction_id') {
      this.setState({ jurisdiction_path: value });
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
    } else if (field && event.target.id === 'assigned_user') {
      if (isNaN(value) || parseInt(value) > 999999) return;

      // trim call included since there is a bug with yup validation for numbers that allows whitespace entry
      value = _.trim(value) === '' ? null : parseInt(value);
    }
    this.setState(
      {
        current: { ...current, patient: { ...current.patient, [field]: value } },
        modified: { ...modified, patient: { ...modified.patient, [field]: value } },
      },
      () => {
        this.props.onChange(value, field);
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
              isInvalid={this.props.errors['jurisdiction_id']}
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
              {this.props.errors['jurisdiction_id']}
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
                    onChange={this.props.onPropagatedFieldChange}
                    checked={this.props.currentState.propagatedFields.jurisdiction_id || false}
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
              isInvalid={this.props.errors['assigned_user']}
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
              {this.props.errors['assigned_user']}
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
                    onChange={this.props.onPropagatedFieldChange}
                    checked={this.props.currentState.propagatedFields.assigned_user || false}
                  />
                </Form.Group>
              )}
          </Form.Group>
          <Form.Group as={Col} md="8" controlId="exposure_risk_assessment" className="mb-2 pt-2">
            <Form.Label className="input-label">
              RISK ASSESSMENT{this.props.schema?.fields?.exposure_risk_assessment?._exclusive?.required && ' *'}
              <InfoTooltip tooltipTextKey={'exposureRiskAssessment'} location="right"></InfoTooltip>
            </Form.Label>
            <Form.Control
              isInvalid={this.props.errors['exposure_risk_assessment']}
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
              {this.props.errors['exposure_risk_assessment']}
            </Form.Control.Feedback>
          </Form.Group>
          <Form.Group as={Col} md="16" controlId="monitoring_plan" className="mb-2 pt-2">
            <Form.Label className="input-label">
              MONITORING PLAN{this.props.schema?.fields?.monitoring_plan?._exclusive?.required && ' *'}
              <InfoTooltip tooltipTextKey={'monitoringPlan'} location="right"></InfoTooltip>
            </Form.Label>
            <Form.Control
              isInvalid={this.props.errors['monitoring_plan']}
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
              {this.props.errors['monitoring_plan']}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
      </React.Fragment>
    );
  }
}

PublicHealthManagement.propTypes = {
  currentState: PropTypes.object,
  onChange: PropTypes.func,
  onPropagatedFieldChange: PropTypes.func,
  patient: PropTypes.object,
  has_dependents: PropTypes.bool,
  jurisdiction_paths: PropTypes.object,
  assigned_users: PropTypes.array,
  schema: PropTypes.object,
  errors: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default PublicHealthManagement;
