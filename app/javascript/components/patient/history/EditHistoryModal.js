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
                  <div className="text-muted mb-1">
                    {formatRelativePast(version.created_at)} by {version.created_by}
                  </div>
                  <i>{version.comment}</i>
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
