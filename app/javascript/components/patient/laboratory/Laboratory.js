import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Dropdown, Form, Modal } from 'react-bootstrap';
import axios from 'axios';
import { toast } from 'react-toastify';
import ReactTooltip from 'react-tooltip';
import LaboratoryModal from './LaboratoryModal';
import reportError from '../../util/ReportError';

class Laboratory extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showModal: false,
      showDeleteModal: false,
      noReasonSelected: true,
      selectedReason: '',
      loading: false,
    };
  }

  createDeleteModal(toggle, submit) {
    return (
      <Modal size="lg" show centered onHide={toggle}>
        <Modal.Header>
          <Modal.Title>Delete Lab result</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form.Group>
            <Form.Label>Please Select The Reason Why You Need To Delete This Lab Result</Form.Label>
            <Form.Control
              as="select"
              size="lg"
              className="form-square"
              onChange={() => this.setState({ noReasonSelected: false, selectedReason: event.target.value })}>
              <option disabled selected>
                {' '}
                -- Select a Reason --{' '}
              </option>
              <option>Duplicate Entry</option>
              <option>Wrong Entry</option>
              <option>Other</option>
            </Form.Control>
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.loading || this.state.noReasonSelected}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            <span data-for="lab-result-delete" data-tip="">
              Delete
            </span>
            {this.state.noReasonSelected && (
              <ReactTooltip id="lab-result-delete" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
                <div>Please select a reason for deletion.</div>
              </ReactTooltip>
            )}
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  submit = lab => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/laboratories' + (this.props.lab.id ? '/' + this.props.lab.id : ''), {
          patient_id: this.props.patient.id,
          lab_type: lab.lab_type,
          specimen_collection: lab.specimen_collection,
          report: lab.report,
          result: lab.result,
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  };

  delete = () => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .delete(window.BASE_PATH + '/laboratories/' + this.props.lab.id, {
          data: {
            patient_id: this.props.patient.id,
            reason: this.state.selectedReason,
          },
        })
        .then(() => {
          toast.success('Lab Result successfully deleted.');
          this.setState({ loading: false, noReasonSelected: true, showDeleteModal: false });
          location.reload(true);
        })
        .catch(error => {
          toast.error('Failed to delete Lab Result.');
          this.setState({ loading: false, noReasonSelected: true, showDeleteModal: false });
          reportError(error);
        });
    });
  };

  render() {
    return (
      <React.Fragment>
        {!this.props.lab.id && (
          <Button onClick={() => this.setState({ showModal: true, loading: false })}>
            <i className="fas fa-plus fa-fw"></i>
            <span className="ml-2">Add New Lab Result</span>
          </Button>
        )}
        {this.props.lab.id && (
          <Dropdown>
            <Dropdown.Toggle
              id={`vaccine-action-button-${this.props.lab.id}`}
              size="sm"
              variant="primary"
              aria-label={`vaccine-action-button-${this.props.lab.id}`}>
              <i className="fas fa-cogs fw"></i>
            </Dropdown.Toggle>
            <Dropdown.Menu className="test-class" drop={'up'}>
              <Dropdown.Item className="px-4 hi" onClick={() => this.setState({ showModal: true, loading: false })}>
                <i className="fas fa-edit fa-fw"></i>
                <span className="ml-2">Edit</span>
              </Dropdown.Item>
              <Dropdown.Item className="px-4 hi" onClick={() => this.setState({ showDeleteModal: true, loading: false })}>
                <i className="fas fa-trash fa-fw"></i>
                <span className="ml-2">Delete</span>
              </Dropdown.Item>
            </Dropdown.Menu>
          </Dropdown>
        )}
        {this.state.showModal && (
          <LaboratoryModal
            lab={this.props.lab}
            submit={this.submit}
            cancel={() => this.setState({ showModal: false, loading: false })}
            editMode={!!this.props.lab.id}
            loading={this.state.loading}
          />
        )}
        {this.state.showDeleteModal && this.createDeleteModal(() => this.setState({ showDeleteModal: false }), this.delete)}
      </React.Fragment>
    );
  }
}

Laboratory.propTypes = {
  lab: PropTypes.object,
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default Laboratory;
