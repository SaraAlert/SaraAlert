import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Form, Modal, OverlayTrigger, Tooltip } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';
import moment from 'moment';
import ReactTooltip from 'react-tooltip';

import ApplyToHousehold from '../../household/actions/ApplyToHousehold';
import DateInput from '../../../util/DateInput';
import InfoTooltip from '../../../util/InfoTooltip';
import reportError from '../../../util/ReportError';

class LastDateExposure extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      last_date_of_exposure: this.props.patient.last_date_of_exposure,
      continuous_exposure: !!this.props.patient.continuous_exposure,
      loading: false,
      apply_to_household: false,
      apply_to_household_ids: [],
      showLastDateOfExposureModal: false,
      showContinuousExposureModal: false,
    };
    this.origState = Object.assign({}, this.state);
  }

  openContinuousExposureModal = () => {
    this.setState({
      showContinuousExposureModal: true,
      last_date_of_exposure: null,
      continuous_exposure: !this.props.patient.continuous_exposure,
      apply_to_household: false,
      apply_to_household_ids: [],
    });
  };

  openLastDateOfExposureModal = date => {
    if (date !== this.props.patient.last_date_of_exposure) {
      this.setState({
        showLastDateOfExposureModal: true,
        last_date_of_exposure: date,
        continuous_exposure: date === null,
        apply_to_household: false,
        apply_to_household_ids: [],
      });
    }
  };

  handleApplyHouseholdChange = apply_to_household => {
    this.setState({ apply_to_household, apply_to_household_ids: [] });
  };

  handleApplyHouseholdIdsChange = apply_to_household_ids => {
    this.setState({ apply_to_household_ids });
  };

  closeModal = () => {
    this.setState({
      last_date_of_exposure: this.props.patient.last_date_of_exposure,
      continuous_exposure: !!this.props.patient.continuous_exposure,
      showLastDateOfExposureModal: false,
      showContinuousExposureModal: false,
      apply_to_household: false,
      apply_to_household_ids: [],
    });
  };

  submit = () => {
    let diffState = Object.keys(this.state).filter(k => _.get(this.state, k) !== _.get(this.origState, k));
    diffState.push('continuous_exposure'); // Since exposure date updates change CE, always make sure this gets changed
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/status', {
          last_date_of_exposure: this.state.last_date_of_exposure,
          continuous_exposure: this.state.continuous_exposure,
          apply_to_household: this.state.apply_to_household,
          apply_to_household_ids: this.state.apply_to_household_ids,
          diffState: diffState,
        })
        .then(() => {
          location.reload();
        })
        .catch(err => {
          reportError(err?.response?.data?.error ? err.response.data.error : err, false);
        });
    });
  };

  createModal = (title, message, close, submit) => {
    return (
      <Modal size="lg" show centered onHide={close}>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>{message}</p>
          {this.props.household_members.length > 0 && (
            <ApplyToHousehold
              household_members={this.props.household_members}
              current_user={this.props.current_user}
              jurisdiction_paths={this.props.jurisdiction_paths}
              handleApplyHouseholdChange={this.handleApplyHouseholdChange}
              handleApplyHouseholdIdsChange={this.handleApplyHouseholdIdsChange}
              workflow={this.props.workflow}
            />
          )}
          {!!this.props.patient.continuous_exposure && !this.state.continuous_exposure && (
            <div className="mt-2">
              <Form.Label className="input-label">Update Last Date of Exposure to:</Form.Label>
              <DateInput
                id="last_date_of_exposure"
                date={this.state.last_date_of_exposure}
                maxDate={moment().add(30, 'days').format('YYYY-MM-DD')}
                onChange={date => this.setState({ last_date_of_exposure: date })}
                placement="top"
                customClass="form-control-lg"
                ariaLabel="Update Last Date of Exposure to Input"
              />
            </div>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={close}>
            Cancel
          </Button>
          <Button
            variant="primary btn-square"
            onClick={submit}
            disabled={
              this.state.loading ||
              (this.state.apply_to_household && this.state.apply_to_household_ids.length === 0) ||
              (!this.state.last_date_of_exposure && !this.state.continuous_exposure)
            }>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            <span data-for="lde-submit" data-tip="">
              Submit
            </span>
            {this.state.apply_to_household && this.state.apply_to_household_ids.length === 0 && (
              <ReactTooltip id="lde-submit" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container">
                <div>Please select at least one household member or change your selection to apply to this monitoree only</div>
              </ReactTooltip>
            )}
          </Button>
        </Modal.Footer>
      </Modal>
    );
  };

  render() {
    return (
      <React.Fragment>
        {this.state.showLastDateOfExposureModal &&
          this.createModal(
            'Last Date of Exposure',
            `Are you sure you want to ${this.state.last_date_of_exposure ? 'modify' : 'clear'} the Last Date of Exposure${
              this.state.last_date_of_exposure ? ` to ${moment(this.state.last_date_of_exposure).format('MM/DD/YYYY')}` : ''
            }? The Last Date of Exposure will be updated ${this.state.last_date_of_exposure ? '' : 'to blank '}${
              this.props.patient.monitoring ? `and Continuous Exposure will be turned ${this.state.last_date_of_exposure ? 'OFF' : 'ON'}` : ''
            } for the selected record${this.props.household_members.length > 1 ? '(s):' : '.'}`,
            this.closeModal,
            this.submit
          )}
        {this.state.showContinuousExposureModal &&
          this.createModal(
            'Continuous Exposure',
            `Are you sure you want to turn ${this.state.continuous_exposure ? 'ON' : 'OFF'} Continuous Exposure? The Last Date of Exposure will ${
              this.state.continuous_exposure ? 'be cleared' : 'need to be populated'
            } and Continuous Exposure will be turned ${this.state.continuous_exposure ? 'ON' : 'OFF'} for the selected record${
              this.props.household_members.length > 1 ? '(s):' : '.'
            }`,
            this.closeModal,
            this.submit
          )}
        <Form.Group controlId="last_date_of_exposure">
          <Form.Label className="input-label h6">
            LAST DATE OF EXPOSURE
            <InfoTooltip tooltipTextKey="lastDateOfExposure" location="right"></InfoTooltip>
          </Form.Label>
          <DateInput
            id="last_date_of_exposure"
            date={this.state.last_date_of_exposure}
            minDate={'2020-01-01'}
            maxDate={moment().add(30, 'days').format('YYYY-MM-DD')}
            onChange={this.openLastDateOfExposureModal}
            placement="top"
            customClass="form-control-lg"
            ariaLabel="Last Date of Exposure Input"
            isClearable
          />
          <OverlayTrigger
            key="tooltip-ot-ce"
            placement="left"
            overlay={
              <Tooltip id="tooltip-ce" style={this.props.patient.monitoring ? { display: 'none' } : {}}>
                Continuous Exposure cannot be turned on or off for records on the Closed line list. If this monitoree requires monitoring due to a Continuous
                Exposure, you may update this field after changing Monitoring Status to &quot;Actively Monitoring&quot;
              </Tooltip>
            }>
            <span className="d-inline-block">
              <Form.Check
                size="lg"
                label="CONTINUOUS EXPOSURE"
                id="continuous_exposure"
                className="mt-2"
                disabled={!this.props.patient.monitoring}
                checked={this.state.continuous_exposure}
                onChange={this.openContinuousExposureModal}
              />
            </span>
          </OverlayTrigger>
          <InfoTooltip tooltipTextKey="continuousExposure" location="right"></InfoTooltip>
        </Form.Group>
      </React.Fragment>
    );
  }
}

LastDateExposure.propTypes = {
  household_members: PropTypes.array,
  authenticity_token: PropTypes.string,
  patient: PropTypes.object,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  workflow: PropTypes.string,
};

export default LastDateExposure;
