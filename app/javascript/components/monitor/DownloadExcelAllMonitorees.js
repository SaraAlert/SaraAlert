import React from 'react';
import { Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import DownloadingSpinner from './DownloadingSpinner';
import FileDownload from 'js-file-download';
import base64StringToBlob from 'base64toblob';
import moment from 'moment';
import reportError from '../util/ReportError';

class DownloadExcelAllMonitorees extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showDownloadExcelModal: false,
      loading: false,
    };
    this.toggleDownloadExcelModal = this.toggleDownloadExcelModal.bind(this);
    this.downloadExcel = this.downloadExcel.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  toggleDownloadExcelModal() {
    let current = this.state.showDownloadExcelModal;
    this.setState({
      loading: false,
      showDownloadExcelModal: !current,
    });
  }

  handleChange(event) {
    this.setState({ [event.target.id]: event.target.value });
  }

  downloadExcel() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .get(window.BASE_PATH + '/export/full_history_all_monitorees', {})
        .then(response => {
          var fileDate = moment().format();
          FileDownload(base64StringToBlob(response.data, 'application/xlsx'), 'Sara-Alert-Full-History-All-Monitorees-' + fileDate + '.xlsx');
          this.setState({ loading: false, showDownloadExcelModal: false });
        })
        .catch(error => {
          reportError(error);
        });
    });
  }

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          After clicking &apos;Download&apos;, Sara Alert will gather all of your jurisdiction&apos;s monitoree data, assessments, lab results, and edit
          history. It will then save that data into an Excel file, and may prompt you to download it in your browser. This process may take several minutes to
          complete, based on the amount of data present.
          <br></br>
          <br></br>
          {this.state.loading && (
            <div style={{ display: 'flex', justifyContent: 'center', fontSize: '22px' }}>
              <br></br>
              <br></br>
              <DownloadingSpinner />{' '}
            </div>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.loading}>
            Download
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
      <React.Fragment>
        <Button className="dropdown-item" onClick={this.toggleDownloadExcelModal}>
          Excel Export For All Monitorees
        </Button>
        {this.state.showDownloadExcelModal && this.createModal('Download Database Excel For All Monitorees', this.toggleDownloadExcelModal, this.downloadExcel)}
      </React.Fragment>
    );
  }
}

DownloadExcelAllMonitorees.propTypes = {
  authenticity_token: PropTypes.string,
};

export default DownloadExcelAllMonitorees;
