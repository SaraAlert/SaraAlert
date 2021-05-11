import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Dropdown } from 'react-bootstrap';
import axios from 'axios';
import LaboratoryModal from './LaboratoryModal';
import reportError from '../../util/ReportError';
import DeleteDialog from '../../util/DeleteDialog';

class Laboratory extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showLabModal: false,
      showDeleteModal: false,
      loading: false,
    };
  }

  handleChange = event => {
    this.setState({ [event.target.id]: event.target.value });
  };

  toggleLabModal = () => {
    let current = this.state.showLabModal;
    this.setState({
      showLabModal: !current,
      loading: false,
    });
  };

  handleLabSubmit = lab => {
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
      deleteReason += ', ' + this.state.delete_reason_text;
    }
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .delete(window.BASE_PATH + '/laboratories/' + this.props.lab.id, {
          data: {
            patient_id: this.props.patient.id,
            delete_reason: deleteReason,
          },
        })
        .then(() => {
          this.setState({ loading: false, showDeleteModal: false });
          location.reload(true);
        })
        .catch(error => {
          this.setState({ loading: false, showDeleteModal: false });
          reportError(error);
        });
    });
  };

  render() {
    return (
      <React.Fragment>
        {!this.props.lab.id && (
          <Button onClick={this.toggleLabModal}>
            <i className="fas fa-plus fa-fw"></i>
            <span className="ml-2">Add New Lab Result</span>
          </Button>
        )}
        {this.props.lab.id && (
          <Dropdown>
            <Dropdown.Toggle
              id={`laboratory-action-button-${this.props.lab.id}`}
              size="sm"
              variant="primary"
              aria-label={`laboratory-action-button-${this.props.lab.id}`}>
              <i className="fas fa-cogs fw"></i>
            </Dropdown.Toggle>
            <Dropdown.Menu>
              <Dropdown.Item className="px-4" onClick={this.toggleLabModal}>
                <i className="fas fa-edit fa-fw"></i>
                <span className="ml-2">Edit</span>
              </Dropdown.Item>
              <Dropdown.Item className="px-4" onClick={this.toggleDeleteModal}>
                <i className="fas fa-trash fa-fw"></i>
                <span className="ml-2">Delete</span>
              </Dropdown.Item>
            </Dropdown.Menu>
          </Dropdown>
        )}
        {this.state.showLabModal && (
          <LaboratoryModal
            lab={this.props.lab}
            submit={this.handleLabSubmit}
            cancel={this.toggleLabModal}
            editMode={!!this.props.lab.id}
            loading={this.state.loading}
          />
        )}
        {this.state.showDeleteModal && (
          <DeleteDialog type={'Lab Result'} delete={this.handleDeleteSubmit} toggle={this.toggleDeleteModal} onChange={this.handleChange} />
        )}
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
