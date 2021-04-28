import React from 'react';
import { PropTypes } from 'prop-types';
import { Col, Row } from 'react-bootstrap';
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

  render() {
    return (
      <Row>
        <Col sm={8}>
          <SymptomOnset
            authenticity_token={this.props.authenticity_token}
            patient={this.props.patient}
            symptomatic_assessments_exist={this.props.symptomatic_assessments_exist}
          />
        </Col>
        {!this.props.patient.isolation && (
          <Col sm={8}>
            <LastDateExposure
              household_members={this.props.household_members}
              authenticity_token={this.props.authenticity_token}
              patient={this.props.patient}
              current_user={this.props.current_user}
              jurisdiction_paths={this.props.jurisdiction_paths}
            />
          </Col>
        )}
        <Col sm={8}>
          {this.props.patient.isolation ? (
            <ExtendedIsolation authenticity_token={this.props.authenticity_token} patient={this.props.patient} />
          ) : (
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
              <div className="my-1">{this.formatEndOfMonitoringDate()}</div>
            </React.Fragment>
          )}
        </Col>
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
};

export default MonitoringPeriod;
