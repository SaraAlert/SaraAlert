import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Row, Col, Button, Modal } from 'react-bootstrap';
import axios from 'axios';

import reportError from '../util/ReportError';

class MoveToHousehold extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      updateDisabled: true,
      showModal: false,
      loading: false,
      groupMembers: [],
    };
    this.toggleModal = this.toggleModal.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.submit = this.submit.bind(this);
    this.getResponders = this.getResponders.bind(this);
  }

  toggleModal() {
    let current = this.state.showModal;
    this.setState({
      updateDisabled: true,
      showModal: !current,
      loading: !current,
    });
    if (!current) {
      this.getResponders();
    }
  }

  handleChange(event) {
    let updateDisabled = true;
    if (event.target.id == 'hoh_selection') {
      updateDisabled = event.target.value === -1;
    }
    this.setState({ [event.target.id]: event.target.value, updateDisabled: updateDisabled });
  }

  getResponders() {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios({
      method: 'get',
      url: window.BASE_PATH + '/patients/households/self_reporting',
      params: {},
    })
      .then(response => {
        this.setState({
          loading: false,
          groupMembers: JSON.parse(response['data']['self_reporting']),
        });
      })
      .catch(err => {
        reportError(err);
      });
  }

  submit() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/update_hoh', {
          new_hoh_id: this.state.hoh_selection,
        })
        .then(() => {
          this.setState({ updateDisabled: false });
          location.reload(true);
        })
        .catch(error => {
          console.error(error);
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
                <Form.Label className="nav-input-label">Select The New Monitoree That Will Respond For The Current Monitoree</Form.Label>
                <Form.Label size="sm" className="nav-input-label">
                  Note: The current monitoree will be moved into the selected monitoree&apos;s household
                </Form.Label>
                <Form.Control as="select" className="form-control-lg" id="hoh_selection" onChange={this.handleChange} defaultValue={-1}>
                  <option value={-1} disabled>
                    --
                  </option>
                  {this.state?.groupMembers?.map((member, index) => {
                    return (
                      <option key={`option-${index}`} value={member.id}>
                        {member.last_name}, {member.first_name} Age: {member.age}, State ID: {member.state_id}
                      </option>
                    );
                  })}
                </Form.Control>
              </Form.Group>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.updateDisabled || this.state.loading}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Update
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Button size="sm" className="my-2" onClick={this.toggleModal}>
          <i className="fas fa-house-user"></i> Move To Household
        </Button>
        {this.state.showModal && this.createModal('Move To Household', this.toggleModal, this.submit)}
      </React.Fragment>
    );
  }
}

MoveToHousehold.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default MoveToHousehold;
