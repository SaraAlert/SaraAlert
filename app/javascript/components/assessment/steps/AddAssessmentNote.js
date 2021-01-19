import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Button, Modal } from 'react-bootstrap';
import axios from 'axios';

import reportError from '../../util/ReportError';

class AddAssessmentNote extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showAddAssessmentNoteModal: false,
      comment: '',
      loading: false,
    };
  }

  toggleAddAssessmentNoteModal = () => {
    let current = this.state.showAddAssessmentNoteModal;
    this.setState({
      showAddAssessmentNoteModal: !current,
    });
  };

  handleChange = event => {
    this.setState({ [event.target.id]: event.target.value });
  };

  AddAssessmentNote = () => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/histories', {
          patient_id: this.props.patient.id,
          comment: 'User left a note for a report (ID: ' + this.props.assessment.id + '). Note is: ' + this.state.comment,
          type: 'Report Note',
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  };

  createModal(toggle, submit) {
    return (
      <Modal size="lg" show centered onHide={toggle}>
        <Modal.Header>
          <Modal.Title>Add Note To Report</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>Please enter your note about the report (ID: {this.props.assessment.id}) below.</p>
          <Form.Group>
            <Form.Control as="textarea" rows="2" id="comment" onChange={this.handleChange} aria-label="Enter Assessment Note Text Area" />
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.loading}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Submit
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Button variant="link" onClick={this.toggleAddAssessmentNoteModal} className="dropdown-item">
          <i className="fas fa-comment-medical fa-fw"></i> Add Note
        </Button>
        {this.state.showAddAssessmentNoteModal && this.createModal(this.toggleAddAssessmentNoteModal, this.AddAssessmentNote)}
      </React.Fragment>
    );
  }
}

AddAssessmentNote.propTypes = {
  authenticity_token: PropTypes.string,
  assessment: PropTypes.object,
  patient: PropTypes.object,
};

export default AddAssessmentNote;
