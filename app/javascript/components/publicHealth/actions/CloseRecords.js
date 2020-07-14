import React from 'react';
import { Button, Form, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import reportError from '../../util/ReportError';

class CloseRecords extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      applyToGroup: false,
      loading: false,
    };
    this.handleChange = this.handleChange.bind(this);
    this.submit = this.submit.bind(this);
  }

  handleChange(event) {
    if (event.target.type === 'checkbox') {
      this.setState({ [event.target.id]: event.target.checked });
    }
  }

  submit() {
    let idArray = this.props.patients.map(x => x['id']);

    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/bulk_edit/status', {
          ids: idArray,
          comment: true,
          message: 'monitoring status to "Not Monitoring".',
          monitoring: false,
          apply_to_group: this.state.applyToGroup,
        })
        .then(() => {
          location.href = window.BASE_PATH;
        })
        .catch(error => {
          reportError(error);
          this.setState({ loading: false });
        });
    });
  }

  render() {
    return (
      <React.Fragment>
        <Modal.Body>
          <p>You are about to change the Monitoring Status of the selected records from &quot;Actively Monitoring&quot; to &quot;Not Monitoring&quot;.</p>
          <p>These records will be moved to the closed line list and the reason for closure will be blank.</p>
          <Form.Group className="my-2">
            <Form.Check
              type="switch"
              id="applyToGroup"
              label="Apply this change to the entire household that these monitorees are responsible for, if it applies"
              checked={this.state.applyToGroup === true || false}
              onChange={this.handleChange}
            />
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.close}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={this.submit}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Submit
          </Button>
        </Modal.Footer>
      </React.Fragment>
    );
  }
}

CloseRecords.propTypes = {
  authenticity_token: PropTypes.string,
  patients: PropTypes.array,
  close: PropTypes.func,
};

export default CloseRecords;
