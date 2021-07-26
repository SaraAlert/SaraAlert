import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Col } from 'react-bootstrap';

import AssignedUser from './AssignedUser';
import CaseStatus from './CaseStatus';
import ExposureRiskAssessment from './ExposureRiskAssessment';
import Jurisdiction from './Jurisdiction';
import MonitoringPlan from './MonitoringPlan';
import MonitoringStatus from './MonitoringStatus';
import PublicHealthAction from './PublicHealthAction';

class MonitoringActions extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <React.Fragment>
        <Form className="mb-3 mt-3 px-4">
          <Form.Row className="align-items-end">
            <Form.Group as={Col} md="12" lg="8" className="pt-2">
              <MonitoringStatus
                patient={this.props.patient}
                authenticity_token={this.props.authenticity_token}
                household_members={this.props.household_members}
                monitoring_reasons={this.props.monitoring_reasons}
                current_user={this.props.current_user}
                jurisdiction_paths={this.props.jurisdiction_paths}
                workflow={this.props.workflow}
                continuous_exposure_enabled={this.props.continuous_exposure_enabled}
              />
            </Form.Group>
            <Form.Group as={Col} md="12" lg="8" className="pt-2">
              <ExposureRiskAssessment
                patient={this.props.patient}
                authenticity_token={this.props.authenticity_token}
                household_members={this.props.household_members}
                current_user={this.props.current_user}
                jurisdiction_paths={this.props.jurisdiction_paths}
                workflow={this.props.workflow}
                continuous_exposure_enabled={this.props.continuous_exposure_enabled}
              />
            </Form.Group>
            <Form.Group as={Col} md="12" lg="8" className="pt-2">
              <MonitoringPlan
                patient={this.props.patient}
                authenticity_token={this.props.authenticity_token}
                household_members={this.props.household_members}
                current_user={this.props.current_user}
                jurisdiction_paths={this.props.jurisdiction_paths}
                workflow={this.props.workflow}
                continuous_exposure_enabled={this.props.continuous_exposure_enabled}
              />
            </Form.Group>
            <Form.Group as={Col} md="12" lg="8" className="pt-2">
              <CaseStatus
                patient={this.props.patient}
                authenticity_token={this.props.authenticity_token}
                household_members={this.props.household_members}
                monitoring_reasons={this.props.monitoring_reasons}
                current_user={this.props.current_user}
                jurisdiction_paths={this.props.jurisdiction_paths}
                workflow={this.props.workflow}
                continuous_exposure_enabled={this.props.continuous_exposure_enabled}
                available_workflows={this.props.available_workflows}
              />
            </Form.Group>
            <Form.Group as={Col} md="12" lg="8" className="pt-2">
              <PublicHealthAction
                patient={this.props.patient}
                authenticity_token={this.props.authenticity_token}
                household_members={this.props.household_members}
                current_user={this.props.current_user}
                jurisdiction_paths={this.props.jurisdiction_paths}
                workflow={this.props.workflow}
                continuous_exposure_enabled={this.props.continuous_exposure_enabled}
              />
            </Form.Group>
            <Form.Group as={Col} md="12" lg="8" className="pt-2">
              <AssignedUser
                patient={this.props.patient}
                authenticity_token={this.props.authenticity_token}
                household_members={this.props.household_members}
                assigned_users={this.props.assigned_users}
                current_user={this.props.current_user}
                jurisdiction_paths={this.props.jurisdiction_paths}
                workflow={this.props.workflow}
                continuous_exposure_enabled={this.props.continuous_exposure_enabled}
              />
            </Form.Group>
            <Form.Group as={Col} lg="24" className="pt-2">
              <Jurisdiction
                patient={this.props.patient}
                authenticity_token={this.props.authenticity_token}
                household_members={this.props.household_members}
                jurisdiction_paths={this.props.jurisdiction_paths}
                current_user={this.props.current_user}
                playbook={this.props.playbook}
                workflow={this.props.workflow}
                continuous_exposure_enabled={this.props.continuous_exposure_enabled}
              />
            </Form.Group>
          </Form.Row>
        </Form>
      </React.Fragment>
    );
  }
}

MonitoringActions.propTypes = {
  current_user: PropTypes.object,
  user_can_transfer: PropTypes.bool,
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  assigned_users: PropTypes.array,
  household_members: PropTypes.array,
  monitoring_reasons: PropTypes.array,
  playbook: PropTypes.string,
  workflow: PropTypes.string,
  continuous_exposure_enabled: PropTypes.bool,
  available_workflows: PropTypes.array,
};

export default MonitoringActions;
