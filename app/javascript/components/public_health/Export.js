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
    let exportOptions = [];
    let hasCustomFormat = false;
    if (props?.export_options?.export) {
      exportOptions = Object.values(props.export_options.export.options).map(x => ({ isOpen: false, workflowSpecific: x.workflow_specific, label: x.label }));
    }
    // 'Custom Format' is shown at the end after a divider, if it exists
    hasCustomFormat = exportOptions.some(x => x.label === 'Custom Format...');
    exportOptions = exportOptions.filter(x => x.label !== 'Custom Format...');

    this.state = {
      exportOptions,
      hasCustomFormat,
      showCustomFormatModal: false,
    };
  }

  toggleExportOpen = eoIndex => {
    this.setState({
      exportOptions: this.state.exportOptions.map((eo, eoi) => {
        if (eoi === eoIndex) {
          eo.isOpen = !eo.isOpen;
        }
        return eo;
      }),
    });
  };

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
          exportOptions: this.state.exportOptions.map(eo => {
            eo.isOpen = false;
            return eo;
          }),
        });
      })
      .catch(err => {
        reportError(err?.response?.data?.message ? err.response.data.message : err, false);
        this.setState({
          exportOptions: this.state.exportOptions.map(eo => {
            eo.isOpen = false;
            return eo;
          }),
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
              <i className="fas fa-download"></i> {this.props.export_options?.export.label || 'Export'}{' '}
            </React.Fragment>
          }>
          {this.state.exportOptions.map((eo, eoIndex) => {
            return (
              <Dropdown.Item key={`export-option-${eoIndex}`} onClick={() => this.toggleExportOpen(eoIndex)}>
                {eo.workflowSpecific ? `${eo.label} (${this.props.query.workflow})` : `${eo.label}`}
              </Dropdown.Item>
            );
          })}
          {this.state.savedExportPresets && this.state.savedExportPresets.length > 0 && <Dropdown.Divider />}
          {this.state.savedExportPresets?.map((savedPreset, index) => {
            return (
              <Dropdown.Item key={`sep-${index}`} onClick={() => this.setState({ savedPreset, showCustomFormatModal: true })}>
                {savedPreset.name}
              </Dropdown.Item>
            );
          })}
          {this.state.hasCustomFormat && (
            <React.Fragment>
              <Dropdown.Divider />
              <Dropdown.Item onClick={() => this.setState({ showCustomFormatModal: true })}>Custom Format...</Dropdown.Item>
            </React.Fragment>
          )}
        </DropdownButton>
        {this.state.exportOptions.map((eo, eoIndex) => {
          if (eo.isOpen) {
            return (
              <ConfirmExport
                key={`confirm-export-${eoIndex}`}
                show={eo.isOpen}
                exportType={eo.label}
                workflow={eo.workflowSpecific ? this.props.query.workflow : null}
                onCancel={() => this.toggleExportOpen(eoIndex)}
                onStartExport={this.submit}
              />
            );
          }
        })}
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
  all_monitorees_count: PropTypes.number,
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  all_assigned_users: PropTypes.array,
  jurisdiction: PropTypes.object,
  available_workflows: PropTypes.array,
  available_line_lists: PropTypes.object,
  current_monitorees_count: PropTypes.number,
  custom_export_options: PropTypes.object,
  export_options: PropTypes.object,
  tabs: PropTypes.object,
  query: PropTypes.object,
};

export default Export;
