import React from 'react';
import { PropTypes } from 'prop-types';

class CurrentStatus extends React.Component {
  constructor(props) {
    super(props);
  }

  generateStatus(status) {
    if (status === 'symptomatic') {
      return <span className="text-danger">symptomatic</span>;
    } else if (status === 'asymptomatic') {
      return <span className="text-success">asymptomatic</span>;
    } else if (status === 'non_reporting') {
      return <span className="text-warning">non-reporting</span>;
    } else if (status === 'pui') {
      return <span className="text-dark">PUI</span>;
    } else if (status === 'purged') {
      return <span className="text-muted">purged</span>;
    } else if (status === 'closed') {
      return <span className="text-secondary">not currently being monitored</span>;
    } else if (status === 'isolation_requiring_review') {
      return <span className="text-danger">requires review</span>;
    } else if (status === 'isolation_non_test_based') {
      return <span className="text-danger">requires review (non test based)</span>;
    } else if (status === 'isolation_test_based') {
      return <span className="text-danger">requires review (test based)</span>;
    } else if (status === 'isolation_non_reporting') {
      return <span className="text-warning">non-reporting</span>;
    } else if (status === 'isolation_reporting') {
      return <span className="text-success">reporting</span>;
    } else {
      return <span>unknown</span>;
    }
  }

  render() {
    return (
      <React.Fragment>
        {!this.props.isolation && (
          <h1 className="display-6 pb-3">
            This monitoree is in the <u>exposure</u> workflow, and their current status is <b>{this.generateStatus(this.props.status)}</b>.
          </h1>
        )}
        {this.props.isolation && (
          <h1 className="display-6 pb-3">
            This monitoree is in the <u>isolation</u> workflow, and their current status is <b>{this.generateStatus(this.props.status)}</b>.
          </h1>
        )}
      </React.Fragment>
    );
  }
}

CurrentStatus.propTypes = {
  status: PropTypes.string,
  isolation: PropTypes.bool,
};

export default CurrentStatus;
