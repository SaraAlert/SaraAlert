import React from 'react';
import { Form, Row, Col, Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';

class Laboratory extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showModal: false,
      lab_type: this.props.lab.lab_type || '',
      specimen_collection: this.props.lab.specimen_collection || '',
      report: this.props.lab.report || '',
      result: this.props.lab.result || '',
    };
    this.toggleModal = this.toggleModal.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.submit = this.submit.bind(this);
  }

  toggleModal() {
    let current = this.state.showModal;
    this.setState({
      showModal: !current,
    });
  }

  handleChange(event) {
    this.setState({ [event.target.id]: event.target.value });
  }

  submit() {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios
      .post(window.BASE_PATH + '/laboratories' + (this.props.lab.id ? '/' + this.props.lab.id : ''), {
        patient_id: this.props.patient.id,
        lab_type: this.state.lab_type,
        specimen_collection: this.state.specimen_collection,
        report: this.state.report,
        result: this.state.result,
      })
      .then(() => {
        location.href = window.BASE_PATH + '/patients/' + this.props.patient.id;
      })
      .catch(error => {
        console.error(error);
      });
  }

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Lab Test Type</Form.Label>
                <Form.Control as="select" className="form-control-lg" id="lab_type" onChange={this.handleChange} value={this.state.lab_type}>
                  <option disabled></option>
                  <option>PCR</option>
                  <option>Antigen</option>
                  <option>IgG Antibody</option>
                  <option>IgM Antibody</option>
                  <option>IgA Antibody</option>
                </Form.Control>
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Specimen Collection Date</Form.Label>
                <Form.Control
                  type="date"
                  className="form-square form-control-lg"
                  value={this.state.specimen_collection}
                  onChange={this.handleChange}
                  id="specimen_collection"
                />
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Report Date</Form.Label>
                <Form.Control type="date" className="form-square form-control-lg" value={this.state.report} onChange={this.handleChange} id="report" />
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Result</Form.Label>
                <Form.Control as="select" className="form-control-lg" id="result" onChange={this.handleChange} value={this.state.result}>
                  <option disabled></option>
                  <option>positive</option>
                  <option>negative</option>
                  <option>indeterminate</option>
                  <option>other</option>
                </Form.Control>
              </Form.Group>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="primary btn-square" onClick={submit}>
            Create
          </Button>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        {!this.props.lab.id && (
          <Button onClick={this.toggleModal}>
            <i className="fas fa-plus"></i> Add New Result
          </Button>
        )}
        {this.props.lab.id && (
          <Button variant="link" onClick={this.toggleModal} className="btn btn-link py-0" size="sm">
            <i className="fas fa-edit"></i> Edit
          </Button>
        )}
        {this.state.showModal && this.createModal('Lab Result', this.toggleModal, this.submit)}
      </React.Fragment>
    );
  }
}

Laboratory.propTypes = {
  lab: PropTypes.object,
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default Laboratory;
