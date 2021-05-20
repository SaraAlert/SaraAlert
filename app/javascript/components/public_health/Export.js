import React from 'react';
import { PropTypes } from 'prop-types';
import { ButtonGroup, DropdownButton, Dropdown } from 'react-bootstrap';

import { toast } from 'react-toastify';
import axios from 'axios';
import _ from 'lodash';

import ConfirmExport from './ConfirmExport';
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
        toast.success('Export has been initiated!');
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

  render() {
    return (
      <React.Fragment>
        <DropdownButton
          as={ButtonGroup}
          size="md"
          className="ml-2 mb-2"
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
        {this.state.showCSVModal && (
          <ConfirmExport
            show={this.state.showCSVModal}
            exportType={'Line list CSV'}
            workflow={this.props.query.workflow}
            onCancel={() => this.setState({ showCSVModal: false })}
            onStartExport={this.submit}
          />
        )}
        {this.state.showSaraFormatModal && (
          <ConfirmExport
            show={this.state.showSaraFormatModal}
            exportType={'Sara Alert Format'}
            workflow={this.props.query.workflow}
            onCancel={() => this.setState({ showSaraFormatModal: false })}
            onStartExport={this.submit}
          />
        )}
        {this.state.showAllPurgeEligibleModal && (
          <ConfirmExport
            show={this.state.showAllPurgeEligibleModal}
            exportType={'Excel Export For Purge-Eligible Monitorees'}
            onCancel={() => this.setState({ showAllPurgeEligibleModal: false })}
            onStartExport={this.submit}
          />
        )}
        {this.state.showAllModal && (
          <ConfirmExport
            show={this.state.showAllModal}
            exportType={'Excel Export For All Monitorees'}
            onCancel={() => this.setState({ showAllModal: false })}
            onStartExport={this.submit}
          />
        )}
        {this.state.showCustomFormatModal && (
          <CustomExport
            authenticity_token={this.props.authenticity_token}
            jurisdiction_paths={this.props.jurisdiction_paths}
            all_assigned_users={this.props.all_assigned_users}
            jurisdiction={this.props.jurisdiction}
            available_workflows={this.props.available_workflows}
            available_line_lists={this.props.available_line_lists}
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
  all_assigned_users: PropTypes.array,
  jurisdiction: PropTypes.object,
  available_workflows: PropTypes.array,
  available_line_lists: PropTypes.object,
  tabs: PropTypes.object,
  query: PropTypes.object,
  all_monitorees_count: PropTypes.number,
  current_monitorees_count: PropTypes.number,
  custom_export_options: PropTypes.object,
};

export default Export;
