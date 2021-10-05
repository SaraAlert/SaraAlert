import React from 'react';
import axios from 'axios';
import { PropTypes } from 'prop-types';
import { Form, Row, Col, Button, Modal } from 'react-bootstrap';
import reportError from '../../../util/ReportError';
import { formatNameAlt } from '../../../../utils/PatientFormatters';

class ChangeHoH extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      disabled: true,
      showModal: false,
      loading: false,
      hoh_selection: null,
    };
  }

  toggleModal = () => {
    let current = this.state.showModal;
    this.setState({
      disabled: true,
      showModal: !current,
      hoh_selection: null,
    });
  };

  handleChange = event => {
    this.setState({ [event.target.id]: event.target.value, disabled: false });
  };

  submit = () => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/update_hoh', {
          new_hoh_id: this.state.hoh_selection,
        })
        .then(() => {
          this.setState({ disabled: false }, () => {
            location.reload();
          });
        })
        .catch(err => {
          reportError(err?.response?.data?.error ? err.response.data.error : err, false);
        });
    });
  };

  createModal() {
    return (
      <Modal size="lg" show centered onHide={this.toggleModal}>
        <Modal.Header>
          <Modal.Title>Edit Head of Household</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Form.Group as={Col}>
                <Form.Label htmlFor="hoh_selection" className="input-label">
                  Select The New Head Of Household
                </Form.Label>
                <Form.Label size="sm" className="input-label">
                  Note: The selected monitoree will become the responder for the current monitoree and all others within the list
                </Form.Label>
                <Form.Control as="select" className="form-control-lg" id="hoh_selection" onChange={this.handleChange} defaultValue={-1}>
                  <option value={-1} disabled>
                    --
                  </option>
                  {this.props?.dependents?.map((member, index) => {
                    return (
                      <option key={`option-${index}`} value={member.id}>
                        {formatNameAlt(member)}
                      </option>
                    );
                  })}
                </Form.Control>
              </Form.Group>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.toggleModal}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={this.submit} disabled={this.state.disabled || this.state.loading}>
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
        <Button size="sm" className="my-2 mr-2" onClick={this.toggleModal}>
          <i className="fas fa-house-user"></i> Change Head of Household
        </Button>
        {this.state.showModal && this.createModal()}
      </React.Fragment>
    );
  }
}

ChangeHoH.propTypes = {
  patient: PropTypes.object,
  dependents: PropTypes.array,
  authenticity_token: PropTypes.string,
};

export default ChangeHoH;
