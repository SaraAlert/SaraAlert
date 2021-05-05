import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Row, Col, Button, Modal } from 'react-bootstrap';
import axios from 'axios';
import reportError from '../../../util/ReportError';

class RemoveFromHousehold extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      removeEligible: null,
      showModal: false,
      loading: false,
    };
  }

  componentDidMount() {
    this.checkHouseholdRemoveEligible();
  }

  toggleModal = () => {
    let current = this.state.showModal;
    this.setState({
      showModal: !current,
    });
  };

  submit = () => {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/remove_from_household')
        .then(() => {
          location.reload();
        })
        .catch(err => {
          reportError(err?.response?.data?.error ? err.response.data.error : err, false);
        });
    });
  };

  checkHouseholdRemoveEligible = () => {
    let self = this;
    axios
      .get(window.BASE_PATH + '/patients/' + this.props.patient.id + '/household_removeable')
      .then(response => {
        self.setState({ removeEligible: response.data.removeable });
      })
      .catch(error => {
        console.error(error);
      });
  };

  createModal() {
    return (
      <Modal size="lg" show centered onHide={this.toggleModal}>
        <Modal.Header>
          <Modal.Title>{this.state.removeEligible == false && 'Cannot '}Remove Monitoree From Household</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Form.Group as={Col}>
                {this.state.removeEligible && (
                  <Form.Label size="sm" className="nav-input-label">
                    This monitoree will be removed from their household and will be responsible for their own responses.
                  </Form.Label>
                )}
                {this.state.removeEligible == false && (
                  <Form.Label size="sm" className="nav-input-label">
                    This monitoree cannot be removed from their household until their email and primary telephone number differ from those of the current head
                    of household.
                  </Form.Label>
                )}
              </Form.Group>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.toggleModal}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={this.submit} disabled={!this.state.removeEligible || this.state.loading}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Remove
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Button size="sm" className="my-2" onClick={this.toggleModal}>
          <i className="fas fa-house-user"></i> Remove From Household
        </Button>
        {this.state.showModal && this.createModal()}
      </React.Fragment>
    );
  }
}

RemoveFromHousehold.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default RemoveFromHousehold;
