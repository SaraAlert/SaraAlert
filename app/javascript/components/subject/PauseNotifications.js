import React from 'react';
import { PropTypes } from 'prop-types';
import { Button } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import axios from 'axios';

import confirmDialog from '../util/ConfirmDialog';
import reportError from '../util/ReportError';

class PauseNotifications extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      loading: false,
      disableAndDisplayTooltip: props.patient.id !== props.patient.responder_id || !props.patient.monitoring,
    };
  }

  submit = () => {
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
  };

  handleSubmit = async confirmText => {
    if (await confirmDialog(confirmText)) {
      this.submit();
    }
  };

  renderTooltip() {
    const notificationsAction = this.props.patient.pause_notifications ? 'resumed' : 'paused';
    let text = '';
    // monitoree record is closed
    if (!this.props.patient.monitoring) {
      text = `Notifications cannot be ${notificationsAction} for records on the Closed line list. You may update this field after changing Monitoring Status to "Actively Monitoring"`;
      // monitoree is a HH dependent
    } else if (this.props.patient.id !== this.props.patient.responder_id) {
      text = `Notifications cannot be ${notificationsAction} because the monitoree is within a Household, so the Head of Household will receive notifications instead. If notifications to the Head of Household should be ${notificationsAction}, you may update this field on the Head of Household record.`;
    }
    return (
      <ReactTooltip id={`notifications-tooltip`} multiline={true} place="bottom" type="dark" effect="solid" className="tooltip-container mt-3">
        <span>{text}</span>
      </ReactTooltip>
    );
  }

  render() {
    return (
      <React.Fragment>
        <span data-for="notifications-tooltip" data-tip="">
          <Button
            id="notifications_action"
            className="mr-2"
            disabled={this.state.disableAndDisplayTooltip || this.state.loading}
            onClick={() =>
              this.handleSubmit(
                this.props.patient.pause_notifications
                  ? `You are about to change this monitoree's notification status to resumed. This means that the system will start sending the monitoree symptom report requests during their preferred reporting time until they are no longer eligible or notifications are paused by a user.`
                  : `You are about to change this monitoree's notification status to paused. This means that the system will stop sending the monitoree symptom report requests until notifications are resumed by a user.`
              )
            }>
            {this.props.patient.pause_notifications && (
              <span>
                <i className="fas fa-play"></i> Resume Notifications
              </span>
            )}
            {!this.props.patient.pause_notifications && (
              <span>
                <i className="fas fa-pause"></i> Pause Notifications
              </span>
            )}
            {this.state.loading && (
              <React.Fragment>
                &nbsp;<span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
              </React.Fragment>
            )}
          </Button>
        </span>
        {this.state.disableAndDisplayTooltip && this.renderTooltip()}
      </React.Fragment>
    );
  }
}

PauseNotifications.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default PauseNotifications;
