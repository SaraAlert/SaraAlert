import React from 'react';
import PropTypes, { bool } from 'prop-types';
import { Button, Form, InputGroup, Modal } from 'react-bootstrap';
import Select from 'react-select';
import _ from 'lodash';
import { cursorPointerStyle, bootstrapSelectTheme } from '../../packs/stylesheets/ReactSelectStyling';
import { lockReasonOptions } from '../../data/lockReasonOptions';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faExclamationCircle } from '@fortawesome/free-solid-svg-icons';

const MAX_NOTES_LENGTH = 5000;

class UserModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      email: this.props.initialUserData.email || '',
      sorted_jurisdiction_paths: _.values(this.props.jurisdiction_paths).sort((a, b) => a.localeCompare(b)),
      jurisdiction_path: this.props.initialUserData.jurisdiction_path || this.props.jurisdiction_paths[0],
      roleTitle: this.props.initialUserData.role_title || this.props.roles[0],
      roles: this.props.roles,
      isAPIEnabled: this.props.initialUserData.is_api_enabled || false,
      isLocked: this.props.initialUserData.is_locked || false,
      lockReason: this.props.initialUserData.lock_reason || '',
      autoLockReason: this.props.initialUserData.auto_lock_reason || '',
      activeState: this.props.initialUserData.active_state,
      status: this.props.initialUserData.status,
      notes: this.props.initialUserData.notes || '',
      lockReasonOptions:
        this.props.initialUserData.lock_reason === 'Auto-locked by the System'
          ? lockReasonOptions.concat(['Auto-locked by the System']).sort()
          : lockReasonOptions,
    };
  }

  handleChange = event => {
    this.setState({ [event.target.name]: event?.target?.value || '' });
  };

  handleJurisdictionChange = data => {
    this.setState({ jurisdiction_path: data.value });
  };

  handleRoleChange = data => {
    this.setState({ roleTitle: data.value });
  };

  handleLockedSystemAccessChange = event => {
    const val = event.target.checked;
    this.setState({ isLocked: val });
  };

  handleStatusChange = data => {
    this.setState({ lockReason: data.value });
  };

  handleAPIAccessChange = event => {
    const val = event.target.checked;
    this.setState({ isAPIEnabled: val });
  };

  getStatusValue = () => {
    if (this.state.isLocked) {
      return this.state.lockReason ? { label: this.state.lockReason, value: this.state.lockReason } : { label: 'Not specified', value: 'Not specified' };
    } else {
      return { label: this.state.activeState, value: this.state.activeState };
    }
  };

  render() {
    return (
      <Modal id="user-modal" show={this.props.show} onHide={this.props.onClose} backdrop="static" aria-labelledby="contained-modal-title-vcenter" centered>
        <Modal.Header closeButton>
          <Modal.Title>{this.props.title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Form.Group>
              <Form.Label className="input-label">Email Address</Form.Label>
              <InputGroup>
                <InputGroup.Prepend>
                  <InputGroup.Text id="email-addon">
                    <i className="fas fa-envelope"></i>
                  </InputGroup.Text>
                </InputGroup.Prepend>
                <Form.Control
                  id="email-input"
                  name="email"
                  value={this.state.email ? this.state.email : ''}
                  placeholder="Enter email address"
                  aria-label="Enter email address"
                  aria-describedby="email-addon"
                  onChange={this.handleChange}
                />
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
                    : { label: this.state.jurisdiction_paths[0], value: this.state.jurisdiction_paths[0] }
                }
                options={this.state.sorted_jurisdiction_paths.map(path => {
                  return { label: path, value: path };
                })}
                onChange={this.handleJurisdictionChange}
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
                    : { label: this.state.roles[0], value: this.state.roles[0] }
                }
                options={this.state.roles.map(role => {
                  return { label: role, value: role };
                })}
                onChange={this.handleRoleChange}
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
                    name="system-access"
                    type="switch"
                    checked={this.state.isLocked}
                    label={this.state.isLocked ? 'Locked' : 'Unlocked'}
                    onChange={this.handleLockedSystemAccessChange}
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
                <Select
                  inputId="status-select"
                  id="status"
                  name="status"
                  value={this.getStatusValue()}
                  options={this.state.lockReasonOptions.map(lockReason => {
                    return { label: lockReason, value: lockReason };
                  })}
                  onChange={this.handleStatusChange}
                  styles={cursorPointerStyle}
                  theme={bootstrapSelectTheme}
                  isDisabled={!this.state.isLocked}
                />
              </Form.Group>
            )}
            <Form.Group>
              <Form.Label className="input-label">API Access</Form.Label>
              <Form.Check
                id="access-input"
                name="access"
                type="switch"
                checked={this.state.isAPIEnabled}
                label={this.state.isAPIEnabled ? 'Enabled' : 'Disabled'}
                onChange={this.handleAPIAccessChange}
              />
            </Form.Group>
            <Form.Group controlId="notes">
              <Form.Label className="input-label">Notes</Form.Label>
              <InputGroup>
                <Form.Control
                  name="notes"
                  as="textarea"
                  rows="5"
                  className="form-square"
                  value={this.state.notes}
                  maxLength={MAX_NOTES_LENGTH}
                  onChange={this.handleChange}
                />
              </InputGroup>
              <div className="character-limit-text">{MAX_NOTES_LENGTH - this.state.notes.length} characters remaining</div>
            </Form.Group>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={this.props.onClose}>
            Cancel
          </Button>
          <Button variant="primary" onClick={() => this.props.onSave(this.state)}>
            Save
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

UserModal.propTypes = {
  show: bool,
  title: PropTypes.string,
  type: PropTypes.string,
  initialUserData: PropTypes.object,
  onClose: PropTypes.func,
  onSave: PropTypes.func,
  jurisdiction_paths: PropTypes.array,
  roles: PropTypes.array,
};

export default UserModal;
