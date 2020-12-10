import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Row, Col, Button, Modal } from 'react-bootstrap';
import axios from 'axios';
import moment from 'moment';

import DateInput from '../util/DateInput';
import reportError from '../util/ReportError';

class Vaccine extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showModal: false,
      loading: false,
      vaccinated: this.props.vac.vaccinate || false,
      first_vac_date: this.props.vac.first_vac_date,
      second_vac_date: this.props.vac.second_vac_date,
      vaccinationInvalid: false,
    };
    this.toggleModal = this.toggleModal.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.submit = this.submit.bind(this);
  }

  toggleModal() {
    this.setState(state => {
      return {
        showModal: !state.showModal,
        loading: false,
      };
    });
  }

  handleChange(event) {
    this.setState({ [event.target.id]: event.target.value });
  }

  handleDateChange(field, date) {
    this.setState({ [field]: date }, () => {
      this.setState(state => {
        return {
          vaccinationInvalid: moment(state.second_vac_date).isBefore(state.first_vac_date, 'day'),
        };
      });
    });
  }

  submit() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/vaccines' + (this.props.vac.id ? '/' + this.props.vac.id : ' '), {
          patient_id: this.props.patient.id,
          vaccinated: this.state.vaccinated,
          first_vac_date: this.state.first_vac_date,
          second_vac_date: this.state.second_vac_date,
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  }

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered onHide={toggle}>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">First Vaccination Date</Form.Label>
                <DateInput
                  id="first_vac_date"
                  date={this.state.first_vac_date}
                  minDate={'2020-01-01'}
                  maxDate={moment().format('YYYY-MM-DD')}
                  onChange={date => this.handleDateChange('first_vac_date', date)}
                  placement="bottom"
                  customClass="form-control-lg"
                />
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Second Vaccination Date</Form.Label>
                <DateInput
                  id="second_vac_date"
                  date={this.state.second_vac_date}
                  minDate={'2020-01-01'}
                  maxDate={moment().format('YYYY-MM-DD')}
                  onChange={date => this.handleDateChange('second_vac_date', date)}
                  placement="bottom"
                  customClass="form-control-lg"
                />
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Vaccinated</Form.Label>
                <Form.Check id="vaccinated" name="vaccinated" type="switch" checked={this.state.vaccinated} onChange={this.handleVacChange} />
              </Form.Group>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
          <Button variant="primary btn-square" disable={this.state.loading || this.state.reportInvalid} onClick={submit}>
            Create
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        {!this.props.vac.id && (
          <Button onClick={this.toggleModal}>
            <i className="fas fa-plus"></i> Add New Vaccine
          </Button>
        )}
        {this.props.vac.id && (
          <Button variant="link" onClick={this.toggleModal} className="btn btn-link py-0" size="sm">
            <i className="fas fa-edit"></i> Edit
          </Button>
        )}
        {this.state.showModal && this.createModal('Vaccine', this.toggleModal, this.submit)}
      </React.Fragment>
    );
  }
}

Vaccine.propTypes = {
  vac: PropTypes.object,
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default Vaccine;
