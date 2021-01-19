import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Button, Modal } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';
import moment from 'moment';

import DateInput from '../../util/DateInput';
import InfoTooltip from '../../util/InfoTooltip';
import reportError from '../../util/ReportError';

class MonitoringStatus extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showMonitoringStatusModal: false,
      monitoring: props.patient.monitoring,
      monitoring_status: props.patient.monitoring ? 'Actively Monitoring' : 'Not Monitoring',
      monitoring_reason: '',
      reasoning: '',
      loading: false,
      apply_to_household: false,
      apply_to_household_cm_exp_only: false,
      apply_to_household_cm_exp_only_date: moment(new Date()).format('YYYY-MM-DD'),
    };
  }

  handleMonitoringStatusChange = event => {
    this.setState({
      showMonitoringStatusModal: true,
      monitoring: event.target.value === 'Actively Monitoring',
      monitoring_status: event?.target?.value ? event.target.value : '',
    });
  };

  handleApplyHouseholdChange = event => {
    if (event?.target?.name && event.target.name === 'apply_to_household') {
      const applyToGroup = event.target.id === 'apply_to_household_yes';
      this.setState({
        apply_to_household: applyToGroup,
        apply_to_household_cm_exp_only: false,
      });
    } else if (event?.target?.name && event.target.name === 'apply_to_household_cm_exp_only') {
      const applyToGroup = event.target.id === 'apply_to_household_cm_exp_only_yes';
      this.setState({ apply_to_household_cm_exp_only: applyToGroup });
    }
  };

  handleChange = event => {
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    this.setState({ [event.target.id]: value || '' });
  };

  toggleMonitoringStatusModal = () => {
    const current = this.state.showMonitoringStatusModal;
    this.setState({
      showMonitoringStatusModal: !current,
      monitoring: this.props.patient.monitoring,
      monitoring_status: this.props.patient.monitoring ? 'Actively Monitoring' : 'Not Monitoring',
      monitoring_reason: '',
      reasoning: '',
      apply_to_household: false,
      apply_to_household_cm_exp_only: false,
      apply_to_household_cm_exp_only_date: moment(new Date()).format('YYYY-MM-DD'),
    });
  };

  submit = () => {
    const diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          monitoring: this.state.monitoring,
          monitoring_reason: this.state.monitoring_status === 'Not Monitoring' ? this.state.monitoring_reason : null,
          reasoning:
            (this.state.showMonitoringStatusModal && this.state.monitoring_status === 'Not Monitoring'
              ? this.state.monitoring_reason + (this.state.reasoning !== '' ? ', ' : '')
              : '') + this.state.reasoning,
          apply_to_household: this.state.apply_to_household,
          apply_to_household_cm_exp_only: this.state.apply_to_household_cm_exp_only,
          apply_to_household_cm_exp_only_date: this.state.apply_to_household_cm_exp_only_date,
          diffState: diffState,
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  };

  createModal(toggle, submit) {
    return (
      <Modal size="lg" show centered onHide={toggle}>
        <Modal.Header>
          <Modal.Title>Monitoring Status</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            Are you sure you want to change monitoring status to &quot;{this.state.monitoring_status}&quot;?
            {!this.state.monitoring && <b> This will move the selected record(s) to the Closed line list and turn Continuous Exposure OFF.</b>}
            {this.state.monitoring && <b> This will move the selected record(s) from the Closed line list to the appropriate Active Monitoring line list.</b>}
          </p>
          {this.props.has_dependents && (
            <React.Fragment>
              <p className="mb-2">Please select the records that you would like to apply this change to:</p>
              <Form.Group className="px-4">
                <Form.Check
                  type="radio"
                  className="mb-1"
                  name="apply_to_household"
                  id="apply_to_household_no"
                  label="This monitoree only"
                  onChange={this.handleApplyHouseholdChange}
                  checked={!this.state.apply_to_household}
                />
                <Form.Check
                  type="radio"
                  className="mb-3"
                  name="apply_to_household"
                  id="apply_to_household_yes"
                  label={`This monitoree and all household members ${
                    this.state.monitoring ? '' : '(this will turn Continuous Exposure OFF for all household members)'
                  }`}
                  onChange={this.handleApplyHouseholdChange}
                  checked={this.state.apply_to_household}
                />
              </Form.Group>
            </React.Fragment>
          )}
          {!this.state.monitoring && (
            <Form.Group>
              <Form.Label>Please select reason for status change:</Form.Label>
              <Form.Control as="select" size="lg" className="form-square" id="monitoring_reason" onChange={this.handleChange} defaultValue={-1}>
                <option></option>
                {this.props.monitoring_reasons.map((option, index) => (
                  <option key={`option-${index}`} value={option}>
                    {option}
                  </option>
                ))}
              </Form.Control>
            </Form.Group>
          )}
          <Form.Group>
            <Form.Label>Please include any additional details:</Form.Label>
            <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleChange} aria-label="Additional Details Text Area" />
          </Form.Group>
          {this.props.patient.isolation && !this.state.monitoring && this.props.in_household_with_member_with_ce_in_exposure && !this.state.apply_to_household && (
            <div className="update-dependent-lde">
              <hr />
              <p className="mb-2">
                Would you like to update the <i>Last Date of Exposure</i> for all household members who have Continuous Exposure turned ON and are being
                monitored in the Exposure Workflow?
              </p>
              <Form.Group className="px-4">
                <Form.Check
                  type="radio"
                  className="mb-2"
                  name="apply_to_household_cm_exp_only"
                  id="apply_to_household_cm_exp_only_no"
                  label="No, household members still have continuous exposure to another case"
                  onChange={this.handleApplyHouseholdChange}
                  checked={!this.state.apply_to_household_cm_exp_only}
                />
                <Form.Check>
                  <Form.Check.Label>
                    <Form.Check.Input
                      type="radio"
                      name="apply_to_household_cm_exp_only"
                      id="apply_to_household_cm_exp_only_yes"
                      onChange={this.handleApplyHouseholdChange}
                      checked={this.state.apply_to_household_cm_exp_only}
                    />
                    <p className="mb-1">Yes, household members are no longer being exposed to a case</p>
                    {this.state.apply_to_household_cm_exp_only && (
                      <React.Fragment>
                        <p className="mb-2">
                          Update their <b>Last Date of Exposure</b> to:
                        </p>
                        <DateInput
                          id="apply_to_household_cm_exp_only_date"
                          date={this.state.apply_to_household_cm_exp_only_date}
                          minDate={'2020-01-01'}
                          maxDate={moment()
                            .add(30, 'days')
                            .format('YYYY-MM-DD')}
                          onChange={date => this.setState({ apply_to_household_cm_exp_only_date: date })}
                          placement="bottom"
                          customClass="form-control-lg"
                          ariaLabel="Update Last Exposure Date Input"
                        />
                      </React.Fragment>
                    )}
                  </Form.Check.Label>
                </Form.Check>
              </Form.Group>
            </div>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.loading}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Submit
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <div className="disabled">
          <Form.Label htmlFor="monitoring_status" className="nav-input-label">
            MONITORING STATUS
            <InfoTooltip tooltipTextKey="monitoringStatus" location="right"></InfoTooltip>
          </Form.Label>
          <Form.Control
            as="select"
            className="form-control-lg"
            id="monitoring_status"
            onChange={this.handleMonitoringStatusChange}
            value={this.state.monitoring_status}>
            <option>Actively Monitoring</option>
            <option>Not Monitoring</option>
          </Form.Control>
        </div>
        {this.state.showMonitoringStatusModal && this.createModal(this.toggleMonitoringStatusModal, this.submit)}
      </React.Fragment>
    );
  }
}

MonitoringStatus.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  has_dependents: PropTypes.bool,
  in_household_with_member_with_ce_in_exposure: PropTypes.bool,
  monitoring_reasons: PropTypes.array,
};

export default MonitoringStatus;
