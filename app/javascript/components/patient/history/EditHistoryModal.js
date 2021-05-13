import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, ListGroup, Modal } from 'react-bootstrap';
import moment from 'moment';
import { formatRelativePast } from '../../../utils/DateTime';

class EditHistoryModal extends React.Component {
  render() {
    return (
      <Modal size="lg" show centered onHide={this.props.toggle}>
        <Modal.Header closeButton>
          <Modal.Title>Comment History</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <ListGroup>
            {this.props.versions
              .sort((a, b) => {
                return moment.utc(b.created_at).diff(moment.utc(a.created_at));
              })
              .map(version => (
                <ListGroup.Item key={version.id}>
                  <div className="mb-1">{version.comment}</div>
                  <i className="edit-text">
                    {version.created_by} {version.id === version.original_comment_id ? 'created' : 'edited'} {formatRelativePast(version.created_at)}
                  </i>
                </ListGroup.Item>
              ))}
          </ListGroup>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={this.props.toggle}>
            Close
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

EditHistoryModal.propTypes = {
  versions: PropTypes.array,
  toggle: PropTypes.func,
};

export default EditHistoryModal;
