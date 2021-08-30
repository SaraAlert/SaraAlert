import React from 'react';
import { PropTypes } from 'prop-types';
import { Alert, Col, Row } from 'react-bootstrap';
import moment from 'moment';
import { formatDate } from '../../../../utils/DateTime';

import ExtendedIsolation from './ExtendedIsolation';
import InfoTooltip from '../../../util/InfoTooltip';
import LastDateExposure from './LastDateExposure';
import SymptomOnset from './SymptomOnset';

class MonitoringPeriod extends React.Component {
  constructor(props) {
    super(props);
  }

  formatEndOfMonitoringDate = () => {
    const eom = this.props.patient.linelist.end_of_monitoring;
    return eom === 'Continuous Exposure' ? eom : formatDate(eom);
  };

  renderEndOfMonitoring = () => {
    return (
      <React.Fragment>
        <span className="input-label">END OF MONITORING</span>
        <InfoTooltip
          getCustomText={() => {
            return (
              <div>
                Calculated by the system as Last Date of Exposure + {this.props.monitoring_period_days} days
                <div>
                  <i>Only relevant for Exposure Workflow</i>
                </div>
              </div>
            );
          }}
          location="right"></InfoTooltip>
        <div id="end_of_monitoring_date" className="my-1">
          {this.formatEndOfMonitoringDate()}
        </div>
      </React.Fragment>
    );
  };

  render() {
    return (
      <Row className="mt-3">
        <Col xl={{ span: this.props.patient.isolation ? 9 : 8, order: 1 }} md={{ span: 12, order: 1 }} xs={{ span: 24, order: 1 }}>
          <SymptomOnset
            authenticity_token={this.props.authenticity_token}
            patient={this.props.patient}
            symptomatic_assessments_exist={this.props.symptomatic_assessments_exist}
            num_pos_labs={this.props.num_pos_labs}
            calculated_symptom_onset={this.props.calculated_symptom_onset}
          />
        </Col>
        {!this.props.patient.isolation && (
          <Col xl={{ span: 8, order: 2 }} md={{ span: 12, order: 2 }} xs={{ span: 24, order: 3 }}>
            <LastDateExposure
              household_members={this.props.household_members}
              authenticity_token={this.props.authenticity_token}
              patient={this.props.patient}
              current_user={this.props.current_user}
              jurisdiction_paths={this.props.jurisdiction_paths}
            />
          </Col>
        )}
        <Col xl={{ span: this.props.patient.isolation ? 9 : 8, order: 3 }} md={{ span: 12, order: 3 }} xs={{ span: 24, order: 4 }}>
          {this.props.patient.isolation ? (
            <ExtendedIsolation authenticity_token={this.props.authenticity_token} patient={this.props.patient} />
          ) : (
            this.renderEndOfMonitoring()
          )}
        </Col>
        {this.props.patient.isolation && !this.props.patient.symptom_onset && !this.props.symptomatic_assessments_exist && this.props.num_pos_labs === 0 && (
          <Col xl={{ span: 9, order: 4 }} md={{ span: 12, order: 4 }} xs={{ span: 24, order: 2 }}>
            <Alert variant="warning" className="alert-warning-text">
              <b>Warning: </b>This case does not have a Symptom Onset Date or positive lab result and may never become eligible to end monitoring
            </Alert>
          </Col>
        )}
      </Row>
    );
  }
}

MonitoringPeriod.propTypes = {
  household_members: PropTypes.array,
  authenticity_token: PropTypes.string,
  monitoring_period_days: PropTypes.number,
  patient: PropTypes.object,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  symptomatic_assessments_exist: PropTypes.bool,
  num_pos_labs: PropTypes.number,
  calculated_symptom_onset: function (props) {
    if (props.calculated_symptom_onset && !moment(props.calculated_symptom_onset, 'YYYY-MM-DD').isValid()) {
      return new Error(
        'Invalid prop `calculated_symptom_onset` supplied to `DateInput`, `calculated_symptom_onset` must be a valid date string in the `YYYY-MM-DD` format.'
      );
    }
  },
};

export default MonitoringPeriod;
