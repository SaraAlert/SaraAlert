import React from 'react';
import { PropTypes } from 'prop-types';
import { Badge, Button, Col, Form, Modal, Row } from 'react-bootstrap';

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import CheckboxTree from 'react-checkbox-tree';
import Select from 'react-select';
import axios from 'axios';
import _ from 'lodash';

import reportError from '../util/ReportError';
import { toast } from 'react-toastify';

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
    console.log(props);
    this.state = {
      preset: {
        id: props.preset?.id || null,
        name: props.preset?.name || '',
        config: {
          filename: props.preset?.filename || '',
          format: props.preset?.format || 'xlsx',
          filtered: props.preset?.filtered === !!props.preset?.filtered ? props.preset?.filtered : true,
          query:
            props.preset?.query ||
            props.preset?.query ||
            _.pickBy(props.query, (_, key) => {
              return ['workflow', 'tab', 'jurisdiction', 'scope', 'user', 'search', 'filter'].includes(key);
            }),
          queries: _.mapValues(props.options, (settings, type) => {
            return {
              checked: _.get(props.preset, type)?.queries.checked || settings?.checked || [],
              expanded: _.get(props.preset, type)?.queries.expanded || settings?.expanded || [],
              filters: _.get(props.preset, type)?.queries.filters || [],
              order: _.get(props.preset, type)?.queries.order || [],
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
          this.setState({ id: response?.data?.id });
        }
        this.props.reloadExportPresets();
      });
  };

  // Update an existing preset
  update = () => {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .put(`${window.BASE_PATH}/user_export_presets/${this.state?.id}`, this.state.preset)
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
    console.log(this.state);
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .delete(`${window.BASE_PATH}/user_export_presets/${this.props.preset?.id}`)
      .catch(() => toast.error('Failed to delete export preset.'))
      .then(() => {
        toast.success('Export preset successfully deleted.');
        this.setState({ id: null });
        this.props.reloadExportPresets();
      });
  };

  // Export data with current configurations
  export = () => {
    console.log(this.state);
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(`${window.BASE_PATH}/export/custom`, this.state)
      .then(response => console.log(response))
      .catch(err => reportError(err));
  };

  // Update queries
  handlePresetChange = (field, value) => {
    this.setState(state => {
      const preset = state.preset;
      _.set(preset, field, value);
      return { preset };
    });
  };

  render() {
    return (
      <Modal dialogClassName="modal-xl" backdrop="static" show onHide={this.props.onClose}>
        <Modal.Header closeButton>
          <Modal.Title>Custom Export Format</Modal.Title>
        </Modal.Header>
        <Modal.Body className="p-0">
          <Row className="mx-3 pt-3 pb-1">
            <Col md={12} className="px-2 py-1">
              <Form.Group>
                <Form.Label className="nav-input-label mb-0">Select Monitorees:</Form.Label>
                <div className="py-1">
                  <Form.Check
                    id="allMonitoreesBtn"
                    type="radio"
                    size="sm"
                    label={`All Monitorees (${this.props.all_monitorees_count})`}
                    checked={!this.state.preset?.config?.filtered}
                    onChange={() => this.handlePresetChange(['config', 'filtered'], false)}
                  />
                  {!this.state.preset?.config?.filtered && (
                    <div style={{ paddingLeft: '1.25rem' }}>
                      <Badge variant="primary">Jurisdiction: {this.props.jurisdiction?.path} (all)</Badge>
                    </div>
                  )}
                </div>
                <div className="py-1">
                  <Form.Check
                    id="currentFilterMonitoreesBtn"
                    type="radio"
                    size="sm"
                    label={`Current Filter (${this.props.filtered_monitorees_count})`}
                    checked={!!this.state.preset?.config?.filtered}
                    onChange={() => this.handlePresetChange(['config', 'filtered'], true)}
                  />
                  {this.state.preset?.config?.filtered && (
                    <div style={{ paddingLeft: '1.25rem' }}>
                      {this.state.preset?.config?.query?.jurisdiction && (
                        <Badge variant="primary" className="mr-1">
                          Jurisdiction: {this.props.jurisdiction_paths[this.state.preset?.config?.query?.jurisdiction]} (
                          {this.state.preset?.config?.query?.scope})
                        </Badge>
                      )}
                      {this.state.preset?.config?.query?.workflow && this.state.preset?.config?.query?.tab && (
                        <Badge variant="primary" className="mr-1">
                          {this.state.preset?.config?.query?.workflow === 'isolation' ? 'Isolation' : 'Exposure'} -{' '}
                          {this.props.tabs[this.state.preset?.config?.query.tab]?.label}
                        </Badge>
                      )}
                      {this.state.preset?.config?.query?.user && this.state.preset?.config?.query?.user !== 'all' && (
                        <Badge variant="primary" className="mr-1">
                          Assigned User: {this.state.preset?.config?.query?.user}
                        </Badge>
                      )}
                      {this.state.preset?.config?.query?.search && this.state.preset?.config?.query?.search !== '' && (
                        <Badge variant="primary" className="mr-1">
                          Search: {this.state.preset?.config?.query?.search}
                        </Badge>
                      )}
                      {this.state.preset?.config?.query?.filter &&
                        this.state.preset?.config?.query?.filter.map(f => {
                          return (
                            <Badge variant="secondary" className="mr-1" key={f?.filterOption?.name}>
                              {f?.filterOption?.title}: {f?.value?.toString()}
                            </Badge>
                          );
                        })}
                    </div>
                  )}
                </div>
              </Form.Group>
            </Col>
            <Col md={12} className="px-0 py-1">
              <CheckboxTree
                nodes={this.props.options?.patients?.nodes}
                checked={this.state.preset?.config?.queries?.patients?.checked}
                expanded={this.state.preset?.config?.queries?.patients?.expanded}
                onCheck={checked => this.handlePresetChange(['config', 'queries', 'patients', 'checked'], checked)}
                onExpand={expanded => this.handlePresetChange(['config', 'queries', 'patients', 'expanded'], expanded)}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md={12} className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Filter:</Form.Label>
              <Select isMulti className="my-1" options={this.props.options?.assessments?.filters?.symptomatic?.options} placeholder="Filter by status..." />
              <Select isMulti className="my-1" options={this.props.options?.assessments?.filters?.who_reported?.options} placeholder="Filter by reporter..." />
            </Col>
            <Col md={12} className="px-0 py-1">
              <CheckboxTree
                nodes={this.props.options?.assessments?.nodes}
                checked={this.state.preset?.config?.queries?.assessments?.checked}
                expanded={this.state.preset?.config?.queries?.assessments?.expanded}
                onCheck={checked => this.handlePresetChange(['config', 'queries', 'assessments', 'checked'], checked)}
                onExpand={expanded => this.handlePresetChange(['config', 'queries', 'assessments', 'expanded'], expanded)}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md={12} className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Filter:</Form.Label>
              <Select isMulti className="my-1" options={this.props.options?.laboratories?.filters?.lab_type?.options} placeholder="Filter by type..." />
              <Select isMulti className="my-1" options={this.props.options?.laboratories?.filters?.result?.options} placeholder="Filter by result..." />
            </Col>
            <Col md={12} className="px-0 py-1">
              <CheckboxTree
                nodes={this.props.options?.laboratories?.nodes}
                checked={this.state.preset?.config?.queries?.laboratories?.checked}
                expanded={this.state.preset?.config?.queries?.laboratories?.expanded}
                onCheck={checked => this.handlePresetChange(['config', 'queries', 'laboratories', 'checked'], checked)}
                onExpand={expanded => this.handlePresetChange(['config', 'queries', 'laboratories', 'expanded'], expanded)}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md={12} className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Filter:</Form.Label>
              <Select isMulti className="my-1" options={this.props.options?.close_contacts?.filters?.enrolled_id?.options} placeholder="Filter by type..." />
            </Col>
            <Col md={12} className="px-0 py-1">
              <CheckboxTree
                nodes={this.props.options?.close_contacts?.nodes}
                checked={this.state.preset?.config?.queries?.close_contacts?.checked}
                expanded={this.state.preset?.config?.queries?.close_contacts?.expanded}
                onCheck={checked => this.handlePresetChange(['config', 'queries', 'close_contacts', 'checked'], checked)}
                onExpand={expanded => this.handlePresetChange(['config', 'queries', 'close_contacts', 'expanded'], expanded)}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md={12} className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Filter:</Form.Label>
            </Col>
            <Col md={12} className="px-0 py-1">
              <CheckboxTree
                nodes={this.props.options?.transfers?.nodes}
                checked={this.state.preset?.config?.queries?.transfers?.checked}
                expanded={this.state.preset?.config?.queries?.transfers?.expanded}
                onCheck={checked => this.handlePresetChange(['config', 'queries', 'transfers', 'checked'], checked)}
                onExpand={expanded => this.handlePresetChange(['config', 'queries', 'transfers', 'expanded'], expanded)}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md={12} className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Filter:</Form.Label>
              <Select
                isMulti
                className="my-1"
                options={this.props.options?.histories?.filters?.history_type?.options}
                placeholder="Filter by history type..."
              />
              <Select isMulti className="my-1" options={this.props.options?.histories?.filters?.created_by?.options} placeholder="Filter by creator..." />
            </Col>
            <Col md={12} className="px-0 py-1">
              <CheckboxTree
                nodes={this.props.options?.histories?.nodes}
                checked={this.state.preset?.config?.queries?.histories?.checked}
                expanded={this.state.preset?.config?.queries?.histories?.expanded}
                onCheck={checked => this.handlePresetChange(['config', 'queries', 'histories', 'checked'], checked)}
                onExpand={expanded => this.handlePresetChange(['config', 'queries', 'histories', 'expanded'], expanded)}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
          </Row>
          <Row className="mx-3 pt-3 g-border-top">
            <Col md={8} className="px-1">
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
                disabled={this.state.preset?.id}
              />
            </Col>
            <Col md={8} className="px-1">
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
                onChange={event => this.handlePresetChange(['config', 'filename'], event?.target?.value)}
              />
            </Col>
            <Col md={4} className="px-1">
              <Form.Label className="nav-input-label">FILE FORMAT</Form.Label>
              <Form.Group>
                <Button
                  size="sm"
                  variant={this.state.preset?.config?.format === 'csv' ? 'primary' : 'outline-secondary'}
                  style={{ outline: 'none', boxShadow: 'none' }}
                  onClick={() => this.handlePresetChange(['config', 'format'], 'csv')}>
                  <FontAwesomeIcon className="mr-1" icon={['fas', 'file-csv']} />
                  CSV
                </Button>
                <Button
                  size="sm"
                  variant={this.state.preset?.config?.format === 'xlsx' ? 'primary' : 'outline-secondary'}
                  style={{ outline: 'none', boxShadow: 'none' }}
                  onClick={() => this.handlePresetChange(['config', 'format'], 'xlsx')}>
                  <FontAwesomeIcon className="mr-1" icon={['fas', 'file-excel']} />
                  Excel
                </Button>
              </Form.Group>
            </Col>
            <Col md={4} className="px-1">
              <Form.Label className="nav-input-label">MANAGE PRESET</Form.Label>
              <Form.Group>
                <Button
                  size="sm"
                  variant="success"
                  disabled={this.state.preset?.name === ''}
                  style={{ outline: 'none', boxShadow: 'none' }}
                  onClick={this.save}>
                  <FontAwesomeIcon className="mr-1" icon={['fas', 'save']} />
                  Save
                </Button>
                <Button size="sm" variant="warning" disabled={!this.state.preset?.id} style={{ outline: 'none', boxShadow: 'none' }} onClick={this.update}>
                  <FontAwesomeIcon className="mr-1" icon={['fas', 'pen-alt']} />
                  Update
                </Button>
                <Button size="sm" variant="danger" disabled={!this.state.preset?.id} style={{ outline: 'none', boxShadow: 'none' }} onClick={this.delete}>
                  <FontAwesomeIcon className="mr-1" icon={['fas', 'trash']} />
                  Delete
                </Button>
              </Form.Group>
            </Col>
          </Row>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.onClose}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={this.export} disabled={this.state.preset?.config?.queries?.patients?.checked?.length === 0}>
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
  query: PropTypes.object,
  all_monitorees_count: PropTypes.number,
  filtered_monitorees_count: PropTypes.number,
  options: PropTypes.object,
  onClose: PropTypes.func,
  reloadExportPresets: PropTypes.func,
};

export default CustomExport;
