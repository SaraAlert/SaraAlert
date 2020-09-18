import React from 'react';
import { PropTypes } from 'prop-types';
import { Button } from 'react-bootstrap';
import axios from 'axios';

import confirmDialog from '../util/ConfirmDialog';
import reportError from '../util/ReportError';

class PauseNotifications extends React.Component {
  constructor(props) {
    super(props);
    this.submit = this.submit.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.state = {
      loading: false,
    };
  }

  submit() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          comment: false,
          pause_notifications: !this.props.patient.pause_notifications,
          diffState: ['pause_notifications'],
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  }

  handleSubmit = async confirmText => {
    if (await confirmDialog(confirmText)) {
      this.submit();
    }
  };

  render() {
    return (
      <React.Fragment>
        {!this.props.patient.pause_notifications && (
          <Button
            id="pause_notifications"
            className="mr-2"
            disabled={this.state.loading}
            onClick={() =>
              this.handleSubmit(
                "You are about to change this monitoree's notification status to paused. This means that the system will stop sending the monitoree symptom report requests until notifications are resumed by a user."
              )
            }>
            <i className="fas fa-pause"></i> Pause Notifications
            {this.state.loading && (
              <React.Fragment>
                &nbsp;<span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
              </React.Fragment>
            )}
          </Button>
        )}
        {this.props.patient.pause_notifications && (
          <Button
            id="pause_notifications"
            className="mr-2"
            disabled={this.state.loading}
            onClick={() =>
              this.handleSubmit(
                "You are about to change this monitoree's notification status to resumed. This means that the system will start sending the monitoree symptom report requests unless notifications are paused by a user or the record is closed."
              )
            }>
            <i className="fas fa-play"></i> Resume Notifications
            {this.state.loading && (
              <React.Fragment>
                &nbsp;<span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
              </React.Fragment>
            )}
          </Button>
        )}
      </React.Fragment>
    );
  }
}

PauseNotifications.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default PauseNotifications;
