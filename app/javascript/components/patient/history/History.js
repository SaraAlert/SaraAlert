import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card, Col, Row } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import axios from 'axios';
import reportError from '../../util/ReportError';
import confirmDialog from '../../util/ConfirmDialog';
import { formatTimestamp, formatRelativePast } from '../../../utils/DateTime';

class History extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      editMode: false,
      loading: false,
      comment: props.history.comment,
    };
  }

  handleChange = event => {
    this.setState({ [event.target.id]: event.target.value });
  };

  handleEditClick = () => {
    this.setState({ editMode: true });
  };

  handleEditCancel = () => {
    this.setState({ editMode: false, comment: this.props.history.comment });
  };

  handleEditSubmit = () => {
    console.log('submitting edit...')
      //   this.setState({ loading: true }, () => {
  //     axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
  //     axios
  //       .patch(window.BASE_PATH + '/histories/' + this.props.history.id, {
  //         comment: this.state.comment,
  //       })
  //       .then(() => {
  //         location.reload(true);
  //       })
  //       .catch(error => {
  //         reportError(error);
  //       });
  //   });
  };


  handleArchiveClick = async() => {
    const confirmText = 'Are you sure you would like to archive this comment? This action cannot be undone.'; // CHANGE ME??
    const options = {
      title: 'History',
      okLabel: 'Archive',
      okVariant: 'danger',
      cancelLabel: 'Cancel',
    };
    if (await confirmDialog(confirmText, options)) {
      this.handleArchiveSubmit();
    }
  };

  handleArchiveSubmit = () => {
    console.log('submitting archive...')
    // this.setState({ loading: true }, () => {
    //   axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    //   axios
    //     .delete(window.BASE_PATH + '/histories/' + this.props.history.id)
    //     .then(() => {
    //       location.reload(true);
    //     })
    //     .catch(error => {
    //       reportError(error);
    //     });
    // });
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
          onClick={this.handleEditCancel}
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
            <Button id="edit-history-btn" variant="link" className="icon-btn p-0 mr-1" onClick={this.handleEditClick} aria-label="Edit History Comment">
              <i className="fas fa-edit"></i>
            </Button>
          </span>
          <ReactTooltip
            id={`edit-history-item-${this.props.history.id}`}
            place="top"
            type="dark"
            effect="solid">
            <span>Edit comment</span>
          </ReactTooltip>
          <span data-for={`archive-history-item-${this.props.history.id}`} data-tip="">
            <Button id="delete-history-btn" variant="link" className="icon-btn p-0" onClick={this.handleArchiveClick} aria-label="Archive History Comment">
              <i className="fas fa-archive"></i>
            </Button>
          </span>
          <ReactTooltip
            id={`archive-history-item-${this.props.history.id}`}
            place="top"
            type="dark"
            effect="solid">
            <span>Archive comment</span>
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
                <Col md="auto">
                  {this.props.history.comment}
                  {/* {!!this.props.history.was_edited && <i className="edit-text"> (edited)</i>} */}
                </Col>
                {this.props.history.history_type == 'Comment' && this.renderActionButtons()}
              </Row>
            )}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

History.propTypes = {
  history: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default History;
