import React from 'react';
import PropTypes, { bool } from 'prop-types';
import { Button, Modal, InputGroup, FormControl, Form } from 'react-bootstrap';
import Select from 'react-select';

class UserModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      email: this.props.initialUserData.email ? this.props.initialUserData.email : '',
      jurisdictionPath: this.props.initialUserData.jurisdiction_path ? this.props.initialUserData.jurisdiction_path : this.props.jurisdictionPaths[0],
      roleTitle: this.props.initialUserData.role_title ? this.props.initialUserData.role_title : this.props.roles[0],
      isAPIEnabled: this.props.initialUserData.is_api_enabled ? this.props.initialUserData.is_api_enabled : false,
      isLocked: this.props.initialUserData.is_locked ? this.props.initialUserData.is_locked : false,
    };
  }

  handleEmailChange = e => {
    const val = e.target.value;
    this.setState({ email: val });
  };

  handleJurisdictionChange = data => {
    this.setState({ jurisdictionPath: data.value });
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
                <FormControl
                  id="email-input"
                  name="email"
                  defaultValue={this.props.initialUserData.email ? this.props.initialUserData.email : ''}
                  placeholder="Enter email address"
                  aria-label="Enter email address"
                  aria-describedby="email-addon"
                  onChange={this.handleEmailChange}
                />
              </InputGroup>
            </Form.Group>
            <Form.Group>
              <Form.Label>Jurisdiction</Form.Label>
              <Select
                name="jurisdiction"
                defaultValue={
                  this.props.initialUserData.jurisdiction_path
                    ? { label: this.props.initialUserData.jurisdiction_path, value: this.props.initialUserData.jurisdiction_path }
                    : { label: this.props.jurisdictionPaths[0], value: this.props.jurisdictionPaths[0] }
                }
                options={this.props.jurisdictionPaths.map(path => {
                  return { label: path, value: path };
                })}
                onChange={this.handleJurisdictionChange}
                placeholder=""
                theme={theme => ({
                  ...theme,
                  borderRadius: 0,
                })}
              />
            </Form.Group>
            <Form.Group>
              <Form.Label>Role</Form.Label>
              <Select
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
                theme={theme => ({
                  ...theme,
                  borderRadius: 0,
                })}
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
  jurisdictionPaths: PropTypes.array,
  roles: PropTypes.array,
};

export default UserModal;
