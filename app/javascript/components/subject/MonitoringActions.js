import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Row, Col } from 'react-bootstrap';

import AssignedUser from './AssignedUser';
import CaseStatus from './CaseStatus';
import Jurisdiction from './Jurisdiction';
import MonitoringStatus from './MonitoringStatus';
import GenericAction from './GenericAction';

class MonitoringActions extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <React.Fragment>
        <Form className="mb-3 mt-3 px-4">
          <Row>
            <Col>
              <Form.Row className="align-items-end">
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <MonitoringStatus
                    patient={this.props.patient}
                    authenticity_token={this.props.authenticity_token}
                    has_dependents={this.props.has_dependents}
                    in_household_with_member_with_ce_in_exposure={this.props.in_household_with_member_with_ce_in_exposure}
                  />
                </Form.Group>
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <GenericAction
                    patient={this.props.patient}
                    authenticity_token={this.props.authenticity_token}
                    has_dependents={this.props.has_dependents}
                    title={'EXPOSURE RISK ASSESSMENT'}
                    monitoringAction={'exposure_risk_assessment'}
                    options={['', 'High', 'Medium', 'Low', 'No Identified Risk']}
                    tooltipKey={'exposureRiskAssessment'}
                  />
                </Form.Group>
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <GenericAction
                    patient={this.props.patient}
                    authenticity_token={this.props.authenticity_token}
                    has_dependents={this.props.has_dependents}
                    title={'MONITORING PLAN'}
                    monitoringAction={'monitoring_plan'}
                    options={[
                      'None',
                      'Daily active monitoring',
                      'Self-monitoring with public health supervision',
                      'Self-monitoring with delegated supervision',
                      'Self-observation',
                    ]}
                    tooltipKey={'monitoringPlan'}
                  />
                </Form.Group>
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <CaseStatus patient={this.props.patient} authenticity_token={this.props.authenticity_token} has_dependents={this.props.has_dependents} />
                </Form.Group>
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <GenericAction
                    patient={this.props.patient}
                    authenticity_token={this.props.authenticity_token}
                    has_dependents={this.props.has_dependents}
                    title={'LATEST PUBLIC HEALTH ACTION'}
                    monitoringAction={'public_health_action'}
                    options={['None', 'Recommended medical evaluation of symptoms', 'Document results of medical evaluation', 'Recommended laboratory testing']}
                    tooltipKey={this.props.patient.isolation ? 'latestPublicHealthActionInIsolation' : 'latestPublicHealthActionInExposure'}
                  />
                </Form.Group>
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <AssignedUser
                    patient={this.props.patient}
                    authenticity_token={this.props.authenticity_token}
                    has_dependents={this.props.has_dependents}
                    assigned_users={this.props.assigned_users}
                  />
                </Form.Group>
                <Form.Group as={Col} lg="24" className="pt-2">
                  <Jurisdiction
                    patient={this.props.patient}
                    authenticity_token={this.props.authenticity_token}
                    has_dependents={this.props.has_dependents}
                    jurisdiction_paths={this.props.jurisdiction_paths}
                    current_user={this.props.current_user}
                  />
                </Form.Group>
              </Form.Row>
            </Col>
          </Row>
        </Form>
      </React.Fragment>
    );
  }
}

MonitoringActions.propTypes = {
  current_user: PropTypes.object,
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  assigned_users: PropTypes.array,
  has_dependents: PropTypes.bool,
  in_household_with_member_with_ce_in_exposure: PropTypes.bool,
};

export default MonitoringActions;
