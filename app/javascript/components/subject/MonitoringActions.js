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
                    has_group_members={this.props.has_group_members}
                    in_a_group={this.props.in_a_group}
                    isolation={this.props.isolation}
                  />
                </Form.Group>
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <GenericAction
                    patient={this.props.patient}
                    authenticity_token={this.props.authenticity_token}
                    has_group_members={this.props.has_group_members}
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
                    has_group_members={this.props.has_group_members}
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
                  <CaseStatus
                    patient={this.props.patient}
                    authenticity_token={this.props.authenticity_token}
                    has_group_members={this.props.has_group_members}
                  />
                </Form.Group>
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <GenericAction
                    patient={this.props.patient}
                    authenticity_token={this.props.authenticity_token}
                    has_group_members={this.props.has_group_members}
                    title={'LATEST PUBLIC HEALTH ACTION'}
                    monitoringAction={'public_health_action'}
                    options={['None', 'Recommended medical evaluation of symptoms', 'Document results of medical evaluation', 'Recommended laboratory testing']}
                    tooltipKey={this.props.isolation ? 'latestPublicHealthActionInIsolation' : 'latestPublicHealthActionInExposure'}
                  />
                </Form.Group>
                <Form.Group as={Col} md="12" lg="8" className="pt-2">
                  <AssignedUser
                    patient={this.props.patient}
                    authenticity_token={this.props.authenticity_token}
                    has_group_members={this.props.has_group_members}
                    assignedUsers={this.props.assignedUsers}
                  />
                </Form.Group>
                <Form.Group as={Col} lg="24" className="pt-2">
                  <Jurisdiction
                    patient={this.props.patient}
                    authenticity_token={this.props.authenticity_token}
                    has_group_members={this.props.has_group_members}
                    jurisdictionPaths={this.props.jurisdictionPaths}
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
  jurisdictionPaths: PropTypes.object,
  assignedUsers: PropTypes.array,
  has_group_members: PropTypes.bool,
  in_a_group: PropTypes.bool,
  isolation: PropTypes.bool,
};

export default MonitoringActions;
