import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card, Col, Form, Row } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import axios from 'axios';
import _ from 'lodash';

import DeleteDialog from '../../util/DeleteDialog';
import EditHistoryModal from './EditHistoryModal';
import reportError from '../../util/ReportError';
import { formatTimestamp, formatRelativePast } from '../../../utils/DateTime';

const MAX_COMMENT_LENGTH = 10000;

class History extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      loading: false,
      editMode: false,
      showEditHistoryModal: false,
      showDeleteModal: false,
      original_version: _.first(props.versions),
      latest_version: _.last(props.versions),
      comment: _.last(props.versions).comment,
    };
  }

  handleChange = event => {
    this.setState({ [event.target.id]: event.target.value });
  };

  toggleEditMode = () => {
    let current = this.state.editMode;
    this.setState({ editMode: !current, comment: this.state.latest_version.comment });
  };

  handleEditSubmit = () => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/histories/' + this.state.latest_version.id + '/edit', {
          patient_id: this.state.latest_version.patient_id,
          comment: this.state.comment,
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  };

  toggleDeleteModal = () => {
    let current = this.state.showDeleteModal;
    this.setState({
      showDeleteModal: !current,
      delete_reason: null,
      delete_reason_text: null,
    });
  };

  handleDeleteSubmit = () => {
    let deleteReason = this.state.delete_reason;
    if (deleteReason === 'Other' && this.state.delete_reason_text) {
      deleteReason += ': ' + this.state.delete_reason_text;
    }

    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(window.BASE_PATH + '/histories/' + this.state.latest_version.id + '/delete', {
        patient_id: this.state.latest_version.patient_id,
        delete_reason: deleteReason,
      })
      .then(() => {
        location.reload(true);
      })
      .catch(error => {
        reportError(error);
      });
  };

  renderEditedButton() {
    return (
      <React.Fragment>
        <span data-for={`view-edit-history-item-${this.state.original_version.id}`} data-tip="">
          <Button
            variant="link"
            className="history-edited-link p-0 ml-1"
            onClick={() => {
              this.setState({ showEditHistoryModal: true });
            }}>
            <i className="edit-text">(edited)</i>
          </Button>
        </span>
        <ReactTooltip id={`view-edit-history-item-${this.state.original_version.id}`} place="bottom" type="dark" effect="solid">
          <span>Click to view full edit history of comment</span>
        </ReactTooltip>
      </React.Fragment>
    );
  }

  renderEditMode() {
    return (
      <React.Fragment>
        <Form.Control
          id="comment"
          as="textarea"
          className="form-control"
          aria-label="Edit comment input"
          rows="3"
          maxLength={MAX_COMMENT_LENGTH}
          value={this.state.comment}
          onChange={this.handleChange}
        />
        <div className="character-limit-text">{MAX_COMMENT_LENGTH - this.state.comment.length} characters remaining</div>
        <Button
          id="update-edit-history-btn"
          variant="primary"
          size="sm"
          className="float-right mt-2"
          disabled={this.state.loading || this.state.comment === '' || this.state.comment === this.state.latest_version.comment}
          onClick={this.handleEditSubmit}
          aria-label="Submit Edit History Comment">
          Update
        </Button>
        <Button
          id="cancel-edit-history-btn"
          variant="primary"
          size="sm"
          className="float-right mt-2 mr-2"
          disabled={this.state.loading}
          onClick={this.toggleEditMode}
          aria-label="Cancel Edit History Comment">
          Cancel
        </Button>
      </React.Fragment>
    );
  }

  renderActionButtons() {
    return (
      <Col>
        <div className="float-right" style={{ width: '45px' }}>
          <span data-for={`edit-history-item-${this.state.latest_version.id}`} data-tip="">
            <Button id="edit-history-btn" variant="link" className="icon-btn p-0 mr-1" onClick={this.toggleEditMode} aria-label="Edit History Comment">
              <i className="fas fa-edit"></i>
            </Button>
          </span>
          <ReactTooltip id={`edit-history-item-${this.state.latest_version.id}`} place="top" type="dark" effect="solid">
            <span>Edit comment</span>
          </ReactTooltip>
          <span data-for={`delete-history-item-${this.state.latest_version.id}`} data-tip="">
            <Button id="delete-history-btn" variant="link" className="icon-btn p-0" onClick={this.toggleDeleteModal} aria-label="Delete History Comment">
              <i className="fas fa-trash"></i>
            </Button>
          </span>
          <ReactTooltip id={`delete-history-item-${this.state.latest_version.id}`} place="top" type="dark" effect="solid">
            <span>Delete comment</span>
          </ReactTooltip>
        </div>
      </Col>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square mt-4 mx-3 shadow-sm">
          <Card.Header>
            <b>{this.state.original_version.created_by}</b>, {formatRelativePast(this.state.original_version.created_at)} (
            {formatTimestamp(this.state.original_version.created_at)})
            <span className="float-right">
              <div className="badge-padding h5">
                <span className="badge badge-secondary">{this.state.original_version.history_type}</span>
              </div>
            </span>
          </Card.Header>
          <Card.Body>
            {this.state.editMode ? (
              this.renderEditMode()
            ) : (
              <Row>
                <Col xs="auto">
                  {this.state.comment}
                  {this.state.latest_version.id !== this.state.original_version.id && this.renderEditedButton()}
                </Col>
                {this.state.original_version.history_type === 'Comment' &&
                  this.state.original_version.created_by === this.props.current_user.email &&
                  this.renderActionButtons()}
              </Row>
            )}
          </Card.Body>
        </Card>
        {this.state.showEditHistoryModal && (
          <EditHistoryModal
            versions={this.props.versions}
            toggle={() => {
              this.setState({ showEditHistoryModal: false });
            }}
          />
        )}
        {this.state.showDeleteModal && (
          <DeleteDialog type={'Comment'} delete={this.handleDeleteSubmit} toggle={this.toggleDeleteModal} onChange={this.handleChange} />
        )}
      </React.Fragment>
    );
  }
}

History.propTypes = {
  versions: PropTypes.array,
  current_user: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default History;
