import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, ButtonGroup, Col, Dropdown, DropdownButton, Form, Modal, ProgressBar, Row } from 'react-bootstrap';
import axios from 'axios';

import Export from './Export';
import Import from './Import';
import confirmDialog from '../util/ConfirmDialog';
import { navQueryParam } from '../../utils/Navigation';

class PublicHealthHeader extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      counts: {},
      showUploadModal: false,
      showImportModal: false,
      showWarningModal: false,
      uploading: false,
    };
  }

  componentDidMount() {
    axios.get(window.BASE_PATH + '/public_health/patients/counts/workflow').then(response => {
      if (response && response.data) {
        this.setState({ counts: response.data });
      }
    });
  }

  selectFileForUpload(event, type) {
    this.setState({ file: event.target.files[0], fileType: type });
  }

  uploadFile = () => {
    if (this.state.file && this.state.fileType) {
      this.setState({ uploading: true }, () => {
        axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
        const config = { headers: { 'content-type': 'multipart/form-data' } };
        const formData = new FormData();
        formData.append('file', this.state.file);
        const url = `${window.BASE_PATH}/import/${this.props.workflow}/${this.state.fileType}`;
        axios.post(url, formData, config).then(response => {
          this.setState({
            uploading: false,
            importData: response.data,
            file: null,
            showUploadModal: false,
            showWarningModal: Object.keys(response.data.warnings).length > 0 && response.data.errors.length === 0,
            showImportModal: Object.keys(response.data.warnings).length === 0 || response.data.errors.length > 0,
          });
        });
      });
    }
  };

  renderImportModal() {
    return (
      <Modal
        dialogClassName="modal-import"
        backdrop={this.state.importData?.errors?.length > 0 ? true : 'static'}
        scrollable="true"
        show={this.state.showImportModal}
        onHide={async () => {
          if (this.state.importData.errors.length > 0) {
            this.setState({ showImportModal: false, importType: null, importData: null });
          } else if (this.importComponent.state.progress > 0) {
            this.importComponent.stopImport('X');
          } else if (this.importComponent.state.accepted.length > 0) {
            const confirmText = 'You are about to stop the import process. Are you sure you want to do this?';
            const options = {
              title: 'Stop Import',
              okLabel: 'Proceed to Stop',
              cancelLabel: 'Return to Import',
              additionalNote: 'Records imported prior to clicking "X" will not be deleted from the system.',
            };
            if (await confirmDialog(confirmText, options)) {
              location.href = `${window.BASE_PATH}/public_health/${this.props.workflow}`;
            }
          } else {
            const confirmText = 'You are about to cancel the import process. Are you sure you want to do this?';
            const options = {
              title: 'Cancel Import',
              okLabel: 'Proceed to Cancel',
              cancelLabel: 'Return to Import',
            };
            if (await confirmDialog(confirmText, options)) {
              this.setState({ showImportModal: false, importType: null, importData: null });
            }
          }
        }}>
        <Modal.Header closeButton>
          {this.state.importData && (
            <React.Fragment>
              <Modal.Title className="h5">
                {this.state.importType === 'saf' && 'Import Sara Alert Format'}
                {this.state.importType === 'epix' && 'Import Epi-X'}
                {this.state.importType === 'sdx' && 'Import SDX'} {this.state.importData.errors.length === 0 ? this.props.workflow : '(error)'}
              </Modal.Title>
            </React.Fragment>
          )}
        </Modal.Header>
        <Modal.Body>
          {this.state.importData && this.state.importData.patients && this.state.importData.errors && (
            <Import
              workflow={this.props.workflow}
              patients={this.state.importData.patients}
              errors={this.state.importData.errors}
              authenticity_token={this.props.authenticity_token}
              ref={instance => {
                this.importComponent = instance;
              }}
              showWarningModal={this.state.showWarningModal}
            />
          )}
        </Modal.Body>
      </Modal>
    );
  }

  renderUploadModal() {
    return (
      <Modal size="md" show={this.state.showUploadModal} onHide={() => this.setState({ showUploadModal: false, file: null, importType: null })}>
        <Modal.Header closeButton>
          <Modal.Title>
            {this.state.importType === 'epix' && 'Import Epi-X'}
            {this.state.importType === 'saf' && 'Import Sara Alert Format'}
            {this.state.importType === 'sdx' && 'Import SDX'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {this.state.importType === 'saf' && (
            <div className="mb-3">
              <a href={`${window.location.origin}/Sara%20Alert%20Import%20Format.xlsx`}>Download formatting guidance</a> (Updated 12/28/2021)
            </div>
          )}
          <Form inline>
            <Form.File>
              <Form.File.Input onChange={event => this.selectFileForUpload(event, this.state.importType)}></Form.File.Input>
            </Form.File>
            <Button className="float-right ml-auto" disabled={!this.state.file} onClick={this.uploadFile}>
              <i className="fas fa-upload"></i> Upload
            </Button>
          </Form>
          {this.state.uploading && <ProgressBar animated striped now={100} className="mt-3" />}
        </Modal.Body>
      </Modal>
    );
  }

  renderWarningModal() {
    return (
      <Modal
        centered
        dialogClassName="modal-import"
        className="import-warning-modal-container"
        scrollable="true"
        backdrop="static"
        size="lg"
        show={this.state.showWarningModal}
        onHide={async () => {
          this.setState({ showWarningModal: false, importType: null, importData: null });
        }}>
        <Modal.Header closeButton>
          <Modal.Title className="h5">{this.state.importType === 'epix' ? 'Import Epi-X' : 'Import Sara Alert Format'} Warning</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {this.state.importData?.warnings &&
            Object.keys(this.state.importData.warnings).map(key => (
              <span key={key}>
                <label className="h5">{key}</label>
                <p>{this.state.importData.warnings[`${key}`]}</p>
              </span>
            ))}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={() => this.setState({ showWarningModal: false, importType: null, importData: null })}>
            Cancel Import
          </Button>
          <Button variant="primary" onClick={() => this.setState({ showWarningModal: false, showImportModal: true })}>
            Continue
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Row className="mx-2 my-2">
          <Col className="p-0">
            <ButtonGroup>
              {this.props.abilities.enrollment && (
                <Button
                  variant="primary"
                  className="mb-2"
                  href={`${window.BASE_PATH}/patients/new?${this.props.workflow === 'isolation' ? 'isolation=true' : ''}${navQueryParam(
                    this.props.workflow,
                    false
                  )}`}>
                  {(this.props.workflow === 'exposure' || this.props.workflow === 'global') && (
                    <span>
                      <i className="fas fa-user-plus"></i> Enroll New Monitoree
                    </span>
                  )}
                  {this.props.workflow === 'isolation' && (
                    <span>
                      <i className="fas fa-user-plus"></i> Enroll New Case
                    </span>
                  )}
                </Button>
              )}
              {this.props.abilities.export && (
                <Export
                  authenticity_token={this.props.authenticity_token}
                  jurisdiction_paths={this.props.jurisdiction_paths}
                  all_assigned_users={this.props.all_assigned_users}
                  all_cohort_names={this.props.all_cohort_names}
                  all_cohort_locations={this.props.all_cohort_locations}
                  jurisdiction={this.props.jurisdiction}
                  tabs={this.props.tabs}
                  workflow={this.props.workflow}
                  query={this.props.query}
                  all_monitorees_count={this.state.counts.exposure + this.state.counts.isolation}
                  current_monitorees_count={this.props.current_monitorees_count}
                  custom_export_options={this.props.custom_export_options}
                />
              )}
              {this.props.abilities.import && (
                <DropdownButton
                  as={ButtonGroup}
                  size="md"
                  className="ml-2 mb-2"
                  title={
                    <React.Fragment>
                      <i className="fas fa-upload"></i> Import{' '}
                    </React.Fragment>
                  }>
                  <Dropdown.Item id="import-saf" onClick={() => this.setState({ importType: 'saf', showUploadModal: true })}>
                    Sara Alert Format ({this.props.workflow})
                  </Dropdown.Item>
                  <Dropdown.Item id="import-epix" onClick={() => this.setState({ importType: 'epix', showUploadModal: true })}>
                    Epi-X ({this.props.workflow})
                  </Dropdown.Item>
                  <Dropdown.Item id="import-sdx" onClick={() => this.setState({ importType: 'sdx', showUploadModal: true })}>
                    SDX ({this.props.workflow})
                  </Dropdown.Item>
                </DropdownButton>
              )}
            </ButtonGroup>
            <ButtonGroup className="float-right mb-2">
              <Button
                id="exposure-nav-btn"
                variant={this.props.workflow === 'exposure' ? 'primary' : 'outline-primary'}
                href={`${window.BASE_PATH}/public_health/exposure`}>
                <i className="fas fa-people-arrows"></i> Exposure <span className="d-none d-xl-inline"> Monitoring</span>{' '}
                {this.state.counts.exposure !== undefined && <span id="exposureCount">({this.state.counts.exposure})</span>}
              </Button>
              <Button
                id="isolation-nav-btn"
                variant={this.props.workflow === 'isolation' ? 'primary' : 'outline-primary'}
                href={`${window.BASE_PATH}/public_health/isolation`}>
                <i className="fas fa-street-view"></i> Isolation <span className="d-none d-xl-inline"> Monitoring</span>{' '}
                {this.state.counts.isolation !== undefined && <span id="isolationCount">({this.state.counts.isolation})</span>}
              </Button>
              <Button
                id="global-nav-btn"
                variant={this.props.workflow === 'global' ? 'primary' : 'outline-primary'}
                href={`${window.BASE_PATH}/public_health/global`}>
                <i className="fas fa-globe"></i> Global<span className="d-none d-xl-inline"> Dashboard</span>{' '}
                {this.state.counts.exposure !== undefined && <span id="globalCount">({this.state.counts.global})</span>}
              </Button>
            </ButtonGroup>
          </Col>
        </Row>
        {this.renderUploadModal()}
        {this.renderImportModal()}
        {this.renderWarningModal()}
      </React.Fragment>
    );
  }
}

PublicHealthHeader.propTypes = {
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  all_assigned_users: PropTypes.array,
  all_cohort_names: PropTypes.array,
  all_cohort_locations: PropTypes.array,
  workflow: PropTypes.oneOf(['global', 'exposure', 'isolation']),
  jurisdiction: PropTypes.object,
  tabs: PropTypes.object,
  abilities: PropTypes.exact({
    analytics: PropTypes.bool,
    enrollment: PropTypes.bool,
    export: PropTypes.bool,
    import: PropTypes.bool,
  }),
  query: PropTypes.object,
  current_monitorees_count: PropTypes.number,
  custom_export_options: PropTypes.object,
};

export default PublicHealthHeader;
