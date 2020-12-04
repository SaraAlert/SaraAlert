import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Col, Form, Modal, OverlayTrigger, Row, Tooltip } from 'react-bootstrap';

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import CheckboxTree from 'react-checkbox-tree';
import axios from 'axios';
import _ from 'lodash';
import { toast } from 'react-toastify';

import AssessmentsFilters from './custom_export/AssessmentsFilters';
import CloseContactsFilters from './custom_export/CloseContactsFilters';
import HistoriesFilters from './custom_export/HistoriesFilters';
import LaboratoriesFilters from './custom_export/LaboratoriesFilters';
import PatientsFilters from './custom_export/PatientsFilters';
import TransfersFilters from './custom_export/TransfersFilters';
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
      preset: {
        id: props.preset?.id || null,
        name: props.preset?.name || '',
        config: {
          filename: props.preset?.config?.filename || '',
          format: props.preset?.config?.format || 'xlsx',
          data: _.mapValues(props.options, (settings, type) => {
            return {
              // checked: _.get(props.preset, ['config', 'data', type, 'checked']) || settings?.checked || [],
              checked: _.get(props.preset, ['config', 'data', type, 'checked']) || [],
              expanded: _.get(props.preset, ['config', 'data', type, 'expanded']) || settings?.expanded || [],
              query: _.get(props.preset, ['config', 'data', type, 'query']) || type === 'patients' ? _.clone(props.patient_query) : {},
            };
          }),
        },
      },
    };
  }

  // Save a new preset
  save = () => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(`${window.BASE_PATH}/user_export_presets`, this.state.preset)
      .catch(() => toast.error('Failed to save export preset.'))
      .then(response => {
        if (response?.data) {
          toast.success('Export preset successfully saved.');
          this.handlePresetChange('id', response?.data?.id);
        }
        this.props.reloadExportPresets();
      });
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
      .then(response => console.log(response))
      .catch(err => reportError(err));
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
    return (
      <Modal dialogClassName="modal-xl" backdrop="static" show onHide={this.props.onClose}>
        <Modal.Header closeButton>
          <Modal.Title>Custom Export Format</Modal.Title>
        </Modal.Header>
        <Modal.Body className="p-1">
          <Row className="mx-3 py-2">
            <Col md={10} className="p-1">
              <CheckboxTree
                nodes={this.props.options?.patients?.nodes}
                checked={this.state.preset?.config?.data?.patients?.checked}
                expanded={this.state.preset?.config?.data?.patients?.expanded}
                onCheck={checked => this.handlePresetChange('config.data.patients.checked', checked)}
                onExpand={expanded => this.handlePresetChange('config.data.patients.expanded', expanded)}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
            <Col md={14} className="px-0 py-1">
              <PatientsFilters
                authenticity_token={this.props.authenticity_token}
                jurisdiction_paths={this.props.jurisdiction_paths}
                jurisdiction={this.props.jurisdiction}
                query={this.state.preset?.config?.data?.patients?.query}
                onQueryChange={(field, value, cb) => this.handlePresetChange(`config.data.patients.query.${field}`, value, cb)}
                // disabled={this.state.preset?.config?.data?.patients?.checked?.length === 0}
              />
            </Col>
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md={10} className="p-1">
              <CheckboxTree
                nodes={this.props.options?.assessments?.nodes}
                checked={this.state.preset?.config?.data?.assessments?.checked}
                expanded={this.state.preset?.config?.data?.assessments?.expanded}
                onCheck={checked => this.handlePresetChange('config.data.assessments.checked', checked)}
                onExpand={expanded => this.handlePresetChange('config.data.assessments.expanded', expanded)}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
            {this.state.preset?.config?.data?.assessments?.checked?.length > 0 && (
              <Col md={14} className="px-0 py-1">
                <AssessmentsFilters
                  query={this.state.preset?.config?.data?.assessments?.query}
                  onQueryChange={(field, value, cb) => this.handlePresetChange(`config.data.assessments.query.${field}`, value, cb)}
                />
              </Col>
            )}
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md={10} className="p-1">
              <CheckboxTree
                nodes={this.props.options?.laboratories?.nodes}
                checked={this.state.preset?.config?.data?.laboratories?.checked}
                expanded={this.state.preset?.config?.data?.laboratories?.expanded}
                onCheck={checked => this.handlePresetChange('config.data.laboratories.checked', checked)}
                onExpand={expanded => this.handlePresetChange('config.data.laboratories.expanded', expanded)}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
            {this.state.preset?.config?.data?.laboratories?.checked?.length > 0 && (
              <Col md={14} className="px-0 py-1">
                <LaboratoriesFilters
                  query={this.state.preset?.config?.data?.laboratories?.query}
                  onQueryChange={(field, value, cb) => this.handlePresetChange(`config.data.laboratories.query.${field}`, value, cb)}
                />
              </Col>
            )}
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md={10} className="p-1">
              <CheckboxTree
                nodes={this.props.options?.close_contacts?.nodes}
                checked={this.state.preset?.config?.data?.close_contacts?.checked}
                expanded={this.state.preset?.config?.data?.close_contacts?.expanded}
                onCheck={checked => this.handlePresetChange('config.data.close_contacts.checked', checked)}
                onExpand={expanded => this.handlePresetChange('config.data.close_contacts.expanded', expanded)}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
            {this.state.preset?.config?.data?.close_contacts?.checked?.length > 0 && (
              <Col md={14} className="px-0 py-1">
                <CloseContactsFilters
                  query={this.state.preset?.config?.data?.close_contacts?.query}
                  onQueryChange={(field, value, cb) => this.handlePresetChange(`config.data.close_contacts.query.${field}`, value, cb)}
                />
              </Col>
            )}
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md={10} className="p-1">
              <CheckboxTree
                nodes={this.props.options?.transfers?.nodes}
                checked={this.state.preset?.config?.data?.transfers?.checked}
                expanded={this.state.preset?.config?.data?.transfers?.expanded}
                onCheck={checked => this.handlePresetChange('config.data.transfers.checked', checked)}
                onExpand={expanded => this.handlePresetChange('config.data.transfers.expanded', expanded)}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
            {this.state.preset?.config?.data?.transfers?.checked?.length > 0 && (
              <Col md={14} className="px-0 py-1">
                <TransfersFilters
                  jurisdiction_paths={this.props.jurisdiction_paths}
                  jurisdiction={this.props.jurisdiction}
                  query={this.state.preset?.config?.data?.transfers?.query}
                  onQueryChange={(field, value, cb) => this.handlePresetChange(`config.data.transfers.query.${field}`, value, cb)}
                />
              </Col>
            )}
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md={10} className="p-1">
              <CheckboxTree
                nodes={this.props.options?.histories?.nodes}
                checked={this.state.preset?.config?.data?.histories?.checked}
                expanded={this.state.preset?.config?.data?.histories?.expanded}
                onCheck={checked => this.handlePresetChange('config.data.histories.checked', checked)}
                onExpand={expanded => this.handlePresetChange('config.data.histories.expanded', expanded)}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
            {this.state.preset?.config?.data?.histories?.checked?.length > 0 && (
              <Col lg={14} className="px-0 py-1">
                <HistoriesFilters
                  query={this.state.preset?.config?.data?.histories?.query}
                  onQueryChange={(field, value, cb) => this.handlePresetChange(`config.data.histories.query.${field}`, value, cb)}
                />
              </Col>
            )}
          </Row>
          <Row className="mx-3 pt-3 g-border-top">
            <Col lg={7} className="px-1">
              <Form.Label className="nav-input-label">PRESET NAME</Form.Label>
              <Form.Control
                id="preset"
                as="input"
                size="sm"
                type="text"
                className="form-square"
                placeholder="(Optional name for export preset)"
                autoComplete="off"
                value={this.state.preset?.name}
                onChange={event => this.handlePresetChange('name', event?.target?.value)}
              />
            </Col>
            <Col md={7} className="px-1">
              <Form.Label className="nav-input-label">FILE NAME PREFIX</Form.Label>
              <Form.Control
                id="filename"
                as="input"
                size="sm"
                type="text"
                className="form-square"
                placeholder="(Optional prefix for export file names)"
                autoComplete="off"
                value={this.state.preset?.config?.filename}
                onChange={event => this.handlePresetChange('config.filename', event?.target?.value)}
              />
            </Col>
            <Col lg={4} className="px-1">
              <Form.Label className="nav-input-label">FILE FORMAT</Form.Label>
              <Form.Group>
                <Button
                  size="sm"
                  variant={this.state.preset?.config?.format === 'csv' ? 'primary' : 'outline-secondary'}
                  style={{ outline: 'none', boxShadow: 'none' }}
                  onClick={() => this.handlePresetChange('config.format', 'csv')}>
                  <FontAwesomeIcon className="mr-1" icon={['fas', 'file-csv']} />
                  CSV
                </Button>
                <Button
                  size="sm"
                  variant={this.state.preset?.config?.format === 'xlsx' ? 'primary' : 'outline-secondary'}
                  style={{ outline: 'none', boxShadow: 'none' }}
                  onClick={() => this.handlePresetChange('config.format', 'xlsx')}>
                  <FontAwesomeIcon className="mr-1" icon={['fas', 'file-excel']} />
                  Excel
                </Button>
              </Form.Group>
            </Col>
            <Col lg={6} className="px-1">
              <Form.Label className="nav-input-label">MANAGE PRESET</Form.Label>
              <Form.Group>
                {this.state.preset?.id ? (
                  <React.Fragment>
                    <Button
                      size="sm"
                      variant="primary"
                      disabled={!this.state.preset?.id}
                      className="mr-1"
                      style={{ outline: 'none', boxShadow: 'none' }}
                      onClick={this.update}>
                      <FontAwesomeIcon className="mr-1" icon={['fas', 'pen-alt']} />
                      Update
                    </Button>
                    <Button
                      size="sm"
                      variant="danger"
                      disabled={!this.state.preset?.id}
                      className="ml-1"
                      style={{ outline: 'none', boxShadow: 'none' }}
                      onClick={this.delete}>
                      <FontAwesomeIcon className="mr-1" icon={['fas', 'trash']} />
                      Delete
                    </Button>
                  </React.Fragment>
                ) : this.state.preset?.name === '' ? (
                  <OverlayTrigger overlay={<Tooltip>Please indicate a preset name to save this preset</Tooltip>}>
                    <div>
                      <Button size="sm" variant="primary" disabled style={{ outline: 'none', boxShadow: 'none' }}>
                        <FontAwesomeIcon className="mr-1" icon={['fas', 'save']} />
                        Save
                      </Button>
                    </div>
                  </OverlayTrigger>
                ) : (
                  <Button size="sm" variant="primary" style={{ outline: 'none', boxShadow: 'none' }} onClick={this.save}>
                    <FontAwesomeIcon className="mr-1" icon={['fas', 'save']} />
                    Save
                  </Button>
                )}
              </Form.Group>
            </Col>
          </Row>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.onClose}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={this.export} disabled={this.state.preset?.config?.data?.patients?.checked?.length === 0}>
            Export
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

CustomExport.propTypes = {
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  jurisdiction: PropTypes.object,
  tabs: PropTypes.object,
  preset: PropTypes.object,
  patient_query: PropTypes.object,
  all_monitorees_count: PropTypes.number,
  filtered_monitorees_count: PropTypes.number,
  options: PropTypes.object,
  onClose: PropTypes.func,
  reloadExportPresets: PropTypes.func,
};

export default CustomExport;
