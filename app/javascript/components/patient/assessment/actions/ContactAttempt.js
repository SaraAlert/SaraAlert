import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Button, Modal } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import axios from 'axios';
import reportError from '../../../util/ReportError';
import ApplyToHousehold from '../../household/actions/ApplyToHousehold';

class ContactAttempt extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showContactAttemptModal: false,
      note: '',
      attempt: 'Successful',
      loading: false,
      apply_to_household: false,
      apply_to_household_ids: [],
    };
  }

  toggleContactAttemptModal = () => {
    let current = this.state.showContactAttemptModal;
    this.setState({
      showContactAttemptModal: !current,
      apply_to_household: false,
      apply_to_household_ids: [],
    });
  };

  handleChange = event => {
    this.setState({ [event.target.id]: event.target.value });
  };

  handleApplyHouseholdChange = apply_to_household => {
    this.setState({ apply_to_household, apply_to_household_ids: [] });
  };

  handleApplyHouseholdIdsChange = apply_to_household_ids => {
    this.setState({ apply_to_household_ids });
  };

  submit = () => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/contact_attempts', {
          patient_id: this.props.patient.id,
          successful: this.state.attempt === 'Successful',
          note: this.state.note,
          comment: this.state.attempt + ' contact attempt.' + (this.state.comment ? ' Note: ' + this.state.comment : ''),
          apply_to_household: this.state.apply_to_household,
          apply_to_household_ids: this.state.apply_to_household_ids,
        })
        .then(() => {
          location.reload();
        })
        .catch(error => {
          reportError(error);
        });
    });
  };

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered onHide={toggle}>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form.Group controlId="attempt">
            <Form.Label>Contact was:</Form.Label>
            <Form.Control as="select" size="lg" className="form-square" onChange={this.handleChange}>
              <option>Successful</option>
              <option>Unsuccessful</option>
            </Form.Control>
          </Form.Group>
          {this.props.household_members.length > 0 && (
            <ApplyToHousehold
              household_members={this.props.household_members}
              current_user={this.props.current_user}
              jurisdiction_paths={this.props.jurisdiction_paths}
              handleApplyHouseholdChange={this.handleApplyHouseholdChange}
              handleApplyHouseholdIdsChange={this.handleApplyHouseholdIdsChange}
              workflow={this.props.workflow}
            />
          )}
          <p>Please include any additional details:</p>
          <Form.Group>
            <Form.Control as="textarea" rows="2" id="note" onChange={this.handleChange} aria-label="Additional Details Text Area" />
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
          <Button
            variant="primary btn-square"
            onClick={submit}
            disabled={this.state.loading || (this.state.apply_to_household && this.state.apply_to_household_ids.length === 0)}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            <span data-for="contact-attempt-submit" data-tip="">
              Submit
            </span>
            {this.state.apply_to_household && this.state.apply_to_household_ids.length === 0 && (
              <ReactTooltip id="contact-attempt-submit" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
                <div>Please select at least one household member or change your selection to apply to this monitoree only</div>
              </ReactTooltip>
            )}
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Button onClick={this.toggleContactAttemptModal}>
          <i className="fas fa-phone"></i> Log Manual Contact Attempt
        </Button>
        {this.state.showContactAttemptModal && this.createModal('Contact Attempt', this.toggleContactAttemptModal, this.submit)}
      </React.Fragment>
    );
  }
}

ContactAttempt.propTypes = {
  authenticity_token: PropTypes.string,
  patient: PropTypes.object,
  household_members: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  workflow: PropTypes.string,
};

export default ContactAttempt;
