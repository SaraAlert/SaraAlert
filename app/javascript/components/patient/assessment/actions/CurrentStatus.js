import React from 'react';
import { PropTypes } from 'prop-types';
import { Badge } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import EligibilityTooltip from '../../../util/EligibilityTooltip';

class CurrentStatus extends React.Component {
  constructor(props) {
    super(props);
  }

  renderStatus(status) {
    if (status === 'exposure_symptomatic') {
      return (
        <Badge variant="danger" className="badge-larger-font" aria-label="Linelist: Symptomatic.">
          symptomatic
        </Badge>
      );
    } else if (status === 'exposure_asymptomatic') {
      return (
        <Badge variant="success" className="badge-larger-font" aria-label="Linelist: Asymptomatic.">
          asymptomatic
        </Badge>
      );
    } else if (status === 'exposure_non_reporting') {
      return (
        <Badge variant="warning" className="badge-larger-font" aria-label="Linelist: Non Reporting.">
          non-reporting
        </Badge>
      );
    } else if (status === 'exposure_under_investigation') {
      return (
        <Badge variant="dark" className="badge-larger-font" aria-label="Linelist: Under Investigation.">
          PUI
        </Badge>
      );
    } else if (status === 'purged') {
      return (
        <Badge className="badge-muted badge-larger-font" aria-label="Linelist: Purged.">
          purged
        </Badge>
      );
    } else if (status === 'closed') {
      return (
        <Badge variant="secondary" className="badge-larger-font" aria-label="Linelist: Closed.">
          not currently being monitored
        </Badge>
      );
    } else if (status === 'isolation_requiring_review') {
      return (
        <Badge variant="danger" className="badge-larger-font" aria-label="Linelist: Requires Review.">
          requires review
        </Badge>
      );
    } else if (status === 'isolation_symp_non_test_based') {
      return (
        <Badge
          variant="danger"
          className="badge-larger-font"
          aria-label="Linelist: Symptomatic Non Test Based."
          data-for={`symptomatic-non-test-based`}
          data-tip="">
          requires review (symptomatic non test based)
        </Badge>
      );
    } else if (status === 'isolation_asymp_non_test_based') {
      return (
        <Badge
          variant="danger"
          className="badge-larger-font"
          aria-label="Linelist: Asymptomatic Non Test Based."
          data-for={`aymptomatic-non-test-based`}
          data-tip="">
          requires review (asymptomatic non test based)
        </Badge>
      );
    } else if (status === 'isolation_test_based') {
      return (
        <Badge variant="danger" className="badge-larger-font" aria-label="Linelist: Test Based." data-for={`test-based`} data-tip="">
          requires review (test based)
        </Badge>
      );
    } else if (status === 'isolation_non_reporting') {
      return (
        <Badge variant="warning" className="badge-larger-font" aria-label="Linelist: Non Reporting.">
          non-reporting
        </Badge>
      );
    } else if (status === 'isolation_reporting') {
      return (
        <Badge variant="success" className="badge-larger-font" aria-label="Linelist: Reporting.">
          reporting
        </Badge>
      );
    } else {
      return <span>unknown</span>;
    }
  }

  renderStatusTooltip(status) {
    if (status === 'isolation_symp_non_test_based') {
      return (
        <ReactTooltip id={`symptomatic-non-test-based`} multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
          <span>
            At least 10 days have passed since the Symptom Onset Date and at least 24 hours have passed since the case last reported “Yes” for fever or use of
            fever-reducing medicine to the system. The system does not collect information on severity of symptoms. Public health will need to validate if other
            symptoms have improved.
          </span>
        </ReactTooltip>
      );
    } else if (status === 'isolation_asymp_non_test_based') {
      return (
        <ReactTooltip id={`asymptomatic-non-test-based`} multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
          <span>
            At least 10 days have passed since the specimen collection date of a positive laboratory test and the monitoree has never reported symptoms.
          </span>
        </ReactTooltip>
      );
    } else if (status === 'isolation_test_based') {
      return (
        <ReactTooltip id={`test-based`} multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
          <span>
            Two negative laboratory results have been documented and at least 24 hours have passed since the case last reported “Yes” for fever or use of
            fever-reducing medicine to the system. The system does not validate the type of test, time between specimen collection, or if the tests were
            consecutive. Public health will need to validate that the test results meet the latest guidance prior to discontinuing isolation. The system does
            not collect information on severity of symptoms. Public health will also need to validate if other symptoms have improved.
          </span>
        </ReactTooltip>
      );
    } else {
      return null;
    }
  }

  getHeaderLabel = () => {
    let eligibilityStatus = this.props.report_eligibility.household
      ? 'In a household'
      : this.props.report_eligibility.eligible
      ? 'Eligible for notifications'
      : this.props.report_eligibility.reported
      ? 'Received a report today'
      : this.props.report_eligibility.sent
      ? 'Waiting for a response'
      : 'Not eligible for notifications';
    return `Notification Status is: ${eligibilityStatus}.`;
  };

  render() {
    return (
      <React.Fragment>
        <h2 className="tertiary-title">
          <b>
            {this.props.isolation ? 'Isolation' : 'Exposure'} Workflow: {this.renderStatus(this.props.status)}
          </b>
          {this.renderStatusTooltip(this.props.status)}
          <span className="b-border-right-3 pl-3"></span>
          <b className="pl-3" aria-label={this.getHeaderLabel()}>
            Notification status is <EligibilityTooltip report_eligibility={this.props.report_eligibility} id={`eltt`} inline={true} />
          </b>
        </h2>
      </React.Fragment>
    );
  }
}

CurrentStatus.propTypes = {
  report_eligibility: PropTypes.object,
  status: PropTypes.string,
  isolation: PropTypes.bool,
};

export default CurrentStatus;
