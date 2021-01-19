import React from 'react';
import { PropTypes } from 'prop-types';
import { Button } from 'react-bootstrap';
import axios from 'axios';
import FileDownload from 'js-file-download';
import base64StringToBlob from 'base64toblob';
import moment from 'moment-timezone';

import reportError from '../util/ReportError';

class DownloadMonitoreeExcel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      loadingNBS: false,
      loadingExcel: false,
    };
  }

  downloadExcel = () => {
    this.setState({ loadingExcel: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .get(window.BASE_PATH + '/export/full_history_patient/' + this.props.patient.id, {})
        .then(response => {
          var fileDate = moment().format();
          FileDownload(
            base64StringToBlob(response.data.replace(/(\r\n|\n|\r)/gm, ''), 'application/xlsx'),
            'Sara-Alert-Monitoree-Export-' + this.props.patient.id + '-' + fileDate + '.xlsx'
          );
          this.setState({ loadingExcel: false });
        })
        .catch(error => {
          reportError(error);
          this.setState({ loadingExcel: false });
        });
    });
  };

  downloadNBS = () => {
    this.setState({ loadingNBS: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .get(window.BASE_PATH + '/export/nbs/patient/' + this.props.patient.id, {})
        .then(response => {
          var fileDate = moment().format();
          FileDownload(
            base64StringToBlob(response.data.replace(/(\r\n|\n|\r)/gm, ''), 'application/zip'),
            'Sara-Alert-Monitoree-Export-NBS-' + this.props.patient.id + '-' + fileDate + '.zip'
          );
          this.setState({ loadingNBS: false });
        })
        .catch(error => {
          reportError(error);
          this.setState({ loadingNBS: false });
        });
    });
  };

  render() {
    return (
      <React.Fragment>
        <Button id="monitoree-excel-export" className="mx-2 mt-1 mb-4" onClick={this.downloadExcel} disabled={this.state.loadingExcel}>
          <i className="fas fa-download"></i> Download Excel Export
          {this.state.loadingExcel && (
            <React.Fragment>
              &nbsp;<span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
            </React.Fragment>
          )}
        </Button>
        <Button id="monitoree-nbs-export" className="mx-1 mt-1 mb-4" onClick={this.downloadNBS} disabled={this.state.loadingNBS}>
          <i className="fas fa-download"></i> Download NBS Export
          {this.state.loadingNBS && (
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
