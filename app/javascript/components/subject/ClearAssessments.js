import React from 'react';
import { Form, Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';

class ClearAssessments extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showClearAssessmentsModal: false,
    };
    this.toggleClearAssessmentsModal = this.toggleClearAssessmentsModal.bind(this);
    this.clearAssessments = this.clearAssessments.bind(this);
  }

  toggleClearAssessmentsModal() {
    let current = this.state.showClearAssessmentsModal;
    this.setState({
      showClearAssessmentsModal: !current,
    });
  }

  clearAssessments() {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post('/patients/' + this.props.patient.id + '/status/clear', {
        reasoning: this.state.reasoning,
      })
      .then(() => {
        location.href = '/patients/' + this.props.patient.id;
      })
      .catch(error => {
        console.log(error);
      });
  }

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            You are about to clear all reports for this subject. This will mark any &quot;Needs Review&quot; reports as &quot;No&quot;. This subject will be
            considered asymptomatic.
          </p>
          <Form.Group>
            <Form.Label>Please describe your reasoning:</Form.Label>
            <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleChange} />
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="primary btn-square" onClick={submit}>
            Submit
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
        <Button onClick={this.toggleClearAssessmentsModal} className="btn-lg btn-square">
          Clear All Reports
        </Button>
        {this.state.showClearAssessmentsModal && this.createModal('Clear All Reports', this.toggleClearAssessmentsModal, this.clearAssessments)}
      </React.Fragment>
    );
  }
}

ClearAssessments.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.array,
  jurisdiction_id: PropTypes.number,
};

export default ClearAssessments;
