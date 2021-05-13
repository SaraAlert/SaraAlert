import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Form, Modal } from 'react-bootstrap';

const MAX_REASON_LENGTH = 200;

class DeleteDialog extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      loading: false,
      disabled: true,
      showTextInput: false,
      delete_reason_text: ''
    };
  }

  handleReasonChange = event => {
    event.persist();
    const showTextInput = event.target.value === 'Other';
    this.setState({ disabled: false, showTextInput, [event.target.id]: event.target.value }, () => {
      this.props.onChange(event);
    });
  };

  handleTextChange = event => {
    event.persist();
    this.setState({ [event.target.id]: event.target.value }, () => {
      this.props.onChange(event);
    });
  };

  delete = () => {
    this.setState({ loading: true }, () => {
      this.props.delete();
    });
  };

  render() {
    return (
      <Modal size="lg" show centered onHide={this.props.toggle}>
        <Modal.Header closeButton>
          <Modal.Title>Delete {this.props.type}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            Are you sure you want to delete this {this.props.type}? This action cannot be undone. For auditing purposes, this deletion will be available in this
            record&apos;s history export.
          </p>
          <p>Please select reason for deletion:</p>
          <Form.Control as="select" className="form-control-md mb-3" id="delete_reason" onChange={this.handleReasonChange} defaultValue={-1}>
            <option disabled value={-1}>
              --
            </option>
            <option>Duplicate entry</option>
            <option>Entered in error</option>
            <option>Other</option>
          </Form.Control>
          {this.state.showTextInput && (
            <React.Fragment>
              <Form.Control
                id="delete_reason_text"
                as="textarea"
                rows="2"
                maxLength={MAX_REASON_LENGTH}
                className="form-square"
                placeholder="Please enter additional information about the reason for deletion"
                value={this.state.delete_reason_text}
                onChange={this.handleTextChange}
              />
              <div className="character-limit-text">{MAX_REASON_LENGTH - this.state.delete_reason_text.length} characters remaining</div>
            </React.Fragment>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={this.props.toggle}>
            Cancel
          </Button>
          <Button variant="danger" onClick={this.delete} disabled={this.state.disabled || this.state.loading}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Delete
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

DeleteDialog.propTypes = {
  type: PropTypes.string,
  delete: PropTypes.func,
  toggle: PropTypes.func,
  onChange: PropTypes.func,
};

export default DeleteDialog;
