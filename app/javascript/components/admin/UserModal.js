import React from 'react';
import PropTypes, { bool } from 'prop-types';
import { Button, Modal, InputGroup, FormControl, Form, ToggleButtonGroup, ToggleButton } from 'react-bootstrap';

class UserModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      data: {
        email: '',
        jurisdiction: '',
        role: '',
        status: 0,
        twoFactorAuthEnabled: false,
      },
      statusOptions: [
        { name: 'Locked', value: 1 },
        { name: 'Unlocked', value: 0 },
      ],
    };
  }
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
                <FormControl placeholder="Enter email address" aria-label="Enter email address" aria-describedby="email-addon" />
              </InputGroup>
            </Form.Group>
            <Form.Group>
              <Form.Label>Jurisdiction</Form.Label>
              <Form.Control as="select">
                {this.props.jurisdictionPaths.map((path, index) => {
                  const isSelected = path.toLowerCase() === this.props.userData.jurisdiction.toLowerCase();
                  return (
                    <option selected={isSelected} key={index}>
                      {path}
                    </option>
                  );
                })}
              </Form.Control>
            </Form.Group>
          </Form>
          <Form.Group>
            <Form.Label>Role</Form.Label>
            <Form.Control as="select">
              {this.props.roles.map((role, index) => {
                const isSelected = role.toLowerCase() === this.props.userData.role.toLowerCase();
                return (
                  <option selected={isSelected} key={index}>
                    {role}
                  </option>
                );
              })}
            </Form.Control>
          </Form.Group>
          <Form.Group>
            <Form.Label>Status</Form.Label>
            <ToggleButtonGroup type="radio" name="statusToggleGroup" defaultValue={this.props.userData.status}>
              {this.state.statusOptions.map((option, index) => (
                <ToggleButton key={index} value={option.value}>
                  {option.name}
                </ToggleButton>
              ))}
            </ToggleButtonGroup>
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={this.props.onClose}>
            Close
          </Button>
          <Button variant="primary" onClick={this.props.onSave}>
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
  userData: PropTypes.object,
};

export default UserModal;
