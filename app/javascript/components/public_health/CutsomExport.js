import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Col, Form, Modal, Row } from 'react-bootstrap';
import CheckboxTree from 'react-checkbox-tree';
import axios from 'axios';

import { customExportOptions } from '../../data/customExportOptions';
import reportError from '../util/ReportError';

class CustomExport extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      preset: this.props.preset || '',
      format: 'xlsx',
      filter: true,
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
        query: this.state.filtered ? this.props.query : {},
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
                onClick={() => this.setState({ format: 'csv' })}>
                CSV
              </Button>
              <Button
                id="xlsxFormatBtn"
                size="sm"
                variant={this.state.format === 'xlsx' ? 'primary' : 'outline-secondary'}
                onClick={() => this.setState({ format: 'xlsx' })}>
                Excel
              </Button>
            </Col>
          </Row>
          <Row className="mx-3 py-2 g-border-bottom">
            <Col md="6" className="pl-1">
              <p className="pt-1 mb-0 font-weight-bold">Export Monitorees:</p>
            </Col>
            <Col md="18">
              <Form.Check
                id="currentFilterMonitoreesBtn"
                type="radio"
                size="sm"
                className="py-1"
                label={`Current Filter (${this.props.filteredMonitoreesCount})`}
                checked={!!this.state.filter}
                onChange={() => this.setState({ filter: true })}
              />
              <Form.Check
                id="allMonitoreesBtn"
                type="radio"
                size="sm"
                className="py-1"
                label={`All Monitorees (${this.props.allMonitoreesCount})`}
                checked={!this.state.filter}
                onChange={() => this.setState({ filter: false })}
              />
            </Col>
          </Row>
          <Row className="mx-3 pt-2">
            <Col md="24" className="pl-1">
              <p className="pt-1 mb-1 font-weight-bold">Export Data:</p>
            </Col>
          </Row>
          <CheckboxTree
            nodes={customExportOptions}
            checked={this.state.checked}
            expanded={this.state.expanded}
            onCheck={checked => {
              console.log(checked);
              this.setState({ checked });
            }}
            onExpand={expanded => {
              console.log(expanded);
              this.setState({ expanded });
            }}
            className="py-2"
            icons={{
              check: <i className="far fa-check-square" />,
              uncheck: <i className="far fa-square" />,
              halfCheck: <i className="far fa-minus-square" />,
              expandClose: <i className="fas fa-chevron-down" />,
              expandOpen: <i className="fas fa-chevron-right" />,
              // expandAll: <i className="fas fa-chevron-down" />,
              // collapseAll: <i className="fas fa-chevron-right" />,
              // parentClose: <i className="fal fa-chevron-down" />,
              // parentOpen: <i className="fal fa-chevron-right" />,
              // leaf: <i className="fas fa-leaf" />,
            }}
          />
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
  preset: PropTypes.string,
  query: PropTypes.object,
  allMonitoreesCount: PropTypes.number,
  filteredMonitoreesCount: PropTypes.number,
  onClose: PropTypes.func,
};

export default CustomExport;
