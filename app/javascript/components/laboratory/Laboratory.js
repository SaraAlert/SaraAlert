import React from 'react';
import { PropTypes } from 'prop-types';
import { Button } from 'react-bootstrap';
import axios from 'axios';

import LaboratoryForm from './LaboratoryForm';
import reportError from '../util/ReportError';

class Laboratory extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showModal: false,
      loading: false,
    };
  }

  toggleModal = () => {
    this.setState(state => {
      return {
        showModal: !state.showModal,
        loading: false,
      };
    });
  };

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
          <Button variant="link" onClick={() => this.setState({ showModal: true, loading: false })} className="btn btn-link py-0" size="sm">
            <i className="fas fa-edit"></i> Edit
          </Button>
        )}
        {this.state.showModal && (
          <LaboratoryForm
            lab={this.props.lab}
            submit={this.submit}
            cancel={() => this.setState({ showModal: false, loading: false })}
            editMode={!!this.props.lab.id}
            loading={this.state.loading}
          />
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
