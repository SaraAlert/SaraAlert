import React from 'react';
import { Form, Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import { toast } from 'react-toastify';
import reportError from '../util/ReportError';

class ReleaseUpdate extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showReleaseUpdateModal: false,
      comment: '',
    };
    this.toggleReleaseUpdateModal = this.toggleReleaseUpdateModal.bind(this);
    this.submit = this.submit.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  toggleReleaseUpdateModal() {
    let current = this.state.showReleaseUpdateModal;
    this.setState({
      showReleaseUpdateModal: !current,
    });
  }

  handleChange(event) {
    this.setState({ [event.target.id]: event.target.value });
  }

  submit() {
    this.setState(
      {
        showReleaseUpdateModal: false,
      },
      () => {
        axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
        axios
          .post(window.BASE_PATH + '/admin/email', {
            comment: this.state.comment,
          })
          .then(() => {
            toast.success('Sent email to all users.', {
              position: toast.POSITION.TOP_CENTER,
            });
          })
          .catch(error => {
            reportError('Failed to send email to all users.');
            console.error(error);
          });
      }
    );
  }

  createModal(title, toggle) {
    return (
      <Modal size="lg" show centered>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>Enter the message to send to all users:</p>
          <Form.Group>
            <Form.Control as="textarea" rows="10" id="comment" onChange={this.handleChange} />
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button
            variant="primary btn-square"
            disabled={!this.state.comment.length}
            onClick={() => {
              if (window.confirm('You are about to send this message to all users (' + this.props.user_count + ' accounts). Are you sure?')) {
                this.submit();
              }
            }}>
            Send
          </Button>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        {this.props.is_usa_admin && (
          <Button variant="secondary" onClick={this.toggleReleaseUpdateModal} className="btn btn-lg mb-3 mt-2" block>
            <i className="fas fa-envelope"></i> Send Email to All Users
          </Button>
        )}
        {this.state.showReleaseUpdateModal && this.props.is_usa_admin && this.createModal('Send Email to All Users', this.toggleReleaseUpdateModal)}
      </React.Fragment>
    );
  }
}

ReleaseUpdate.propTypes = {
  authenticity_token: PropTypes.string,
  user_count: PropTypes.number,
  is_usa_admin: PropTypes.bool,
};

export default ReleaseUpdate;
