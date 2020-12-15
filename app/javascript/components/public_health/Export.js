import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, ButtonGroup, Modal, DropdownButton, Dropdown } from 'react-bootstrap';

import { ToastContainer, toast } from 'react-toastify';
import axios from 'axios';
import _ from 'lodash';

import CustomExport from './CustomExport';
import reportError from '../util/ReportError';

class Export extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showCSVModal: false,
      showSaraFormatModal: false,
      showAllPurgeEligibleModal: false,
      showAllModal: false,
      showCustomFormatModal: false,
    };
  }

  componentDidMount() {
    // Grab saved user presets
    this.reloadExportPresets();
  }

  reloadExportPresets = () => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios.get(window.BASE_PATH + '/user_export_presets').then(response => this.setState({ savedExportPresets: response.data }));
  };

  submit = endpoint => {
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
  };

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
          <Dropdown.Item onClick={() => this.setState({ showCSVModal: true })}>Line list CSV ({this.props.query.workflow})</Dropdown.Item>
          <Dropdown.Item onClick={() => this.setState({ showSaraFormatModal: true })}>Sara Alert Format ({this.props.query.workflow})</Dropdown.Item>
          <Dropdown.Item onClick={() => this.setState({ showAllPurgeEligibleModal: true })}>Excel Export For Purge-Eligible Monitorees</Dropdown.Item>
          <Dropdown.Item onClick={() => this.setState({ showAllModal: true })}>Excel Export For All Monitorees</Dropdown.Item>
          {this.state.savedExportPresets && this.state.savedExportPresets.length > 0 && <Dropdown.Divider />}
          {this.state.savedExportPresets?.map((savedPreset, index) => {
            return (
              <Dropdown.Item key={`sep-${index}`} onClick={() => this.setState({ savedPreset, showCustomFormatModal: true })}>
                {savedPreset.name}
              </Dropdown.Item>
            );
          })}
          <Dropdown.Divider />
          <Dropdown.Item onClick={() => this.setState({ showCustomFormatModal: true })}>Custom Format...</Dropdown.Item>
        </DropdownButton>
        {this.state.showCSVModal &&
          this.createModal(
            `Line list CSV (${this.props.query.workflow})`,
            () => {
              this.setState({ showCSVModal: false });
            },
            this.submit,
            `/export/csv_linelist/${this.props.query.workflow}`
          )}
        {this.state.showSaraFormatModal &&
          this.createModal(
            `Sara Alert Format (${this.props.query.workflow})`,
            () => {
              this.setState({ showSaraFormatModal: false });
            },
            this.submit,
            `/export/sara_alert_format/${this.props.query.workflow}`
          )}
        {this.state.showAllPurgeEligibleModal &&
          this.createModal(
            'Excel Export For Purge-Eligible Monitorees',
            () => {
              this.setState({ showAllPurgeEligibleModal: false });
            },
            this.submit,
            '/export/full_history_patients/purgeable'
          )}
        {this.state.showAllModal &&
          this.createModal(
            'Excel Export For All Monitorees',
            () => {
              this.setState({ showAllModal: false });
            },
            this.submit,
            '/export/full_history_patients/all'
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
        {this.state.showCustomFormatModal && (
          <CustomExport
            authenticity_token={this.props.authenticity_token}
            jurisdiction_paths={this.props.jurisdiction_paths}
            jurisdiction={this.props.jurisdiction}
            tabs={this.props.tabs}
            preset={this.state.savedPreset}
            presets={this.state.savedExportPresets}
            patient_query={_.pickBy(this.props.query, (value, key) => {
              return ['workflow', 'tab', 'jurisdiction', 'scope', 'user', 'search', 'filter', 'tz_offset'].includes(key);
            })}
            current_monitorees_count={this.props.current_monitorees_count}
            all_monitorees_count={this.props.all_monitorees_count}
            options={this.props.custom_export_options}
            onClose={() => this.setState({ showCustomFormatModal: false, savedPreset: null })}
            reloadExportPresets={this.reloadExportPresets}
          />
        )}
      </React.Fragment>
    );
  }
}

Export.propTypes = {
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  jurisdiction: PropTypes.object,
  tabs: PropTypes.object,
  query: PropTypes.object,
  all_monitorees_count: PropTypes.number,
  current_monitorees_count: PropTypes.number,
  custom_export_options: PropTypes.object,
};

export default Export;
