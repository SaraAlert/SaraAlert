import React from 'react';
import { PropTypes } from 'prop-types';
import { Badge } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import EligibilityTooltip from '../util/EligibilityTooltip';

class CurrentStatus extends React.Component {
  constructor(props) {
    super(props);
  }

  generateStatus(status) {
    if (status === 'exposure_symptomatic') {
      return <Badge variant="danger">symptomatic</Badge>;
    } else if (status === 'exposure_asymptomatic') {
      return <Badge variant="success">asymptomatic</Badge>;
    } else if (status === 'exposure_non_reporting') {
      return <Badge variant="warning">non-reporting</Badge>;
    } else if (status === 'exposure_under_investigation') {
      return <Badge variant="dark">PUI</Badge>;
    } else if (status === 'purged') {
      // FIX ME
      return <Badge variant="muted">purged</Badge>;
    } else if (status === 'closed') {
      return <Badge variant="secondary">not currently being monitored</Badge>;
    } else if (status === 'isolation_requiring_review') {
      return <Badge variant="danger">requires review</Badge>;
    } else if (status === 'isolation_symp_non_test_based') {
      return (
        <Badge variant="danger" data-for={`symptomatic-non-test-based`} data-tip="">
          requires review (symptomatic non test based)
        </Badge>
      );
    } else if (status === 'isolation_asymp_non_test_based') {
      return (
        <Badge variant="danger" data-for={`aymptomatic-non-test-based`} data-tip="">
          requires review (asymptomatic non test based)
        </Badge>
      );
    } else if (status === 'isolation_test_based') {
      return (
        <Badge variant="danger" data-for={`test-based`} data-tip="">
          requires review (test based)
        </Badge>
      );
    } else if (status === 'isolation_non_reporting') {
      return <Badge variant="warning">non-reporting</Badge>;
    } else if (status === 'isolation_reporting') {
      return <Badge variant="success">reporting</Badge>;
    } else {
      return <span>unknown</span>;
    }
  }

  generateStatusTooltip(status) {
    if (status === 'isolation_symp_non_test_based') {
      return (
        <ReactTooltip id={`symptomatic-non-test-based`} multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
          <span>
            At least 10 days have passed since the symptom onset date and at least 24 hours have passed since the case last reported “Yes” for fever or use of
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

  render() {
    return (
      <React.Fragment>
        <h4 className="pb-3">
          <b>
            {this.props.isolation ? 'Isolation' : 'Exposure'} Workflow: {this.generateStatus(this.props.status)}
            {this.generateStatusTooltip(this.props.status)}
            {'  |  '}Notification status is <EligibilityTooltip report_eligibility={this.props.report_eligibility} id={`eltt`} inline={true} />
          </b>
        </h4>
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
