import React from 'react';
import { PropTypes } from 'prop-types';
import { Badge, Button, Col, Form, Modal, Row } from 'react-bootstrap';

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import CheckboxTree from 'react-checkbox-tree';
import Select from 'react-select';
import axios from 'axios';
import chroma from 'chroma-js';
import _ from 'lodash';

import reportError from '../util/ReportError';

const rctIcons = {
  check: <FontAwesomeIcon fixedWidth icon={['far', 'check-square']} />,
  uncheck: <FontAwesomeIcon fixedWidth icon={['far', 'square']} />,
  halfCheck: <FontAwesomeIcon fixedWidth icon={['far', 'minus-square']} />,
  expandClose: <FontAwesomeIcon fixedWidth icon={['fas', 'chevron-right']} />,
  expandOpen: <FontAwesomeIcon fixedWidth icon={['fas', 'chevron-down']} />,
};

const colorStyles = {
  control: styles => ({ ...styles, backgroundColor: 'white' }),
  option: (styles, { data, isDisabled, isFocused, isSelected }) => {
    const color = chroma(data.color);
    return {
      ...styles,
      backgroundColor: isDisabled ? null : isSelected ? data.color : isFocused ? color.alpha(0.1).css() : null,
      color: isDisabled ? '#ccc' : isSelected ? (chroma.contrast(color, 'white') > 2 ? 'white' : 'black') : data.color,
      cursor: isDisabled ? 'not-allowed' : 'default',

      ':active': {
        ...styles[':active'],
        backgroundColor: !isDisabled && (isSelected ? data.color : color.alpha(0.3).css()),
      },
    };
  },
  multiValue: (styles, { data }) => {
    const color = chroma(data.color);
    return {
      ...styles,
      backgroundColor: color.alpha(0.1).css(),
    };
  },
  multiValueLabel: (styles, { data }) => ({
    ...styles,
    color: data.color,
  }),
  multiValueRemove: (styles, { data }) => ({
    ...styles,
    color: data.color,
    ':hover': {
      backgroundColor: data.color,
      color: 'white',
    },
  }),
};

class CustomExport extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      preset: props.preset || '',
      filename: '',
      format: 'xlsx',
      filtered: true,
      query: _.pickBy(props.query, (_, key) => {
        return ['workflow', 'tab', 'jurisdiction', 'scope', 'user', 'search', 'filter'].includes(key);
      }),
      patients_checked: props.custom_export_options.patients.checked,
      patients_expanded: props.custom_export_options.patients.expanded,
      patients_filters: [],
      patients_order: [],
      assessments_checked: props.custom_export_options.assessments.checked,
      assessments_expanded: props.custom_export_options.assessments.expanded,
      assessments_filters: [],
      assessments_order: [],
      laboratories_checked: props.custom_export_options.laboratories.checked,
      laboratories_expanded: props.custom_export_options.laboratories.expanded,
      laboratories_filters: [],
      laboratories_order: [],
      close_contacts_checked: props.custom_export_options.close_contacts.checked,
      close_contacts_expanded: props.custom_export_options.close_contacts.expanded,
      close_contacts_filters: [],
      close_contacts_order: [],
      transfers_checked: props.custom_export_options.transfers.checked,
      transfers_expanded: props.custom_export_options.transfers.expanded,
      transfers_filters: [],
      transfers_order: [],
      histories_checked: props.custom_export_options.histories.checked,
      histories_expanded: props.custom_export_options.histories.expanded,
      histories_filters: [],
      histories_order: [],
    };
    this.export = this.export.bind(this);
    console.log(this.props);
    console.log(this.state);
  }

  export() {
    console.log(this.state);
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios({
      method: 'post',
      url: `${window.BASE_PATH}/export/custom`,
      data: this.state,
    })
      .then(response => {
        console.log(response);
      })
      .catch(err => {
        reportError(err);
      });
  }

  render() {
    return (
      <Modal dialogClassName="modal-xl" backdrop="static" show onHide={this.props.onClose}>
        <Modal.Header closeButton>
          <Modal.Title>Custom Export Format</Modal.Title>
        </Modal.Header>
        <Modal.Body className="p-0">
          <Row className="mx-3 pt-3 g-border-bottom">
            <Col md="8" className="px-1">
              <Form.Label className="nav-input-label">EXPORT PRESET NAME</Form.Label>
              <Form.Control
                id="preset"
                as="input"
                size="sm"
                type="text"
                className="form-square"
                placeholder="(Optional name for export preset)"
                autoComplete="off"
                value={this.state.preset}
                onChange={event => this.setState({ preset: event.target.value })}
                disabled={this.props.preset}
              />
            </Col>
            <Col md="8" className="px-1">
              <Form.Label className="nav-input-label">EXPORT FILE NAME PREFIX</Form.Label>
              <Form.Control
                id="filename"
                as="input"
                size="sm"
                type="text"
                className="form-square"
                placeholder="(Optional prefix for export file names)"
                autoComplete="off"
                value={this.state.filename}
                onChange={event => this.setState({ filename: event.target.value })}
              />
            </Col>
            <Col md="8" className="px-1">
              <Form.Label className="nav-input-label">EXPORT FORMAT</Form.Label>
              <Form.Group>
                <Button
                  id="csvFormatBtn"
                  size="sm"
                  variant={this.state.format === 'csv' ? 'primary' : 'outline-secondary'}
                  style={{ outline: 'none', boxShadow: 'none' }}
                  onClick={() => this.setState({ format: 'csv' })}>
                  <FontAwesomeIcon className="mr-1" icon={['fas', 'file-csv']} />
                  CSV
                </Button>
                <Button
                  id="xlsxFormatBtn"
                  size="sm"
                  variant={this.state.format === 'xlsx' ? 'primary' : 'outline-secondary'}
                  style={{ outline: 'none', boxShadow: 'none' }}
                  onClick={() => this.setState({ format: 'xlsx' })}>
                  <FontAwesomeIcon className="mr-1" icon={['fas', 'file-excel']} />
                  Excel
                </Button>
              </Form.Group>
            </Col>
          </Row>
          <Row className="mx-3 py-1">
            <Col md="8" className="px-0 py-1">
              <CheckboxTree
                nodes={this.props.custom_export_options?.patients?.nodes}
                checked={this.state.patients_checked}
                expanded={this.state.patients_expanded}
                onCheck={patients_checked => this.setState({ patients_checked })}
                onExpand={patients_expanded => this.setState({ patients_expanded })}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
            <Col md="8" className="px-2 py-1">
              <Form.Group>
                <Form.Label className="nav-input-label mb-0">Filter:</Form.Label>
                <div className="py-1">
                  <Form.Check
                    id="allMonitoreesBtn"
                    type="radio"
                    size="sm"
                    label={`All Monitorees (${this.props.all_monitorees_count})`}
                    checked={!this.state.filtered}
                    onChange={() => this.setState({ filtered: false })}
                  />
                  {!this.state.filtered && (
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
                    checked={!!this.state.filtered}
                    onChange={() => this.setState({ filtered: true })}
                  />
                  {this.state.filtered && (
                    <div style={{ paddingLeft: '1.25rem' }}>
                      {this.state.query.jurisdiction && (
                        <Badge variant="primary" className="mr-1">
                          Jurisdiction: {this.props.jurisdiction_paths[this.state.query.jurisdiction]} ({this.state.query.scope})
                        </Badge>
                      )}
                      {this.state.query.workflow && this.state.query.tab && (
                        <Badge variant="primary" className="mr-1">
                          {this.state.query.workflow === 'isolation' ? 'Isolation' : 'Exposure'} - {this.props.tabs[this.state.query.tab]?.label}
                        </Badge>
                      )}
                      {this.state.query.user && this.state.query.user !== 'all' && (
                        <Badge variant="primary" className="mr-1">
                          Assigned User: {this.state.query.user}
                        </Badge>
                      )}
                      {this.state.query.search && this.state.query.search !== '' && (
                        <Badge variant="primary" className="mr-1">
                          Search: {this.state.query.search}
                        </Badge>
                      )}
                      {this.state.query.filter &&
                        this.state.query.filter.map(f => {
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
            <Col md="8" className="px-2 py-1">
              <Form.Group>
                <Form.Label className="nav-input-label mb-0">Order:</Form.Label>
                <Select
                  isMulti
                  className="my-1"
                  options={this.props.custom_export_options?.patients?.order}
                  value={this.state.patients_order}
                  onChange={patients_order => this.setState({ patients_order })}
                  placeholder="Order by..."
                  styles={colorStyles}
                />
              </Form.Group>
            </Col>
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md="8" className="px-0 py-1">
              <CheckboxTree
                nodes={this.props.custom_export_options?.assessments?.nodes}
                checked={this.state.assessments_checked}
                expanded={this.state.assessments_expanded}
                onCheck={assessments_checked => this.setState({ assessments_checked })}
                onExpand={assessments_expanded => this.setState({ assessments_expanded })}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
            <Col md="8" className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Filter:</Form.Label>
              <Select
                isMulti
                className="my-1"
                options={this.props.custom_export_options?.assessments?.filters?.symptomatic?.options}
                placeholder="Filter by status..."
              />
              <Select
                isMulti
                className="my-1"
                options={this.props.custom_export_options?.assessments?.filters?.who_reported?.options}
                placeholder="Filter by reporter..."
              />
            </Col>
            <Col md="8" className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Order:</Form.Label>
              <Select
                isMulti
                className="my-1"
                options={this.props.custom_export_options?.assessments?.order}
                onChange={assessments_order => this.setState({ assessments_order })}
                value={this.state.assessments_order}
                placeholder="Order by..."
                styles={colorStyles}
              />
            </Col>
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md="8" className="px-0 py-1">
              <CheckboxTree
                nodes={this.props.custom_export_options?.laboratories?.nodes}
                checked={this.state.laboratories_checked}
                expanded={this.state.laboratories_expanded}
                onCheck={laboratories_checked => this.setState({ laboratories_checked })}
                onExpand={laboratories_expanded => this.setState({ laboratories_expanded })}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
            <Col md="8" className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Filter:</Form.Label>
              <Select
                isMulti
                className="my-1"
                options={this.props.custom_export_options?.laboratories?.filters?.lab_type?.options}
                placeholder="Filter by type..."
              />
              <Select
                isMulti
                className="my-1"
                options={this.props.custom_export_options?.laboratories?.filters?.result?.options}
                placeholder="Filter by result..."
              />
            </Col>
            <Col md="8" className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Order:</Form.Label>
              <Select
                isMulti
                className="my-1"
                options={this.props.custom_export_options?.laboratories?.order}
                value={this.state.laboratories_order}
                onChange={laboratories_order => this.setState({ laboratories_order })}
                placeholder="Order by..."
                styles={colorStyles}
              />
            </Col>
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md="8" className="px-0 py-1">
              <CheckboxTree
                nodes={this.props.custom_export_options?.close_contacts?.nodes}
                checked={this.state.close_contacts_checked}
                expanded={this.state.close_contacts_expanded}
                onCheck={close_contacts_checked => this.setState({ close_contacts_checked })}
                onExpand={close_contacts_expanded => this.setState({ close_contacts_expanded })}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
            <Col md="8" className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Filter:</Form.Label>
              <Select
                isMulti
                className="my-1"
                options={this.props.custom_export_options?.close_contacts?.filters?.enrolled_id?.options}
                placeholder="Filter by type..."
              />
            </Col>
            <Col md="8" className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Order:</Form.Label>
              <Select
                isMulti
                className="my-1"
                options={this.props.custom_export_options?.close_contacts?.order}
                value={this.state.close_contacts_order}
                onChange={close_contacts_order => this.setState({ close_contacts_order })}
                placeholder="Order by..."
                styles={colorStyles}
              />
            </Col>
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md="8" className="px-0 py-1">
              <CheckboxTree
                nodes={this.props.custom_export_options?.transfers?.nodes}
                checked={this.state.transfers_checked}
                expanded={this.state.transfers_expanded}
                onCheck={transfers_checked => this.setState({ transfers_checked })}
                onExpand={transfers_expanded => this.setState({ transfers_expanded })}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
            <Col md="8" className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Filter:</Form.Label>
            </Col>
            <Col md="8" className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Order:</Form.Label>
              <Select
                isMulti
                className="my-1"
                options={this.props.custom_export_options?.transfers?.order}
                value={this.state.transfers_order}
                onChange={transfers_order => this.setState({ transfers_order })}
                placeholder="Order by..."
                styles={colorStyles}
              />
            </Col>
          </Row>
          <Row className="mx-3 py-1 g-border-top">
            <Col md="8" className="px-0 py-1">
              <CheckboxTree
                nodes={this.props.custom_export_options?.histories?.nodes}
                checked={this.state.histories_checked}
                expanded={this.state.histories_expanded}
                onCheck={histories_checked => this.setState({ histories_checked })}
                onExpand={histories_expanded => this.setState({ histories_expanded })}
                showNodeIcon={false}
                icons={rctIcons}
              />
            </Col>
            <Col md="8" className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Filter:</Form.Label>
              <Select
                isMulti
                className="my-1"
                options={this.props.custom_export_options?.histories?.filters?.history_type?.options}
                placeholder="Filter by history type..."
              />
              <Select
                isMulti
                className="my-1"
                options={this.props.custom_export_options?.histories.filters?.created_by?.options}
                placeholder="Filter by creator..."
              />
            </Col>
            <Col md="8" className="px-2 py-1">
              <Form.Label className="nav-input-label mb-0">Order:</Form.Label>
              <Select
                isMulti
                className="my-1"
                options={this.props.custom_export_options?.histories?.order}
                value={this.state.histories_order}
                onChange={histories_order => this.setState({ histories_order })}
                placeholder="Order by..."
                styles={colorStyles}
              />
            </Col>
          </Row>
          <Row className="my-1"></Row>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.onClose}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={this.export} disabled={this.state.patients_checked.length === 0}>
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
  preset: PropTypes.string,
  query: PropTypes.object,
  all_monitorees_count: PropTypes.number,
  filtered_monitorees_count: PropTypes.number,
  custom_export_options: PropTypes.object,
  onClose: PropTypes.func,
};

export default CustomExport;
