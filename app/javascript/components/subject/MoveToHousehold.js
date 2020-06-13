import React from 'react';
import { Form, Row, Col, Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';

class MoveToHousehold extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      updateDisabled: true,
      showModal: false,
      loading: false,
    };
    this.toggleModal = this.toggleModal.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.submit = this.submit.bind(this);
  }

  toggleModal() {
    let current = this.state.showModal;
    this.setState({
      updateDisabled: true,
      showModal: !current,
    });
  }

  handleChange(event) {
    this.setState({ [event.target.id]: event.target.value, updateDisabled: false });
  }

  submit() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/update_hoh', {
          new_hoh_id: this.state.hoh_selection,
          household_ids: this.props?.groupMembers?.map(member => {
            return member.id;
          }),
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
      <Modal size="lg" show centered>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Select The New Monitoree That Will Respond For The Current Monitoree</Form.Label>
                <Form.Label size="sm" className="nav-input-label">
                  Note: The current monitoree will be moved into the selected monitorees household
                </Form.Label>
                <Form.Control as="select" className="form-control-lg" id="hoh_selection" onChange={this.handleChange} defaultValue={-1}>
                  <option value={-1} disabled>
                    --
                  </option>
                  {this.props?.groupMembers?.map((member, index) => {
                    return (
                      <option key={`option-${index}`} value={member.id}>
                        {member.last_name}, {member.first_name} {member.middle_name || ''}
                      </option>
                    );
                  })}
                </Form.Control>
              </Form.Group>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.updateDisabled || this.state.loading}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Update
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
  groupMembers: PropTypes.array,
  authenticity_token: PropTypes.string,
};

export default MoveToHousehold;
