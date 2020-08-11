import React from 'react';
import { Form, Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class EmailModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      comment: '',
    };
  }

  handleCommentChange = event => {
    this.setState({ comment: event.target.value });
  };

  render() {
    return (
      <Modal
        data-testid="email_modal"
        show={this.props.show}
        onHide={this.props.onClose}
        backdrop="static"
        aria-labelledby="contained-modal-title-vcenter"
        centered>
        <Modal.Header closeButton>
          <Modal.Title data-testid="email_title">{this.props.title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>Enter the message to send to {this.props.userCount} user(s):</p>
          <Form.Group>
            <Form.Control as="textarea" rows="10" id="comment" onChange={this.handleCommentChange} />
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.onClose}>
            Cancel
          </Button>
          <Button variant="primary btn-square" disabled={!this.state.comment.length} onClick={() => this.props.onSave(this.state)}>
            Send
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

EmailModal.propTypes = {
  show: PropTypes.bool,
  title: PropTypes.string,
  onClose: PropTypes.func,
  onSave: PropTypes.func,
  userCount: PropTypes.number,
};

export default EmailModal;
