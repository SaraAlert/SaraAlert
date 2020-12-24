import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, ButtonGroup, Modal, DropdownButton, Dropdown } from 'react-bootstrap';
import { ToastContainer, toast } from 'react-toastify';
import axios from 'axios';

import reportError from '../util/ReportError';

class Export extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showCSVModal: false,
      showSaraFormatModal: false,
      showAllPurgeEligibleModal: false,
      showAllModal: false,
    };
    this.submit = this.submit.bind(this);
  }

  submit(endpoint) {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios({
      method: 'get',
      url: window.BASE_PATH + endpoint,
    })
      .then(() => {
        toast.success('Export has been initiated!', {
          containerId: 'exports',
        });
        this.setState({
          showCSVModal: false,
          showSaraFormatModal: false,
          showAllPurgeEligibleModal: false,
          showAllModal: false,
        });
      })
      .catch(err => {
        reportError(err?.response?.data?.message ? err.response.data.message : err, false);
        this.setState({
          showCSVModal: false,
          showSaraFormatModal: false,
          showAllPurgeEligibleModal: false,
          showAllModal: false,
        });
      });
  }

  createModal(title, toggle, submit, endpoint) {
    return (
      <Modal size="lg" show centered onHide={toggle}>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            After clicking <b>Start Export</b>, Sara Alert will gather all of the monitoree data that comprises your request and generate an export file. Sara
            Alert will then send your user account an email with a one-time download link. This process may take several minutes to complete, based on the
            amount of data present.
          </p>
          <p>
            NOTE: The system will store one of each type of export file. If you initiate another export of this file type, any old files will be overwritten and
            download links that have not been accessed will be invalid. Only one of each export type is allowed per user per hour.
          </p>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
          <Button
            variant="primary btn-square"
            onClick={() => {
              submit(endpoint);
            }}>
            Start Export
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <DropdownButton
          as={ButtonGroup}
          size="md"
          className="ml-2 mb-4"
          title={
            <React.Fragment>
              <i className="fas fa-download"></i> Export{' '}
            </React.Fragment>
          }>
          <Dropdown.Item onClick={() => this.setState({ showCSVModal: true })}>Line list CSV ({this.props.workflow})</Dropdown.Item>
          <Dropdown.Item onClick={() => this.setState({ showSaraFormatModal: true })}>Sara Alert Format ({this.props.workflow})</Dropdown.Item>
          <Dropdown.Item onClick={() => this.setState({ showAllPurgeEligibleModal: true })}>Excel Export For Purge-Eligible Monitorees</Dropdown.Item>
          <Dropdown.Item onClick={() => this.setState({ showAllModal: true })}>Excel Export For All Monitorees</Dropdown.Item>
        </DropdownButton>
        {this.state.showCSVModal &&
          this.createModal(
            `Line list CSV (${this.props.workflow})`,
            () => {
              this.setState({ showCSVModal: false });
            },
            this.submit,
            `/export/csv/patients/linelist/${this.props.workflow}`
          )}
        {this.state.showSaraFormatModal &&
          this.createModal(
            `Sara Alert Format (${this.props.workflow})`,
            () => {
              this.setState({ showSaraFormatModal: false });
            },
            this.submit,
            `/export/excel/patients/comprehensive/${this.props.workflow}`
          )}
        {this.state.showAllPurgeEligibleModal &&
          this.createModal(
            'Excel Export For Purge-Eligible Monitorees',
            () => {
              this.setState({ showAllPurgeEligibleModal: false });
            },
            this.submit,
            '/export/excel/patients/full_history/purgeable'
          )}
        {this.state.showAllModal &&
          this.createModal(
            'Excel Export For All Monitorees',
            () => {
              this.setState({ showAllModal: false });
            },
            this.submit,
            '/export/excel/patients/full_history/all'
          )}
        <ToastContainer
          position="top-center"
          autoClose={3000}
          enableMultiContainer
          containerId={'exports'}
          closeOnClick
          pauseOnVisibilityChange
          draggable
          pauseOnHover
        />
      </React.Fragment>
    );
  }
}

Export.propTypes = {
  workflow: PropTypes.string,
  authenticity_token: PropTypes.string,
};

export default Export;
