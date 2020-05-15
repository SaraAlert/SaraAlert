import React from 'react';
import { Button } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import FileDownload from 'js-file-download';
import base64StringToBlob from 'base64toblob';
import moment from 'moment';
import reportError from '../util/ReportError';

class DownloadMonitoreeExcel extends React.Component {
  constructor(props) {
    super(props);
    this.downloadExcel = this.downloadExcel.bind(this);
    this.state = {
      loading: false,
    };
  }

  downloadExcel() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .get(window.BASE_PATH + '/export/excel/patients/full_history/patient/' + this.props.patient.id, {})
        .then(response => {
          var fileDate = moment().format();
          FileDownload(
            base64StringToBlob(response.data.replace(/(\r\n|\n|\r)/gm, ''), 'application/xlsx'),
            'Sara-Alert-Full-History-Monitoree-' + this.props.patient.id + '-' + fileDate + '.xlsx'
          );
          location.href = window.BASE_PATH + '/patients/' + this.props.patient.id;
        })
        .catch(error => {
          reportError(error);
        });
    });
  }

  render() {
    return (
      <React.Fragment>
        <Button className="mx-2 mt-1 mb-4" onClick={this.downloadExcel} disabled={this.state.loading}>
          <i className="fas fa-download"></i> Download Excel Export
          {this.state.loading && (
            <React.Fragment>
              &nbsp;<span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
            </React.Fragment>
          )}
        </Button>
      </React.Fragment>
    );
  }
}

DownloadMonitoreeExcel.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default DownloadMonitoreeExcel;
