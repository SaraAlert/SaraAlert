import React from 'react';
import PropTypes, { bool } from 'prop-types';
import { Button, Modal, InputGroup, FormControl, Form, ToggleButtonGroup, ToggleButton } from 'react-bootstrap';

class UserModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      email: this.props.initialUserData.email ? this.props.initialUserData.email : '',
      jurisdictionPath: this.props.initialUserData.jurisdiction_path ? this.props.initialUserData.jurisdiction_path : this.props.jurisdictionPaths[0],
      role: this.props.initialUserData.role ? this.props.initialUserData.role : this.props.roles[0],
    };
  }

  handleEmailChange = e => {
    this.setState({ email: e.target.value });
  };

  handleJurisdictionChange = e => {
    this.setState({ jurisdictionPath: e.target.value });
  };

  handleRoleChange = e => {
    this.setState({ role: e.target.value });
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
          <Form.Group>
            <Form.Label>Status</Form.Label>
            <Form.Row>
              <ToggleButtonGroup type="radio" name="statusToggleGroup" defaultValue={this.props.initialUserData.is_locked ? true : false}>
                {[
                  { name: 'Locked', value: true },
                  { name: 'Unlocked', value: false },
                ].map((option, index) => {
                  const iconClassName = option.value ? 'fas fa-lock' : 'fas fa-unlock-alt';
                  return (
                    <ToggleButton key={index} value={option.value}>
                      <i className={iconClassName}></i>&nbsp;{option.name}
                    </ToggleButton>
                  );
                })}
              </ToggleButtonGroup>
            </Form.Row>
          </Form.Group>
          <Form.Group>
            <Form.Label>API Access</Form.Label>
            <Form.Row>
              <ToggleButtonGroup type="radio" name="statusToggleGroup" defaultValue={this.props.initialUserData.is_locked ? true : false}>
                {[
                  { name: 'Enabled', value: true },
                  { name: 'Disabled', value: false },
                ].map((option, index) => {
                  return (
                    <ToggleButton key={index} value={option.value}>
                      {option.name}
                    </ToggleButton>
                  );
                })}
              </ToggleButtonGroup>
            </Form.Row>
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
  onClose: PropTypes.func,
  onSave: PropTypes.func,
  title: PropTypes.string,
  jurisdictionPaths: PropTypes.array,
  roles: PropTypes.array,
  initialUserData: PropTypes.object,
};

export default UserModal;
