import React from 'react';
import { Button, Modal, Form } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class CaseStatus extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showCaseStatusModal: this.props.active,
      common_case_status: this.getCommonCaseStatus,
      selected_case_status: '',
    };
    this.submit = this.submit.bind(this);
    this.handleCaseStatusChange = this.handleCaseStatusChange.bind(this);
  }

  toggleCaseStatusModal() {
    let current = this.state.showCaseStatusModal;
    this.setState({
      showCaseStatusModal: !current,
      selected_case_status: '',
    });
  }

  getCommonCaseStatus() {
    // TODO
    'Unknown';
  }

  handleCaseStatusChange(event) {
    event.persist();
    console.log(event.target.value);
  }

  submit() {
    console.log('submit');
  }

  createCaseStatusModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>Please select what you would like to do:</p>
          <Form.Control
            as="select"
            className="form-control-lg"
            id="common_case_status"
            onChange={this.handleCaseStatusChange}
            value={this.state.common_case_status}>
            <option></option>
            <option>Confirmed</option>
            <option>Probable</option>
            <option>Suspect</option>
            <option>Unknown</option>
            <option>Not a Case</option>
          </Form.Control>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.common_case_status === '' || this.state.loading}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
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
      <React.Fragment>{this.state.showCaseStatusModal && this.createCaseStatusModal('Case Status', this.toggleCaseStatusModal, this.submit)}</React.Fragment>
    );
  }

  createModal(title, toggle, submit) {
    if (this.state.common_case_status === 'Confirmed' || this.state.common_case_status === 'Probable') {
      return (
        <Modal size="lg" show centered>
          <Modal.Header>
            <Modal.Title>{title}</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <p>Please select what you would like to do:</p>
            <Form.Control as="select" className="form-control-lg" id="confirmed" onChange={this.handleChange} value={this.state.confirmed}>
              <option></option>
              <option>End Monitoring</option>
              <option>Continue Monitoring in Isolation Workflow</option>
            </Form.Control>
            {this.state.confirmed === 'End Monitoring' && (
              <p className="pt-4">The monitoree will be moved into the &quot;Closed&quot; line list, and will no longer be monitored.</p>
            )}
            {this.state.confirmed === 'Continue Monitoring in Isolation Workflow' && (
              <p className="pt-4">The monitoree will be moved to the isolation workflow.</p>
            )}
            {this.props.has_group_members && (
              <Form.Group className="mt-2">
                <Form.Check
                  type="switch"
                  id="apply_to_group"
                  label="Apply this change to the entire household that this monitoree is responsible for"
                  onChange={this.handleChange}
                  checked={this.state.apply_to_group === true || false}
                />
              </Form.Group>
            )}
          </Modal.Body>
          <Modal.Footer>
            <Button variant="primary btn-square" onClick={submit} disabled={this.state.confirmed === '' || this.state.loading}>
              {this.state.loading && (
                <React.Fragment>
                  <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
                </React.Fragment>
              )}
              Submit
            </Button>
            <Button variant="secondary btn-square" onClick={toggle}>
              Cancel
            </Button>
          </Modal.Footer>
        </Modal>
      );
    } else if (
      this.state.common_case_status === 'Suspect' ||
      this.state.common_case_status === 'Unknown' ||
      this.state.common_case_status === 'Not a Case' ||
      this.state.common_case_status === ''
    ) {
      return (
        <Modal size="lg" show centered>
          <Modal.Header>
            <Modal.Title>{title}</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <p>This case will be moved from the PUI to symptomatic, non-reporting, or asymptomatic line list as appropriate to continue exposure monitoring.</p>
            {this.props.has_group_members && (
              <Form.Group className="mt-2">
                <Form.Check
                  type="switch"
                  id="apply_to_group"
                  label="Apply this change to the entire household that this monitoree is responsible for"
                  onChange={this.handleChange}
                  checked={this.state.apply_to_group === true || false}
                />
              </Form.Group>
            )}
          </Modal.Body>
          <Modal.Footer>
            <Button variant="primary btn-square" onClick={submit} disabled={this.state.loading}>
              {this.state.loading && (
                <React.Fragment>
                  <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
                </React.Fragment>
              )}
              Submit
            </Button>
            <Button variant="secondary btn-square" onClick={toggle}>
              Cancel
            </Button>
          </Modal.Footer>
        </Modal>
      );
    }
  }
}

CaseStatus.propTypes = {
  active: PropTypes.bool,
  has_group_members: PropTypes.bool,
};

export default CaseStatus;
