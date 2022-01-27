import React from 'react';
import PropTypes, { bool } from 'prop-types';
import { Button, Form, InputGroup, Modal } from 'react-bootstrap';
import Select from 'react-select';
import ReactTooltip from 'react-tooltip';
import _ from 'lodash';
import * as yup from 'yup';
import { cursorPointerStyle, bootstrapSelectTheme } from '../../packs/stylesheets/ReactSelectStyling';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faExclamationCircle } from '@fortawesome/free-solid-svg-icons';

const MAX_NOTES_LENGTH = 5000;
const LOCK_REASON_OPTIONS = ['', 'No longer an employee', 'No longer needs access', 'Other'];

class UserModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      email: this.props.initialUserData.email || '',
      sorted_jurisdiction_paths: _.values(this.props.jurisdiction_paths).sort((a, b) => a.localeCompare(b)),
      jurisdiction_path: this.props.initialUserData.jurisdiction_path || this.props.jurisdiction_paths[0],
      roleTitle: this.props.initialUserData.role_title || this.props.roles[0],
      isAPIEnabled: this.props.initialUserData.is_api_enabled || false,
      isLocked: this.props.initialUserData.is_locked || false,
      lockReason: this.props.initialUserData.lock_reason || '',
      autoLockReason: this.props.initialUserData.auto_lock_reason || '',
      activeState: this.props.initialUserData.active_state,
      status: this.props.initialUserData.status,
      notes: this.props.initialUserData.notes || '',
      lockReasonOptions:
        this.props.initialUserData.lock_reason === 'Auto-locked by the System'
          ? LOCK_REASON_OPTIONS.concat(['Auto-locked by the System']).sort()
          : LOCK_REASON_OPTIONS,
      loading: false,
      errors: {},
    };
  }

  handleChange = event => {
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    this.setState({ [event.target.name]: value });
  };

  getStatusValue = () => {
    if (this.state.isLocked) {
      return this.state.lockReason ? { label: this.state.lockReason, value: this.state.lockReason } : { label: '', value: '' };
    } else {
      return { label: this.state.activeState, value: this.state.activeState };
    }
  };

  /**
   * Validates user data and submits if valid, otherwise displays errors in modal
   */
  validate = () => {
    schema
      .validate({ ...this.state }, { abortEarly: false })
      .then(() => {
        this.setState({ loading: true }, () => {
          this.props.onSave(this.state);
        });
      })
      .catch(err => {
        // Validation errors, update state to display to user
        if (err && err.inner) {
          let issues = {};
          for (const issue of err.inner) {
            issues[issue['path']] = issue['errors'];
          }
          this.setState({ errors: issues });
        }
      });
  };

  render() {
    return (
      <Modal id="user-modal" show={this.props.show} onHide={this.props.onClose} backdrop="static" aria-labelledby="contained-modal-title-vcenter" centered>
        <Modal.Header closeButton>
          <Modal.Title>{this.props.title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Form.Group controlId="email-input">
              <Form.Label className="input-label">Email Address{schema?.fields?.email?._exclusive?.required && '*'}</Form.Label>
              <InputGroup>
                <InputGroup.Prepend>
                  <InputGroup.Text id="email-addon">
                    <i className="fas fa-envelope"></i>
                  </InputGroup.Text>
                </InputGroup.Prepend>
                <Form.Control
                  isInvalid={!!this.state.errors['email']}
                  name="email"
                  value={this.state.email || ''}
                  placeholder="Enter email address"
                  aria-label="Enter email address"
                  aria-describedby="email-addon"
                  onChange={this.handleChange}
                />
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['email']}
                </Form.Control.Feedback>
              </InputGroup>
            </Form.Group>
            <Form.Group>
              <Form.Label className="input-label" htmlFor="jurisdiction-select">
                Jurisdiction
              </Form.Label>
              <Select
                inputId="jurisdiction-select"
                name="jurisdiction"
                value={
                  this.state.jurisdiction_path
                    ? { label: this.state.jurisdiction_path, value: this.state.jurisdiction_path }
                    : { label: this.props.jurisdiction_paths[0], value: this.props.jurisdiction_paths[0] }
                }
                options={this.state.sorted_jurisdiction_paths.map(path => {
                  return { label: path, value: path };
                })}
                onChange={data => this.setState({ jurisdiction_path: data.value })}
                placeholder=""
                styles={cursorPointerStyle}
                theme={bootstrapSelectTheme}
              />
            </Form.Group>
            <Form.Group>
              <Form.Label className="input-label" htmlFor="role-select">
                Role
              </Form.Label>
              <Select
                inputId="role-select"
                name="role"
                value={
                  this.state.roleTitle
                    ? { label: this.state.roleTitle, value: this.state.roleTitle }
                    : { label: this.props.roles[0], value: this.props.roles[0] }
                }
                options={this.props.roles.map(role => {
                  return { label: role, value: role };
                })}
                onChange={data => this.setState({ roleTitle: data.value })}
                placeholder=""
                styles={cursorPointerStyle}
                theme={bootstrapSelectTheme}
              />
            </Form.Group>
            {this.props.type === 'edit' && (
              <Form.Group>
                <Form.Label className="input-label">System Access</Form.Label>
                <div style={{ display: 'flex', alignItems: 'center' }}>
                  <Form.Check
                    id="system-access-input"
                    name="isLocked"
                    type="switch"
                    checked={this.state.isLocked}
                    label={this.state.isLocked ? 'Locked' : 'Unlocked'}
                    onChange={this.handleChange}
                  />
                  {this.state.lockReason === 'Auto-locked by the System' && this.state.isLocked && (
                    <div className="locked-warning-text ml-2">
                      <FontAwesomeIcon className="mr-1" icon={faExclamationCircle} />
                      <span>{this.state.autoLockReason}</span>
                    </div>
                  )}
                </div>
              </Form.Group>
            )}
            {this.props.type === 'edit' && (
              <Form.Group>
                <Form.Label className="input-label" htmlFor="status-select">
                  Status
                </Form.Label>
                <span data-for="disabled-status-select" data-tip="">
                  <Select
                    inputId="status-select"
                    name="status"
                    value={this.getStatusValue()}
                    options={this.state.lockReasonOptions.map(lockReason => {
                      return { label: lockReason, value: lockReason };
                    })}
                    onChange={data => this.setState({ lockReason: data.value })}
                    styles={cursorPointerStyle}
                    theme={bootstrapSelectTheme}
                    isDisabled={!this.state.isLocked}
                  />
                </span>
                {!this.state.isLocked && (
                  <ReactTooltip id="disabled-status-select" multiline={true} type="dark" effect="solid" place="bottom" className="tooltip-container">
                    <div>
                      {this.state.activeState === 'Active'
                        ? `Active in the system within the last ${this.props.inactive_user_threshold} days`
                        : `Has not been active in the system for at least ${this.props.inactive_user_threshold} days`}
                    </div>
                  </ReactTooltip>
                )}
              </Form.Group>
            )}
            <Form.Group>
              <Form.Label className="input-label">API Access</Form.Label>
              <Form.Check
                id="access-input"
                name="isAPIEnabled"
                type="switch"
                checked={this.state.isAPIEnabled}
                label={this.state.isAPIEnabled ? 'Enabled' : 'Disabled'}
                onChange={this.handleChange}
              />
            </Form.Group>
            <Form.Group controlId="notes">
              <Form.Label className="input-label">Notes{schema?.fields?.notes?._exclusive?.required && '*'}</Form.Label>
              <InputGroup>
                <Form.Control
                  isInvalid={!!this.state.errors['notes']}
                  name="notes"
                  as="textarea"
                  rows="5"
                  className="form-square"
                  value={this.state.notes}
                  maxLength={MAX_NOTES_LENGTH}
                  onChange={this.handleChange}
                />
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['notes']}
                </Form.Control.Feedback>
              </InputGroup>
              <div className="character-limit-text">{MAX_NOTES_LENGTH - this.state.notes.length} characters remaining</div>
            </Form.Group>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={this.props.onClose}>
            Cancel
          </Button>
          <span data-for="submit-tooltip" data-tip="" className="ml-1">
            <Button variant="primary" disabled={this.state.loading || !this.state.email} onClick={this.validate}>
              {this.state.loading && (
                <React.Fragment>
                  <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
                </React.Fragment>
              )}
              Save
            </Button>
          </span>
          {/* Typically we pair the ReactTooltip up directly next to the mount point. However, due to the disabled attribute on the button */}
          {/* above, this Tooltip should be placed outside the parent component (to prevent unwanted parent opacity settings from being inherited) */}
          {/* This does not impact component functionality at all. */}
          {!this.state.email && (
            <ReactTooltip id="submit-tooltip" place="top" type="dark" effect="solid">
              <span>Please enter an email address.</span>
            </ReactTooltip>
          )}
        </Modal.Footer>
      </Modal>
    );
  }
}

var schema = yup.object().shape({
  email: yup
    .string()
    .required('Please provide an email.')
    .email('Please enter a valid email.')
    .max(200, 'Max length exceeded, please limit to 200 characters.')
    .nullable(),
  notes: yup.string().max(MAX_NOTES_LENGTH, `Max length exceeded, please limit to ${MAX_NOTES_LENGTH} characters.`).nullable(),
});

UserModal.propTypes = {
  show: bool,
  title: PropTypes.string,
  type: PropTypes.string,
  initialUserData: PropTypes.object,
  onClose: PropTypes.func,
  onSave: PropTypes.func,
  jurisdiction_paths: PropTypes.array,
  roles: PropTypes.array,
  inactive_user_threshold: PropTypes.number,
};

export default UserModal;
