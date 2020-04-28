import React from 'react';
import PropTypes from 'prop-types';
import { Modal, Button } from 'react-bootstrap';
import { confirmable, createConfirmation } from 'react-confirm';

class Confirmation extends React.Component {
  render() {
    const { okLabbel = 'OK', cancelLabel = 'Cancel', title, confirmation, show, proceed, enableEscape = true } = this.props;
    return (
      <Modal className="static-modal-container" show={show} onHide={() => proceed(false)} backdrop={enableEscape ? true : 'static'} keyboard={enableEscape}>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>{confirmation}</Modal.Body>
        <Modal.Footer>
          <Button onClick={() => proceed(false)}>{cancelLabel}</Button>
          <Button className="button-l" onClick={() => proceed(true)}>
            {okLabbel}
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

Confirmation.propTypes = {
  okLabbel: PropTypes.string,
  cancelLabel: PropTypes.string,
  title: PropTypes.string,
  confirmation: PropTypes.string,
  show: PropTypes.bool,
  proceed: PropTypes.func, // called when ok button is clicked.
  enableEscape: PropTypes.bool,
};

const defaultConfirmation = createConfirmation(confirmable(Confirmation));

export default function confirm(confirmation, options = {}) {
  return defaultConfirmation({ confirmation, ...options });
}
