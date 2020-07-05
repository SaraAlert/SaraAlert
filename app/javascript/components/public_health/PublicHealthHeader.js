import React from 'react';

import { PropTypes } from 'prop-types';
import axios from 'axios';
import { Button, ButtonGroup, Dropdown, DropdownButton, Form, Modal } from 'react-bootstrap';

import Export from '../export/Export';

class PublicHealthHeader extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      counts: {},
      showImportEpixModal: false,
      showImportSafModal: false,
    };
    this.uploadFile = this.uploadFile.bind(this);
  }

  componentDidMount() {
    axios.get('/public_health/patients/counts/workflow').then(response => {
      if (response && response.data) {
        this.setState({ counts: response.data });
      }
    });
  }

  selectFileForUpload(event, type) {
    this.setState({ file: event.target.files[0], fileType: type });
  }

  uploadFile() {
    if (this.state.file && this.state.fileType) {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      const config = { headers: { 'content-type': 'multipart/form-data' } };
      const formData = new FormData();
      formData.append('file', this.state.file);
      const url = `/import/${this.props.workflow}/${this.state.fileType === 'epix' ? 'epix' : 'comprehensive_monitorees'}`;
      axios.post(url, formData, config);
    }
  }

  createModal(type, close) {
    return (
      <Modal size="md" show>
        <Modal.Header>
          {type === 'epix' && <Modal.Title as="h5">Import Epi-X</Modal.Title>}
          {type === 'saf' && <Modal.Title as="h5">Import Sara Alert Format</Modal.Title>}
          <Button variant="" className="close" onClick={close}>
            <span aria-hidden="true">&times;</span>
          </Button>
        </Modal.Header>
        <Modal.Body>
          {type === 'saf' && (
            <div className="mb-3">
              <a href="https://github.com/SaraAlert/SaraAlert/blob/master/public/Sara%20Alert%20Import%20Format.xlsx?raw=true">Download formatting guidance</a>
            </div>
          )}
          <Form inline>
            <Form.File>
              <Form.File.Input onChange={event => this.selectFileForUpload(event, type)}></Form.File.Input>
            </Form.File>
            <Button className="float-right ml-auto" disabled={!this.state.file} onClick={this.uploadFile}>
              Upload
            </Button>
          </Form>
        </Modal.Body>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <ButtonGroup>
          {this.props.abilities.analytics && (
            <Button variant="primary" className="ml-2 mb-4" href="/analytics">
              <i className="fas fa-chart-pie"></i> Analytics
            </Button>
          )}
          {this.props.abilities.enrollment && (
            <Button variant="primary" className="ml-2 mb-4" href={this.props.workflow === 'exposure' ? '/patients/new' : '/patients/new?isolation=true'}>
              <i className="fas fa-plus-square"></i> Enroll New Monitoree
            </Button>
          )}
          {this.props.abilities.export && <Export authenticity_token={this.props.authenticity_token} workflow={this.props.workflow}></Export>}
          {this.props.abilities.import && (
            <DropdownButton
              as={ButtonGroup}
              size="md"
              className="ml-2 mb-4"
              title={
                <React.Fragment>
                  <i className="fas fa-upload"></i> Import{' '}
                </React.Fragment>
              }>
              <Dropdown.Item onClick={() => this.setState({ showImportEpixModal: true })}>Epi-X</Dropdown.Item>
              <Dropdown.Item onClick={() => this.setState({ showImportSafModal: true })}>Sara Alert Format</Dropdown.Item>
            </DropdownButton>
          )}
        </ButtonGroup>

        <ButtonGroup className="float-right mb-4 mr-2">
          <Button variant={this.props.workflow === 'exposure' ? 'primary' : 'outline-primary'} href="/public_health">
            <i className="fas fa-people-arrows"></i> Exposure Monitoring {this.state.counts.exposure && <span>({this.state.counts.exposure})</span>}
          </Button>
          <Button variant={this.props.workflow === 'isolation' ? 'primary' : 'outline-primary'} href="/public_health/isolation">
            <i className="fas fa-house-user"></i> Isolation Monitoring {this.state.counts.isolation && <span>({this.state.counts.isolation})</span>}
          </Button>
        </ButtonGroup>

        {this.state.showImportEpixModal &&
          this.createModal('epix', () => {
            this.setState({ showImportEpixModal: false });
          })}
        {this.state.showImportSafModal &&
          this.createModal('saf', () => {
            this.setState({ showImportSafModal: false });
          })}
      </React.Fragment>
    );
  }
}

PublicHealthHeader.propTypes = {
  authenticity_token: PropTypes.string,
  workflow: PropTypes.oneOf(['exposure', 'isolation']),
  abilities: PropTypes.exact({
    analytics: PropTypes.bool,
    enrollment: PropTypes.bool,
    export: PropTypes.bool,
    import: PropTypes.bool,
  }),
};

export default PublicHealthHeader;
