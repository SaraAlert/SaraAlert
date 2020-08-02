import React from 'react';
import PropTypes, { bool } from 'prop-types';
import { Button, Modal, InputGroup, FormControl, Form } from 'react-bootstrap';

class UserModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      email: this.props.initialUserData.email ? this.props.initialUserData.email : '',
      jurisdictionPath: this.props.initialUserData.jurisdiction_path ? this.props.initialUserData.jurisdiction_path : this.props.jurisdictionPaths[0],
      role: this.props.initialUserData.role ? this.props.initialUserData.role : this.props.roles[0],
      is_api_enabled: this.props.initialUserData.is_api_enabled ? this.props.initialUserData.is_api_enabled : false,
      is_locked: this.props.initialUserData.is_locked ? this.props.initialUserData.is_locked : false,
    };
  }

  handleEmailChange = e => {
    const val = e.target.value;
    this.setState({ email: val });
  };

  handleJurisdictionChange = e => {
    const val = e.target.value;
    this.setState({ jurisdictionPath: val });
  };

  handleRoleChange = e => {
    const val = e.target.value;
    this.setState({ role: val });
  };

  handleLockedStatusChange = event => {
    const val = event.target.checked;
    this.setState({ is_locked: val });
  };

  handleAPIAccessChange = event => {
    const val = event.target.checked;
    this.setState({ is_api_enabled: val });
  };

  render() {
    return (
      <Modal show={this.props.show} onHide={this.props.onClose} backdrop="static" aria-labelledby="contained-modal-title-vcenter" centered>
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
              <Form.Control
                as="select"
                onChange={this.handleJurisdictionChange}
                defaultValue={this.props.initialUserData.jurisdiction_path ? this.props.initialUserData.jurisdiction_path : this.props.jurisdictionPaths[0]}>
                {this.props.jurisdictionPaths.map((path, index) => {
                  return <option key={index}>{path}</option>;
                })}
              </Form.Control>
            </Form.Group>
          </Form>
          <Form.Group>
            <Form.Label>Role</Form.Label>
            <Form.Control
              as="select"
              onChange={this.handleRoleChange}
              defaultValue={this.props.initialUserData.role ? this.props.initialUserData.role : this.props.roles[0]}>
              {this.props.roles.map((role, index) => {
                return <option key={index}>{role}</option>;
              })}
            </Form.Control>
          </Form.Group>
          {this.props.type === 'edit' && (
            <Form.Group>
              <Form.Label>Status</Form.Label>
              <Form.Check
                id="statusSwitch"
                type="switch"
                checked={this.state.is_locked}
                label={this.state.is_locked ? 'Locked' : 'Unlocked'}
                onChange={this.handleLockedStatusChange}
              />
            </Form.Group>
          )}
          <Form.Group>
            <Form.Label>API Access</Form.Label>
            <Form.Check
              id="accessSwitch"
              type="switch"
              checked={this.state.is_api_enabled}
              label={this.state.is_api_enabled ? 'Enabled' : 'Disabled'}
              onChange={this.handleAPIAccessChange}
            />
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={this.props.onClose}>
            Close
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
