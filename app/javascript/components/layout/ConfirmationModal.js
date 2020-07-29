import React from 'react';
import { Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class ConfirmationModal extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <Modal show={this.props.show} onHide={this.props.onClose} backdrop="static" aria-labelledby="contained-modal-title-vcenter" centered>
        <Modal.Header closeButton>
          <Modal.Title>{this.props.title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>Are you sure you would like to {this.props.actionDescription}?</p>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.onClose}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={() => this.props.onSave(this.state)}>
            Confirm
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

ConfirmationModal.propTypes = {
  show: PropTypes.bool,
  title: PropTypes.string,
  onClose: PropTypes.func,
  onSave: PropTypes.func,
  actionDescription: PropTypes.string,
};

export default ConfirmationModal;
