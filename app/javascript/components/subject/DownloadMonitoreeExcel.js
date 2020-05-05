import React from 'react';
import { Button } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import FileDownload from 'js-file-download';
import base64StringToBlob from 'base64toblob';
import moment from 'moment';

class DownloadMonitoreeExcel extends React.Component {
  constructor(props) {
    super(props);
    this.downloadExcel = this.downloadExcel.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  toggleDownloadExcelModal() {
    let current = this.state.showDownloadExcelModal;
    this.setState({
      showDownloadExcelModal: !current,
    });
  }

  handleChange(event) {
    this.setState({ [event.target.id]: event.target.value });
  }

  downloadExcel() {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .get(window.BASE_PATH + '/export/excel/full_history/patient/' + this.props.patient.id, {})
      .then(response => {
        var fileDate = moment().format();
        FileDownload(
          base64StringToBlob(response.data, 'application/xlsx'),
          'Sara-Alert-Full-History-Monitoree-' + this.props.patient.id + '-' + fileDate + '.xlsx'
        );
        location.href = window.BASE_PATH + '/patients/' + this.props.patient.id;
      })
      .catch(error => {
        console.error(error);
      });
  }

  render() {
    return (
      <React.Fragment>
        <Button className="mx-2 mt-1 mb-3" onClick={this.downloadExcel}>
          <i className="fas fa-download"></i> Download Excel Export
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
