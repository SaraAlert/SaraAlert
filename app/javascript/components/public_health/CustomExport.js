import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Col, Form, Modal, OverlayTrigger, Row, Spinner, Tooltip } from 'react-bootstrap';

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import CheckboxTree from 'react-checkbox-tree';
import axios from 'axios';
import moment from 'moment-timezone';
import _ from 'lodash';
import { toast } from 'react-toastify';

import ConfirmExport from './ConfirmExport';
import PatientsFilters from './custom_export/PatientsFilters';
import reportError from '../util/ReportError';

const rctIcons = {
  check: <FontAwesomeIcon fixedWidth icon={['far', 'check-square']} />,
  uncheck: <FontAwesomeIcon fixedWidth icon={['far', 'square']} />,
  halfCheck: <FontAwesomeIcon fixedWidth icon={['far', 'minus-square']} />,
  expandClose: <FontAwesomeIcon fixedWidth icon={['fas', 'chevron-right']} />,
  expandOpen: <FontAwesomeIcon fixedWidth icon={['fas', 'chevron-down']} />,
};

class CustomExport extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selected_records: props.preset?.id ? 'custom' : 'current',
      custom_patient_query: props.preset?.config?.data?.patients?.query
        ? _.clone(props.preset.config.data.patients.query)
        : {
            workflow: props.available_workflows.length > 1 ? 'global' : props.available_workflows[0].name,
            tab: 'all',
            jurisdiction: props.jurisdiction.id,
            scope: 'all',
            user: null,
            search: '',
            tz_offset: new Date().getTimezoneOffset(),
          },
      filtered_monitorees_count: props.all_monitorees_count,
      show_confirm_export_modal: false,
      cancel_token: axios.CancelToken.source(),
      preset: {
        id: props.preset?.id || null,
        name: props.preset?.name || '',
        config: {
          format: props.preset?.config?.format || 'xlsx',
          data: _.mapValues(props.options, (settings, type) => {
            return {
              checked: _.get(props.preset, ['config', 'data', type, 'checked']) || [],
              expanded: _.get(props.preset, ['config', 'data', type, 'expanded']) || [],
              query:
                _.get(props.preset, ['config', 'data', type, 'query']) || type === 'patients'
                  ? _.clone(props.preset?.config?.data?.patients?.query ? props.preset?.config?.data?.patients?.query : props.patient_query)
                  : {},
            };
          }),
        },
      },
    };
  }

  componentDidMount() {
    // get patient count preview if this is a preset
    if (this.props.preset?.id) {
      this.getPatientCount();
    }
  }

  // Save a new preset
  save = () => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(`${window.BASE_PATH}/user_export_presets`, this.state.preset)
      .then(response => {
        if (response?.data) {
          toast.success('Export preset successfully saved.');
          this.handlePresetChange('id', response?.data?.id);
        }
        this.props.reloadExportPresets();
      })
      .catch(err => reportError(err?.response?.data?.message ? err.response.data.message : err, false));
  };

  // Update an existing preset
  update = () => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .put(`${window.BASE_PATH}/user_export_presets/${this.state.preset?.id}`, this.state.preset)
      .catch(() => toast.error('Failed to update export preset.'))
      .then(response => {
        if (response?.data) {
          toast.success('Export preset successfully updated.');
        }
        this.props.reloadExportPresets();
      });
  };

  // Delete an existing filter
  delete = () => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .delete(`${window.BASE_PATH}/user_export_presets/${this.state.preset?.id}`)
      .catch(() => toast.error('Failed to delete export preset.'))
      .then(() => {
        toast.success('Export preset successfully deleted.');
        this.handlePresetChange('id', null);
        this.props.reloadExportPresets();
      });
  };

  // Export data with current configurations
  export = () => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(`${window.BASE_PATH}/export/custom`, this.state.preset)
      .then(response => {
        if (response?.status === 200) {
          toast.success('Export has been initiated!');
          this.props.onClose();
        }
      })
      .catch(err => {
        reportError(err?.response?.data?.message ? err.response.data.message : err, false);
        this.props.onClose();
      });
  };

  // Get patient count based on custom query
  getPatientCount = () => {
    // cancel any previous unfinished requests to prevent race condition inconsistencies
    this.state.cancel_token.cancel();

    // generate new cancel token for this request
    const cancel_token = axios.CancelToken.source();

    this.setState({ cancel_token, filtered_monitorees_count: 'loading...' }, () => {
      axios
        .post(`${window.BASE_PATH}/public_health/patients/count`, {
          query: this.state.custom_patient_query,
          cancelToken: this.state.cancel_token.token,
        })
        .then(response => this.setState({ filtered_monitorees_count: response?.data?.count || 0 }))
        .catch(err => reportError(err?.response?.data?.message ? err.response.data.message : err, false));
    });
  };

  // Update selected records
  handleSelectedRecordsChange = selected_records => {
    this.setState({ selected_records }, () => {
      if (selected_records === 'current') {
        this.handlePresetChange('config.data.patients.query', _.clone(this.props.patient_query));
      } else if (selected_records === 'custom') {
        this.handlePresetChange('config.data.patients.query', this.state.custom_patient_query);
      } else if (selected_records === 'all') {
        this.handlePresetChange('config.data.patients.query', {
          workflow: 'global',
          tab: 'all',
          jurisdiction: this.props.jurisdiction.id,
          scope: 'all',
          user: null,
          search: '',
          tz_offset: new Date().getTimezoneOffset(),
        });
      }
    });
  };

  // Update preset
  handlePresetChange = (field, value, cb) => {
    this.setState(state => {
      const preset = state.preset;
      _.set(preset, field, value);
      return { preset };
    }, cb);
  };

  render() {
    const non_zero_elements_selected =
      this.state.preset?.config?.data?.patients?.checked?.length > 0 ||
      this.state.preset?.config?.data?.assessments?.checked?.length > 0 ||
      this.state.preset?.config?.data?.laboratories?.checked?.length > 0 ||
      this.state.preset?.config?.data?.vaccines?.checked?.length > 0 ||
      this.state.preset?.config?.data?.close_contacts?.checked?.length > 0 ||
      this.state.preset?.config?.data?.transfers?.checked?.length > 0 ||
      this.state.preset?.config?.data?.histories?.checked?.length > 0;
    const non_zero_records_selected =
      (this.state.selected_records === 'current' && this.props.current_monitorees_count === 0) ||
      (this.state.selected_records === 'custom' && this.state.filtered_monitorees_count === 0);
    return (
      <React.Fragment>
        <Modal size="lg" backdrop="static" show onHide={this.props.onClose}>
          <Modal.Header closeButton>
            <Modal.Title>Custom Export Format {this.state.preset?.name ? `(${this.state.preset.name})` : ''}</Modal.Title>
          </Modal.Header>
          <Modal.Body className="p-0">
            <div className="p-2">
              <p className="mx-3 mt-2 mb-3">Files will be exported in the Excel (.xlsx) format.</p>
              <div className="h5 mx-3 my-2">Choose which records to export</div>
              <Row className="mx-3 pb-2">
                <Col md={24}>
                  <Form.Check
                    id="select-monitoree-records-current"
                    type="radio"
                    className="px-1"
                    label={
                      <span>
                        <a onClick={() => this.handleSelectedRecordsChange('current')}>
                          Current monitoree records from Dashboard View ({this.props.current_monitorees_count}){' '}
                        </a>
                      </span>
                    }
                    onChange={() => this.handleSelectedRecordsChange('current')}
                    checked={this.state.selected_records === 'current'}
                  />
                  {this.state.selected_records === 'current' && (
                    <div className="custom-export-filters">
                      <span className="custom-export-filter-text">
                        <small>
                          <b className="mr-2">Linelist:</b>
                          {`${_.capitalize(this.props.patient_query.workflow)} - ${this.props.tabs[this.props.patient_query.tab]?.label}`}
                        </small>
                      </span>
                      {this.props.patient_query.jurisdiction !== this.props.jurisdiction.id && (
                        <span className="custom-export-filter-text">
                          <small>
                            <b className="mr-2">Jurisdiction:</b>
                            {this.props.jurisdiction_paths[this.props.patient_query.jurisdiction]}
                          </small>
                        </span>
                      )}
                      {this.props.patient_query.user !== null && (
                        <span className="custom-export-filter-text">
                          <small>
                            <b className="mr-2">Assigned User:</b>
                            {this.props.patient_query.user === 'none' ? '<none>' : this.props.patient_query.user}
                          </small>
                        </span>
                      )}
                      {this.props.patient_query.search !== '' && (
                        <span className="custom-export-filter-text">
                          <small>
                            <b className="mr-2">Dashboard Search Terms:</b>
                            {this.props.patient_query.search}
                          </small>
                        </span>
                      )}
                      {this.props.patient_query.filter?.map((filter, index) => {
                        return (
                          <span key={`filter-${index}`} className="custom-export-filter-text">
                            <small>
                              <b className="mr-2">{filter.filterOption?.title}:</b>
                              {['search', 'select', 'number'].includes(filter.filterOption?.type) && (
                                <span>{filter.value === '' ? '<blank>' : filter.value}</span>
                              )}
                              {filter.filterOption?.type === 'multi' && (
                                <div style={{ display: 'inline-grid' }}>
                                  {filter.value?.map((elem, i) => {
                                    return (
                                      <span key={`filter-${index}-${i}`} className="mb-0">
                                        {elem.label}
                                      </span>
                                    );
                                  })}
                                </div>
                              )}
                              {filter.filterOption?.type === 'boolean' && <span>{filter.value ? 'True' : 'False'}</span>}
                              {filter.filterOption?.type === 'date' && (
                                <span>
                                  {filter.dateOption === ''
                                    ? '<blank>'
                                    : `${filter.dateOption} ${
                                        filter.dateOption === 'within'
                                          ? moment(filter.value?.start).format('MM/DD/YYYY') + ' and ' + moment(filter.value?.end).format('MM/DD/YYYY')
                                          : moment(filter.value).format('MM/DD/YYYY')
                                      }`}
                                </span>
                              )}
                              {filter.filterOption?.type === 'relative' && (
                                <span>
                                  {filter.relativeOption === 'custom'
                                    ? `in the ${filter.value?.when} ${filter.value?.number} ${filter.value?.unit}`
                                    : filter.relativeOption}
                                </span>
                              )}
                              {filter.filterOption?.type === 'combination' && (
                                <div style={{ display: 'inline-grid' }}>
                                  {filter.value?.map((f, i) => {
                                    return (
                                      <span key={`filter-${index}-${i}`} className="mb-0">
                                        <b className="mr-2">
                                          {filter.filterOption?.fields
                                            ?.find(fields => {
                                              return fields.name === f.name;
                                            })
                                            ?.title?.replace(/\b\w/g, l => l.toUpperCase())}
                                          :
                                        </b>
                                        {typeof f.value === 'string'
                                          ? f.value === ''
                                            ? '<blank>'
                                            : f.value
                                          : f.value?.when === ''
                                          ? '<blank>'
                                          : `${f.value.when}  ${moment(filter.value.date).format('MM/DD/YYYY')}`}
                                      </span>
                                    );
                                  })}
                                </div>
                              )}
                            </small>
                          </span>
                        );
                      })}
                    </div>
                  )}
                  <Form.Check
                    id="select-monitoree-records-all"
                    type="radio"
                    className="px-1"
                    label={<a onClick={() => this.handleSelectedRecordsChange('all')}>All monitoree records ({this.props.all_monitorees_count})</a>}
                    onChange={() => this.handleSelectedRecordsChange('all')}
                    checked={this.state.selected_records === 'all'}
                  />
                  <Form.Check
                    id="select-monitoree-records-custom"
                    type="radio"
                    className="px-1 mb-2"
                    label={
                      <a onClick={() => this.handleSelectedRecordsChange('custom')}>
                        Only include monitoree records that meet the following criteria (
                        {this.state.filtered_monitorees_count === 'loading...' ? (
                          <Spinner variant="secondary" animation="border" size="sm"></Spinner>
                        ) : (
                          this.state.filtered_monitorees_count
                        )}
                        ):
                      </a>
                    }
                    onChange={() => this.handleSelectedRecordsChange('custom')}
                    checked={this.state.selected_records === 'custom'}
                  />
                  {this.state.selected_records === 'custom' && (
                    <PatientsFilters
                      authenticity_token={this.props.authenticity_token}
                      jurisdiction_paths={this.props.jurisdiction_paths}
                      all_assigned_users={this.props.all_assigned_users}
                      jurisdiction={this.props.jurisdiction}
                      available_workflows={this.props.available_workflows}
                      available_line_lists={this.props.available_line_lists}
                      continuous_exposure_enabled={this.props.continuous_exposure_enabled}
                      query={this.state.custom_patient_query}
                      onQueryChange={(field, value, cb) =>
                        this.setState(
                          state => {
                            return {
                              custom_patient_query: { ...state.custom_patient_query, [field]: value },
                            };
                          },
                          () => {
                            this.getPatientCount();
                            if (this.state.selected_records === 'custom') {
                              this.handlePresetChange(`config.data.patients.query.${field}`, value, cb);
                            }
                          }
                        )
                      }
                    />
                  )}
                </Col>
              </Row>
            </div>
            <hr className="m-0" />
            <div className="p-2">
              <div className="h5 mx-3 my-2">Choose which elements to export</div>
              <p className="mx-3 mb-1">Which data would you like to include for each monitoree?</p>
              <Row className="mx-3 py-2">
                <Col md={24} className="p-1">
                  <CheckboxTree
                    id="rct-patients-elements"
                    nodes={this.props.options?.patients?.nodes}
                    checked={this.state.preset?.config?.data?.patients?.checked}
                    expanded={this.state.preset?.config?.data?.patients?.expanded}
                    onCheck={checked => this.handlePresetChange('config.data.patients.checked', checked)}
                    onExpand={expanded => this.handlePresetChange('config.data.patients.expanded', expanded)}
                    showNodeIcon={false}
                    icons={rctIcons}
                  />
                </Col>
              </Row>
              <Row className="mx-3 py-1 g-border-top">
                <Col md={24} className="p-1">
                  <CheckboxTree
                    id="rct-assessments-elements"
                    nodes={this.props.options?.assessments?.nodes}
                    checked={this.state.preset?.config?.data?.assessments?.checked}
                    expanded={this.state.preset?.config?.data?.assessments?.expanded}
                    onCheck={checked => this.handlePresetChange('config.data.assessments.checked', checked)}
                    onExpand={expanded => this.handlePresetChange('config.data.assessments.expanded', expanded)}
                    showNodeIcon={false}
                    icons={rctIcons}
                  />
                </Col>
              </Row>
              <Row className="mx-3 py-1 g-border-top">
                <Col md={24} className="p-1">
                  <CheckboxTree
                    id="rct-laboratories-elements"
                    nodes={this.props.options?.laboratories?.nodes}
                    checked={this.state.preset?.config?.data?.laboratories?.checked}
                    expanded={this.state.preset?.config?.data?.laboratories?.expanded}
                    onCheck={checked => this.handlePresetChange('config.data.laboratories.checked', checked)}
                    onExpand={expanded => this.handlePresetChange('config.data.laboratories.expanded', expanded)}
                    showNodeIcon={false}
                    icons={rctIcons}
                  />
                </Col>
              </Row>
              <Row className="mx-3 py-1 g-border-top">
                <Col md={24} className="p-1">
                  <CheckboxTree
                    id="rct-vaccines-elements"
                    nodes={this.props.options?.vaccines?.nodes}
                    checked={this.state.preset?.config?.data?.vaccines?.checked}
                    expanded={this.state.preset?.config?.data?.vaccines?.expanded}
                    onCheck={checked => this.handlePresetChange('config.data.vaccines.checked', checked)}
                    onExpand={expanded => this.handlePresetChange('config.data.vaccines.expanded', expanded)}
                    showNodeIcon={false}
                    icons={rctIcons}
                  />
                </Col>
              </Row>
              <Row className="mx-3 py-1 g-border-top">
                <Col md={24} className="p-1">
                  <CheckboxTree
                    id="rct-close-contacts-elements"
                    nodes={this.props.options?.close_contacts?.nodes}
                    checked={this.state.preset?.config?.data?.close_contacts?.checked}
                    expanded={this.state.preset?.config?.data?.close_contacts?.expanded}
                    onCheck={checked => this.handlePresetChange('config.data.close_contacts.checked', checked)}
                    onExpand={expanded => this.handlePresetChange('config.data.close_contacts.expanded', expanded)}
                    showNodeIcon={false}
                    icons={rctIcons}
                  />
                </Col>
              </Row>
              <Row className="mx-3 py-1 g-border-top">
                <Col md={24} className="p-1">
                  <CheckboxTree
                    id="rct-transfers-elements"
                    nodes={this.props.options?.transfers?.nodes}
                    checked={this.state.preset?.config?.data?.transfers?.checked}
                    expanded={this.state.preset?.config?.data?.transfers?.expanded}
                    onCheck={checked => this.handlePresetChange('config.data.transfers.checked', checked)}
                    onExpand={expanded => this.handlePresetChange('config.data.transfers.expanded', expanded)}
                    showNodeIcon={false}
                    icons={rctIcons}
                  />
                </Col>
              </Row>
              <Row className="mx-3 py-1 g-border-top">
                <Col md={24} className="p-1">
                  <CheckboxTree
                    id="rct-histories-elements"
                    nodes={this.props.options?.histories?.nodes}
                    checked={this.state.preset?.config?.data?.histories?.checked}
                    expanded={this.state.preset?.config?.data?.histories?.expanded}
                    onCheck={checked => this.handlePresetChange('config.data.histories.checked', checked)}
                    onExpand={expanded => this.handlePresetChange('config.data.histories.expanded', expanded)}
                    showNodeIcon={false}
                    icons={rctIcons}
                  />
                </Col>
              </Row>
            </div>
            <hr className="m-0" />
            <div className="p-2">
              <div className="h5 mx-3 my-2">Custom export format name</div>
              <Row className="mx-3">
                <Col md={12} className="px-1 py-2">
                  <Form.Control
                    id="preset"
                    as="input"
                    size="sm"
                    type="text"
                    className="form-square"
                    placeholder="(Optional name for saved Custom Export)"
                    aria-label="Custom Export Name Text Input"
                    autoComplete="off"
                    value={this.state.preset?.name}
                    onChange={event => this.handlePresetChange('name', event?.target?.value)}
                  />
                </Col>
                <Col md={12} className="px-1 pt-2">
                  <Form.Group className="mb-0 float-right">
                    {this.state.preset?.id && (
                      <React.Fragment>
                        <Button
                          id="custom-export-action-delete"
                          size="sm"
                          variant="danger"
                          disabled={!this.state.preset?.id}
                          className="mr-1 custom-export-btn"
                          onClick={this.delete}>
                          <FontAwesomeIcon className="mr-1" icon={['fas', 'trash']} />
                          Delete
                        </Button>
                        {this.state.preset?.name === '' ? (
                          <OverlayTrigger overlay={<Tooltip>Please indicate a name for the saved Custom Export</Tooltip>}>
                            <span>
                              <Button size="sm" variant="primary" disabled className="ml-1 custom-export-btn">
                                <FontAwesomeIcon className="mr-1" icon={['fas', 'pen-alt']} />
                                Update
                              </Button>
                            </span>
                          </OverlayTrigger>
                        ) : (
                          <Button id="custom-export-action-update" size="sm" variant="primary" className="ml-1 custom-export-btn" onClick={this.update}>
                            <FontAwesomeIcon className="mr-1" icon={['fas', 'pen-alt']} />
                            Update
                          </Button>
                        )}
                      </React.Fragment>
                    )}
                    {!this.state.preset?.id && (
                      <React.Fragment>
                        {this.state.preset?.name === '' ? (
                          <OverlayTrigger overlay={<Tooltip>Please indicate a name for the saved Custom Export</Tooltip>}>
                            <span>
                              <Button size="sm" variant="primary" disabled className="custom-export-btn-disabled">
                                <FontAwesomeIcon className="mr-1" icon={['fas', 'save']} />
                                Save
                              </Button>
                            </span>
                          </OverlayTrigger>
                        ) : (
                          <Button id="custom-export-action-save" size="sm" variant="primary" className="custom-export-btn" onClick={this.save}>
                            <FontAwesomeIcon className="mr-1" icon={['fas', 'save']} />
                            Save
                          </Button>
                        )}
                      </React.Fragment>
                    )}
                  </Form.Group>
                </Col>
              </Row>
            </div>
          </Modal.Body>
          <Modal.Footer>
            <Button id="custom-export-action-cancel" variant="secondary btn-square" onClick={this.props.onClose}>
              Cancel
            </Button>
            {non_zero_elements_selected ? (
              non_zero_records_selected ? (
                <OverlayTrigger overlay={<Tooltip>Please modify filters to select at least 1 record</Tooltip>}>
                  <span>
                    <Button variant="primary btn-square" disabled className="custom-export-btn-disabled">
                      Export
                    </Button>
                  </span>
                </OverlayTrigger>
              ) : (
                <Button id="custom-export-action-export" variant="primary btn-square" onClick={() => this.setState({ show_confirm_export_modal: true })}>
                  Export
                </Button>
              )
            ) : (
              <OverlayTrigger overlay={<Tooltip>Please select at least one data element to export</Tooltip>}>
                <span>
                  <Button variant="primary btn-square" disabled className="custom-export-btn-disabled">
                    Export
                  </Button>
                </span>
              </OverlayTrigger>
            )}
          </Modal.Footer>
        </Modal>
        {this.state.show_confirm_export_modal && (
          <ConfirmExport
            show={this.state.show_confirm_export_modal}
            exportType={'Custom Export Format'}
            presetName={this.state.preset?.name}
            onCancel={() => this.setState({ show_confirm_export_modal: false })}
            onStartExport={this.export}
          />
        )}
      </React.Fragment>
    );
  }
}

CustomExport.propTypes = {
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  all_assigned_users: PropTypes.array,
  jurisdiction: PropTypes.object,
  available_workflows: PropTypes.array,
  available_line_lists: PropTypes.object,
  tabs: PropTypes.object,
  preset: PropTypes.object,
  presets: PropTypes.array,
  patient_query: PropTypes.object,
  all_monitorees_count: PropTypes.number,
  current_monitorees_count: PropTypes.number,
  options: PropTypes.object,
  onClose: PropTypes.func,
  reloadExportPresets: PropTypes.func,
  continuous_exposure_enabled: PropTypes.bool,
};

export default CustomExport;
