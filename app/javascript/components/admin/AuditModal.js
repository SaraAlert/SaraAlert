import React from 'react';
import { Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import { ToastContainer, toast } from 'react-toastify';
import { Spinner, Table } from 'react-bootstrap';
import axios from 'axios';
import moment from 'moment-timezone';
import _ from 'lodash';

class AuditModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      show: false,
      loading: false,
      events: [],
    };
  }

  hide = () => {
    this.setState({ loading: false }, () => {
      this.props.onClose();
    });
  };

  componentDidMount() {
    this.setState({ loading: true }, () => {
      axios
        .get(window.BASE_PATH + '/users/audits/' + this.props.user.id)
        .then(response => {
          this.setState({ loading: false, events: response.data });
        })
        .catch(() => {
          toast.error('Failed to fetch user audit events.', {
            autoClose: 2000,
            position: toast.POSITION.TOP_CENTER,
          });
          this.setState({ loading: false });
        });
    });
  }

  formatTimestamp = timestamp => {
    const ts = moment.tz(timestamp, 'UTC');
    return ts.isValid() ? ts.tz(moment.tz.guess()).format('MM/DD/YYYY HH:mm z') : '';
  };

  renderChange = change => {
    return (
      <React.Fragment>
        {change.jurisdiction_id && (
          <React.Fragment>
            <b>Jurisdiction:</b>&nbsp;
            {_.invert(this.props.jurisdiction_paths)[change.jurisdiction_id[0]]}
            <i className="mx-2 fas fa-arrow-right"></i>
            {_.invert(this.props.jurisdiction_paths)[change.jurisdiction_id[1]]}
          </React.Fragment>
        )}
        {change.role && (
          <React.Fragment>
            <b>Role:</b>&nbsp;
            {_.startCase(change.role[0])}
            <i className="mx-2 fas fa-arrow-right"></i>
            {_.startCase(change.role[1])}
          </React.Fragment>
        )}
        {change.locked_at && (
          <React.Fragment>
            <b>Status:</b>&nbsp;
            {change.locked_at[0] && (
              <span>
                Locked<i className="mx-2 fas fa-arrow-right"></i>Unlocked
              </span>
            )}
            {!change.locked_at[0] && (
              <span>
                Unlocked<i className="mx-2 fas fa-arrow-right"></i>Locked
              </span>
            )}
          </React.Fragment>
        )}
        {change.api_enabled && (
          <React.Fragment>
            <b>API Enabled:</b>&nbsp;
            {change.api_enabled[0] && (
              <span>
                Yes<i className="mx-2 fas fa-arrow-right"></i>No
              </span>
            )}
            {!change.api_enabled[0] && (
              <span>
                No<i className="mx-2 fas fa-arrow-right"></i>Yes
              </span>
            )}
          </React.Fragment>
        )}
        {change.email && (
          <React.Fragment>
            <b>Email:</b>&nbsp;
            {change.email[0]}
            <i className="mx-2 fas fa-arrow-right"></i>
            {change.email[1]}
          </React.Fragment>
        )}
        {change.authy_enabled && (
          <React.Fragment>
            <b>2FA Enabled:</b>&nbsp;
            {change.authy_enabled[0] && (
              <span>
                Yes<i className="mx-2 fas fa-arrow-right"></i>No
              </span>
            )}
            {!change.authy_enabled[0] && (
              <span>
                No<i className="mx-2 fas fa-arrow-right"></i>Yes
              </span>
            )}
          </React.Fragment>
        )}
        {change.force_password_change && (
          <React.Fragment>
            <b>Password Changed/Reset</b>
          </React.Fragment>
        )}
        {change.last_sign_in_with_authy && (
          <React.Fragment>
            <b>User Signed In</b>
          </React.Fragment>
        )}
      </React.Fragment>
    );
  };

  renderEvent = (event, index) => {
    return (
      <tr key={`${index}${this.props.user.id}ae`}>
        <td>{event.user}</td>
        <td>{this.renderChange(event.change)}</td>
        <td>{this.formatTimestamp(event.when)}</td>
      </tr>
    );
  };

  render() {
    return (
      <React.Fragment>
        <Modal show={this.props.show} onHide={this.hide} dialogClassName="modal-am" aria-labelledby="contained-modal-title-vcenter" centered>
          <Modal.Header closeButton>
            <Modal.Title>Audit Events for {this.props.user.email}</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            {this.state.loading && (
              <div className="text-center">
                <Spinner variant="secondary" animation="border" size="lg" />
              </div>
            )}
            <Table striped bordered size="sm">
              <thead>
                <tr>
                  <th>Who</th>
                  <th>What</th>
                  <th>When</th>
                </tr>
              </thead>
              <tbody>
                {this.state.events.map((event, index) => {
                  return this.renderEvent(event, index);
                })}
                {this.state.events.length === 0 && (
                  <tr>
                    <td colSpan="3">No Events Found.</td>
                  </tr>
                )}
              </tbody>
            </Table>
          </Modal.Body>
          <Modal.Footer>
            <Button variant="secondary btn-square" onClick={this.hide}>
              Close
            </Button>
          </Modal.Footer>
        </Modal>
        <ToastContainer />
      </React.Fragment>
    );
  }
}

AuditModal.propTypes = {
  user: PropTypes.object,
  onClose: PropTypes.func,
  show: PropTypes.bool,
  jurisdiction_paths: PropTypes.object,
};

export default AuditModal;
