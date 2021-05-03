import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card, Col, Row } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import axios from 'axios';

import DeleteDialog from '../../util/DeleteDialog';
import reportError from '../../util/ReportError';
import { formatTimestamp, formatRelativePast } from '../../../utils/DateTime';

class History extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      loading: false,
      editMode: false,
      showDeleteModal: false,
      comment: props.history.comment,
    };
  }

  handleChange = event => {
    this.setState({ [event.target.id]: event.target.value });
  };

  toggleEditMode = () => {
    this.setState({ editMode: true });
  };

  toggleEditMode = () => {
    let current = this.state.editMode;
    this.setState({ editMode: !current, comment: this.props.history.comment });
  };

  handleEditSubmit = () => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/histories/' + this.props.history.id + '/edit', {
          patient_id: this.props.history.patient_id,
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

    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/histories/' + this.props.history.id + '/delete', {
          patient_id: this.props.history.patient_id,
          delete_reason: deleteReason,
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  };

  renderEditMode() {
    return (
      <React.Fragment>
        <textarea
          id="comment"
          name="comment"
          className="form-control"
          aria-label="Edit comment input"
          style={{ resize: 'none' }}
          rows="3"
          value={this.state.comment}
          onChange={this.handleChange}
        />
        <Button
          id="update-edit-history-btn"
          variant="primary"
          size="sm"
          className="float-right mt-2"
          disabled={this.state.loading || this.state.comment === '' || this.state.comment === this.props.history.comment}
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
          <span data-for={`edit-history-item-${this.props.history.id}`} data-tip="">
            <Button id="edit-history-btn" variant="link" className="icon-btn p-0 mr-1" onClick={this.toggleEditMode} aria-label="Edit History Comment">
              <i className="fas fa-edit"></i>
            </Button>
          </span>
          <ReactTooltip id={`edit-history-item-${this.props.history.id}`} place="top" type="dark" effect="solid">
            <span>Edit comment</span>
          </ReactTooltip>
          <span data-for={`delete-history-item-${this.props.history.id}`} data-tip="">
            <Button id="delete-history-btn" variant="link" className="icon-btn p-0" onClick={this.toggleDeleteModal} aria-label="Delete History Comment">
              <i className="fas fa-trash"></i>
            </Button>
          </span>
          <ReactTooltip id={`delete-history-item-${this.props.history.id}`} place="top" type="dark" effect="solid">
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
            <b>{this.props.history.created_by}</b>, {formatRelativePast(this.props.history.created_at)} ({formatTimestamp(this.props.history.created_at)})
            <span className="float-right">
              <div className="badge-padding h5">
                <span className="badge badge-secondary">{this.props.history.history_type}</span>
              </div>
            </span>
          </Card.Header>
          <Card.Body>
            {this.state.editMode ? (
              this.renderEditMode()
            ) : (
              <Row>
                <Col xs="auto">
                  {this.props.history.comment}
                  {this.props.history.edited_at && <i className="edit-text"> (edited)</i>}
                </Col>
                {this.props.history.history_type === 'Comment' && this.props.history.created_by === this.props.current_user.email && this.renderActionButtons()}
              </Row>
            )}
          </Card.Body>
        </Card>
        {this.state.showDeleteModal && (
          <DeleteDialog type={'Comment'} delete={this.handleDeleteSubmit} toggle={this.toggleDeleteModal} onChange={this.handleChange} />
        )}
      </React.Fragment>
    );
  }
}

History.propTypes = {
  history: PropTypes.object,
  current_user: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default History;
