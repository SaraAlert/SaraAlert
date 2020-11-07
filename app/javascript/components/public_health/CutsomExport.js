import React from 'react';
import { PropTypes } from 'prop-types';
import { Badge, Button, Col, Form, Modal, Row } from 'react-bootstrap';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import CheckboxTree from 'react-checkbox-tree';
import axios from 'axios';
import _ from 'lodash';

import reportError from '../util/ReportError';

class CustomExport extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      preset: props.preset || '',
      format: 'xlsx',
      filtered: true,
      query: _.pickBy(props.query, (value, key) => {
        return ['workflow', 'tab', 'jurisdiction', 'scope', 'user', 'search', 'filter'].includes(key);
      }),
      checked: [],
      expanded: [],
    };
    this.export = this.export.bind(this);
  }

  export() {
    console.log(this.state);
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios({
      method: 'post',
      url: `${window.BASE_PATH}/export/custom`,
      data: {
        format: this.state.format,
        query: this.state.filtered ? this.state.query : {},
        checked: this.state.checked,
        preset: this.state.preset,
      },
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
      <Modal size="lg" show centered onHide={this.props.onClose}>
        <Modal.Header closeButton>
          <Modal.Title>Custom Export Format</Modal.Title>
        </Modal.Header>
        <Modal.Body className="p-0">
          <Row className="mx-3 py-2 g-border-bottom">
            <Col md="6" className="pl-1">
              <p className="pt-1 mb-0 font-weight-bold">{this.props.preset ? 'Export Preset' : 'Save as Preset:'}</p>
            </Col>
            <Col md="12">
              {this.props.preset ? (
                <p>{this.props.preset}</p>
              ) : (
                <Form.Control
                  id="preset"
                  as="input"
                  size="sm"
                  type="text"
                  className="form-square"
                  placeholder="(Optional name for Export Preset)"
                  autoComplete="off"
                  value={this.state.preset}
                  onChange={event => this.setState({ preset: event.target.value })}
                />
              )}
            </Col>
            {this.props.preset && (
              <Col md="6">
                <Button size="sm" variant="secondary btn-square">
                  Remove
                </Button>
              </Col>
            )}
          </Row>
          <Row className="mx-3 py-2 g-border-bottom">
            <Col md="6" className="pl-1">
              <p className="pt-1 mb-0 font-weight-bold">Export Format:</p>
            </Col>
            <Col md="18">
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
            </Col>
          </Row>
          <Row className="mx-3 py-2 g-border-bottom">
            <Col md="6" className="pl-1">
              <p className="pt-1 mb-0 font-weight-bold">Export Monitorees:</p>
            </Col>
            <Col md="18">
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
                    {this.state.query.workflow && this.state.query.tab && (
                      <Badge variant="primary" className="mr-1">
                        {this.state.query.workflow === 'isolation' ? 'Isolation' : 'Exposure'} - {this.props.tabs[this.state.query.tab]?.label}
                      </Badge>
                    )}
                    {this.state.query.jurisdiction && (
                      <Badge variant="primary" className="mr-1">
                        Jurisdiction: {this.props.jurisdiction_paths[this.state.query.jurisdiction]} ({this.state.query.scope})
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
            </Col>
          </Row>
          <Row className="mx-3 pt-2 pb-1">
            <Col md="24" className="pl-1">
              <p className="pt-1 mb-1 font-weight-bold">Export Data:</p>
            </Col>
          </Row>
          <Row className="mx-0 px-3" style={{ backgroundColor: '#ddd' }}>
            <CheckboxTree
              nodes={this.props.custom_export_options}
              checked={this.state.checked}
              expanded={this.state.expanded}
              checkModel="all"
              onCheck={checked => this.setState({ checked })}
              onExpand={expanded => this.setState({ expanded })}
              className="py-2"
              showNodeIcon={false}
              icons={{
                check: <FontAwesomeIcon fixedWidth icon={['far', 'check-square']} />,
                uncheck: <FontAwesomeIcon fixedWidth icon={['far', 'square']} />,
                halfCheck: <FontAwesomeIcon fixedWidth icon={['far', 'minus-square']} />,
                expandClose: <FontAwesomeIcon fixedWidth icon={['fas', 'chevron-right']} />,
                expandOpen: <FontAwesomeIcon fixedWidth icon={['fas', 'chevron-down']} />,
              }}
            />
          </Row>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.onClose}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={this.export} disabled={this.state.checked.length === 0}>
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
  custom_export_options: PropTypes.array,
  onClose: PropTypes.func,
};

export default CustomExport;
