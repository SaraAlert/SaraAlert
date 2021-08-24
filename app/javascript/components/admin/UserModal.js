import React from 'react';
import PropTypes, { bool } from 'prop-types';
import { Button, Modal, InputGroup, Form } from 'react-bootstrap';
import Select from 'react-select';
import _ from 'lodash';
import { cursorPointerStyle, bootstrapSelectTheme } from '../../packs/stylesheets/ReactSelectStyling';

const MAX_NOTES_LENGTH = 5000;

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
      notes: this.props.initialUserData.notes || '',
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

  handleLockedStatusChange = event => {
    const val = event.target.checked;
    this.setState({ isLocked: val });
  };

  handleAPIAccessChange = event => {
    const val = event.target.checked;
    this.setState({ isAPIEnabled: val });
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
              <Form.Label>Email Address</Form.Label>
              <InputGroup>
                <InputGroup.Prepend>
                  <InputGroup.Text id="email-addon">
                    <i className="fas fa-envelope"></i>
                  </InputGroup.Text>
                </InputGroup.Prepend>
                <Form.Control
                  id="email-input"
                  name="email"
                  defaultValue={this.props.initialUserData.email ? this.props.initialUserData.email : ''}
                  placeholder="Enter email address"
                  aria-label="Enter email address"
                  aria-describedby="email-addon"
                  onChange={this.handleChange}
                />
              </InputGroup>
            </Form.Group>
            <Form.Group>
              <Form.Label htmlFor="jurisdiction-select">Jurisdiction</Form.Label>
              <Select
                inputId="jurisdiction-select"
                name="jurisdiction"
                defaultValue={
                  this.props.initialUserData.jurisdiction_path
                    ? { label: this.props.initialUserData.jurisdiction_path, value: this.props.initialUserData.jurisdiction_path }
                    : { label: this.props.jurisdiction_paths[0], value: this.props.jurisdiction_paths[0] }
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
              <Form.Label htmlFor="role-select">Role</Form.Label>
              <Select
                inputId="role-select"
                name="role"
                defaultValue={
                  this.props.initialUserData.role_title
                    ? { label: this.props.initialUserData.role_title, value: this.props.initialUserData.jurisdiction_path }
                    : { label: this.props.roles[0], value: this.props.roles[0] }
                }
                options={this.props.roles.map(role => {
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
                <Form.Label>Status</Form.Label>
                <Form.Check
                  id="status-input"
                  name="status"
                  type="switch"
                  checked={this.state.isLocked}
                  label={this.state.isLocked ? 'Locked' : 'Unlocked'}
                  onChange={this.handleLockedStatusChange}
                />
              </Form.Group>
            )}
            <Form.Group>
              <Form.Label>API Access</Form.Label>
              <Form.Check
                id="access-input"
                name="access"
                type="switch"
                checked={this.state.isAPIEnabled}
                label={this.state.isAPIEnabled ? 'Enabled' : 'Disabled'}
                onChange={this.handleAPIAccessChange}
              />
            </Form.Group>
            <Form.Group>
              <Form.Label>Notes</Form.Label>
              <InputGroup>
                <Form.Control
                  id="notes"
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
