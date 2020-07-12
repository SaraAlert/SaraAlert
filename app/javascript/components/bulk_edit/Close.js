import React from 'react';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import reportError from '../util/ReportError';
import confirmDialog from '../util/ConfirmDialog';

class Close extends React.Component {
  constructor(props) {
    super(props);
    this.submit = this.submit.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.state = {
      loading: false,
      message: 'monitoring status to "Not Monitoring".',
      showConfirm: false,
    };
    window.bulkCloseComponent = this;
  }

  clearState() {
    this.setState({
      patients: [],
    });
  }

  componentDidUpdate() {
    if (this.state.showConfirm) {
      this.handleSubmit('You are about to close out the selected monitoree records. Are you sure?');
    }
  }

  activate(patients) {
    if (!patients || !patients.length) {
      return;
    }

    this.setState({
      patients: patients,
      showConfirm: true,
    });
  }

  handleSubmit = async confirmText => {
    if (await confirmDialog(confirmText)) {
      this.setState({ showConfirm: false }, () => {
        this.submit();
      });
    }
  };

  submit() {
    let idArray = this.state.patients.map(x => x['id']);

    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/bulk_edit/status', {
          ids: idArray,
          comment: true,
          message: this.state.message,
          monitoring: false,
          apply_to_group: false,
          diffState: ['monitoring'],
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
    return <React.Fragment></React.Fragment>;
  }
}

Close.propTypes = {
  authenticity_token: PropTypes.string,
};

export default Close;
