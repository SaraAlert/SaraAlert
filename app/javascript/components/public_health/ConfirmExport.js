import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Modal } from 'react-bootstrap';

class ConfirmExport extends React.Component {
  render() {
    return (
      <Modal size="lg" className="confirm-export-modal-container" show={this.props.show} centered>
        <Modal.Header>
          <Modal.Title>{this.props.title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            After clicking <b>Start Export</b>, Sara Alert will gather all of the monitoree data that comprises your request and generate an export file. Sara
            Alert will then send your user account an email with a one-time download link. This process may take several minutes to complete, based on the
            amount of data present.
          </p>
          <p>
            NOTE: The system will store one of each type of export file. If you initiate another export of this file type, any old files will be overwritten and
            download links that have not been accessed will be invalid. Only one of each export type is allowed per user per hour.
          </p>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.onCancel}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={this.props.onStartExport}>
            Start Export
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

ConfirmExport.propTypes = {
  show: PropTypes.bool,
  title: PropTypes.string,
  onCancel: PropTypes.func,
  onStartExport: PropTypes.func,
};

export default ConfirmExport;
