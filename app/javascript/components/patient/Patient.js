import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Col, Collapse, Row } from 'react-bootstrap';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faChevronRight } from '@fortawesome/free-solid-svg-icons';

import BadgeHoH from './icons/BadgeHoH';
import InfoTooltip from '../util/InfoTooltip';
import FollowUpFlagPanel from './follow_up_flag/FollowUpFlagPanel';
import FollowUpFlagModal from './follow_up_flag/FollowUpFlagModal';
import { Heading } from '../../utils/Heading';
import { navQueryParam, patientHref } from '../../utils/Navigation';
import { customPreferredContactTimeOptions } from '../../data/preferredContactTimeOptions';
import { convertLanguageCodesToNames } from '../../utils/Languages';
import { formatName, formatPhoneNumberVisually, formatRace, isMinor } from '../../utils/Patient';

let rootHeaderLevel;

class Patient extends React.Component {
  constructor(props) {
    super(props);
    rootHeaderLevel = props.headingLevel || 1;
    this.state = {
      expanded: props.edit_mode || !props.collapse,
      expandNotes: false,
      expandArrivalNotes: false,
      expandPlannedTravelNotes: false,
      primaryLanguageDisplayName: null,
      showSetFlagModal: false,
    };
  }

  componentDidMount() {
    convertLanguageCodesToNames([this.props.details?.primary_language], this.props.authenticity_token, res => {
      this.setState({ primaryLanguageDisplayName: res[0] });
    });
  }

  componentDidUpdate(nextProps, prevState) {
    // The way that Enrollment is structured, this Patient component is not re-mounted when reviewing a Patient
    // We need to update the `primaryLanguageDisplayName`. We reset `primary_language` below to break out of the
    // infinite loop that not resetting it will cause. You cannot use `getDerivedStateFromProps` here due to the
    // async nature of convertLanguageCodesToNames()
    if (nextProps.details?.primary_language !== prevState.details?.primary_language) {
      convertLanguageCodesToNames([nextProps.details?.primary_language], this.props.authenticity_token, res => {
        this.setState({
          details: { ...nextProps.details, primary_language: nextProps.details?.primary_language },
          primaryLanguageDisplayName: res[0],
        });
      });
    }
  }

  /**
   * Renders the edit link depending on if the user is coming from the monitoree details section or summary of the enrollment wizard.
   * @param {String} section - title of the monitoree details section
   * @param {Number} enrollmentStep - the number of the step for the section within the enrollment wizard
   */
  renderEditLink(section, enrollmentStep) {
    let sectionId = `edit-${section.replace(/\s+/g, '_').toLowerCase()}-btn`;
    if (this.props.goto) {
      return (
        <Button variant="link" id={sectionId} className="edit-link p-0" onClick={() => this.props.goto(enrollmentStep)} aria-label={`Edit ${section}`}>
          Edit
        </Button>
      );
    } else {
      return (
        <div className="edit-link">
          <a
            href={`${window.BASE_PATH}/patients/${this.props.details.id}/edit?step=${enrollmentStep}${navQueryParam(this.props.workflow, false)}`}
            id={sectionId}
            aria-label={`Edit ${section}`}>
            Edit
          </a>
        </div>
      );
    }
  }

  render() {
    if (!this.props.details) {
      return <React.Fragment>No monitoree details to show.</React.Fragment>;
    }

    const showDomesticAddress =
      this.props.details.address_line_1 ||
      this.props.details.address_line_2 ||
      this.props.details.address_city ||
      this.props.details.address_state ||
      this.props.details.address_zip ||
      this.props.details.address_county;
    const showMonitoredAddress =
      this.props.details.monitored_address_line_1 ||
      this.props.details.monitored_address_line_2 ||
      this.props.details.monitored_address_city ||
      this.props.details.monitored_address_state ||
      this.props.details.monitored_address_zip ||
      this.props.details.monitored_address_county;
    const showForeignAddress =
      this.props.details.foreign_address_line_1 ||
      this.props.details.foreign_address_line_2 ||
      this.props.details.foreign_address_line_3 ||
      this.props.details.foreign_address_city ||
      this.props.details.foreign_address_zip ||
      this.props.details.foreign_address_country;
    const showForeignMonitoringAddress =
      this.props.details.foreign_monitored_address_line_1 ||
      this.props.details.foreign_monitored_address_line_2 ||
      this.props.details.foreign_monitored_address_city ||
      this.props.details.foreign_monitored_address_state ||
      this.props.details.foreign_monitored_address_zip ||
      this.props.details.foreign_monitored_address_county;
    const showArrivalSection =
      this.props.details.port_of_origin ||
      this.props.details.date_of_departure ||
      this.props.details.flight_or_vessel_carrier ||
      this.props.details.flight_or_vessel_number ||
      this.props.details.port_of_entry_into_usa ||
      this.props.details.date_of_arrival;
    const showPlannedTravel =
      this.props.details.additional_planned_travel_type ||
      this.props.details.additional_planned_travel_destination_country ||
      this.props.details.additional_planned_travel_destination_state ||
      this.props.details.additional_planned_travel_port_of_departure ||
      this.props.details.additional_planned_travel_start_date ||
      this.props.details.additional_planned_travel_end_date;
    const showRiskFactors =
      this.props.details.contact_of_known_case ||
      this.props.details.member_of_a_common_exposure_cohort ||
      this.props.details.travel_to_affected_country_or_area ||
      this.props.details.was_in_health_care_facility_with_known_cases ||
      this.props.details.laboratory_personnel ||
      this.props.details.healthcare_personnel ||
      this.props.details.crew_on_passenger_or_cargo_flight;

    return (
      <React.Fragment>
        <Row id="monitoree-details-header" className="mb-3">
          {this.props.can_modify_subject_status && !this.props.edit_mode && this.props.details.follow_up_reason && (
            <FollowUpFlagPanel
              patient={this.props.details}
              current_user={this.props.current_user}
              jurisdiction_paths={this.props.jurisdiction_paths}
              authenticity_token={this.props.authenticity_token}
              other_household_members={this.props.other_household_members}
              bulkAction={false}
            />
          )}
          <Col sm={12}>
            <Heading level={rootHeaderLevel} className="secondary-title">
              <span className="pr-2" aria-label={`Monitoree Name: ${formatName(this.props.details)}`}>
                {formatName(this.props.details)}
              </span>
              {this.props.details.head_of_household && <BadgeHoH patientId={String(this.props.details.id)} location={'right'} />}
            </Heading>
            {this.props.can_modify_subject_status && !this.props.edit_mode && !this.props.details.follow_up_reason && (
              <Button id="set-follow-up-flag-link" size="sm" aria-label="Set Flag for Follow-up" onClick={() => this.setState({ showSetFlagModal: true })}>
                <i className="fas fa-flag pr-1"></i> Flag for Follow-up
              </Button>
            )}
          </Col>
          <Col sm={12}>
            <div className="jurisdiction-user-box float-right">
              <div id="jurisdiction-path">
                <b>
                  <span className="d-none d-md-inline">Assigned</span> Jurisdiction:
                </b>{' '}
                {this.props.jurisdiction_paths[this.props.details.jurisdiction_id] || '--'}
              </div>
              <div id="assigned-user">
                <b>Assigned User:</b> {this.props.details.assigned_user || '--'}
              </div>
            </div>
          </Col>
        </Row>
        <Row>
          <Col id="identification" lg={14} className="col-xxl-12">
            <div className="section-header">
              <Heading level={rootHeaderLevel + 1} className="section-title">
                Identification
              </Heading>
              {this.renderEditLink('Identification', 0)}
            </div>
            <Row>
              <Col sm={10} className="item-group">
                <div>
                  <b>DOB:</b> <span>{this.props.details.date_of_birth && moment(this.props.details.date_of_birth, 'YYYY-MM-DD').format('MM/DD/YYYY')}</span>
                  {this.props.details.date_of_birth && isMinor(this.props.details.date_of_birth) && <span className="text-danger"> (Minor)</span>}
                </div>
                <div>
                  <b>Age:</b> <span>{this.props.details.age || '--'}</span>
                </div>
                <div>
                  <b>Language:</b> <span>{this.state.primaryLanguageDisplayName || '--'}</span>
                </div>
                <div>
                  <b>Sara Alert ID:</b> <span>{this.props.details.id || '--'}</span>
                </div>
                <div>
                  <b>State/Local ID:</b> <span>{this.props.details.user_defined_id_statelocal || '--'}</span>
                </div>
                <div>
                  <b>CDC ID:</b> <span>{this.props.details.user_defined_id_cdc || '--'}</span>
                </div>
                <div>
                  <b>NNDSS ID:</b> <span>{this.props.details.user_defined_id_nndss || '--'}</span>
                </div>
              </Col>
              <Col sm={14} className="item-group">
                <div>
                  <b>Birth Sex:</b> <span>{this.props.details.sex || '--'}</span>
                </div>
                <div>
                  <b>Gender Identity:</b> <span>{this.props.details.gender_identity || '--'}</span>
                </div>
                <div>
                  <b>Sexual Orientation:</b> <span>{this.props.details.sexual_orientation || '--'}</span>
                </div>
                <div>
                  <b>Race:</b> <span>{formatRace(this.props.details)}</span>
                </div>
                <div>
                  <b>Ethnicity:</b> <span>{this.props.details.ethnicity || '--'}</span>
                </div>
                <div>
                  <b>Nationality:</b> <span>{this.props.details.nationality || '--'}</span>
                </div>
              </Col>
            </Row>
          </Col>
          <Col id="contact-information" lg={10} className="col-xxl-12">
            <div className="section-header">
              <Heading level={rootHeaderLevel + 1} className="section-title">
                Contact Information
              </Heading>
              {this.renderEditLink('Contact Information', 2)}
            </div>
            <div className="item-group">
              {this.props.details.date_of_birth && isMinor(this.props.details.date_of_birth) && (
                <React.Fragment>
                  <span className="text-danger">Monitoree is a minor</span>
                  {!this.props.details.head_of_household && this.props.hoh && (
                    <div>
                      View contact info for Head of Household:
                      <a className="pl-1" href={patientHref(this.props.hoh.id, this.props.workflow)}>
                        {formatName(this.props.hoh)}
                      </a>
                    </div>
                  )}
                </React.Fragment>
              )}
              <div>
                <b>Phone:</b> <span>{this.props.details.primary_telephone ? `${formatPhoneNumberVisually(this.props.details.primary_telephone)}` : '--'}</span>
                {this.props.details.blocked_sms && (
                  <span className="font-weight-bold pl-2">
                    SMS Blocked
                    <InfoTooltip tooltipTextKey="blockedSMS" location="top" />
                  </span>
                )}
              </div>
              <div>
                <b>Preferred Contact Time:</b>{' '}
                <span>
                  {customPreferredContactTimeOptions[this.props.details.preferred_contact_time] || this.props.details.preferred_contact_time || '--'}
                  {customPreferredContactTimeOptions[this.props.details.preferred_contact_time] && (
                    <InfoTooltip tooltipTextKey="customPreferredContactTime" location="right" />
                  )}
                </span>
              </div>
              <div>
                <b>Primary Telephone Type:</b> <span>{this.props.details.primary_telephone_type || '--'}</span>
              </div>
              {(this.props.details.secondary_telephone || this.props.details.international_telephone) && (
                <div className="pl-3 py-1">
                  {this.props.details.secondary_telephone && (
                    <div className="small-text">
                      <b>Secondary Phone:</b> <span>{formatPhoneNumberVisually(this.props.details.primary_telephone) || '--'}</span>
                    </div>
                  )}
                  {this.props.details.secondary_telephone && (
                    <div className="small-text">
                      <b>Secondary Phone Type:</b> <span>{this.props.details.secondary_telephone_type || '--'}</span>
                    </div>
                  )}
                  {this.props.details.international_telephone && (
                    <div className="small-text">
                      <b>International Phone:</b> <span>{this.props.details.international_telephone || '--'}</span>
                    </div>
                  )}
                </div>
              )}
              <div>
                <b>Email:</b> <span>{this.props.details.email || '--'}</span>
              </div>
              <div>
                <b>Preferred Reporting Method:</b>{' '}
                {(!this.props.details.blocked_sms || !this.props.details.preferred_contact_method?.includes('SMS')) && (
                  <span>{this.props.details.preferred_contact_method || '--'}</span>
                )}
                {this.props.details.blocked_sms && this.props.details.preferred_contact_method?.includes('SMS') && (
                  <span className="font-weight-bold text-danger">
                    {this.props.details.preferred_contact_method}
                    <InfoTooltip tooltipTextKey="blockedSMSContactMethod" location="top" />
                  </span>
                )}
              </div>
            </div>
          </Col>
        </Row>
        {!this.props.edit_mode && (
          <div className="details-expander mb-3">
            <Button id="details-expander-link" variant="link" className="p-0" onClick={() => this.setState({ expanded: !this.state.expanded })}>
              <FontAwesomeIcon className={this.state.expanded ? 'chevron-opened' : 'chevron-closed'} icon={faChevronRight} />
              <span aria-label={`${this.state.expanded ? 'Collapse' : 'Expand'} address, travel, exposure, and case information`} className="pl-2">
                {this.state.expanded ? 'Hide' : 'Show'} address, travel, exposure, and case information
              </span>
            </Button>
            <span className="dashed-line"></span>
          </div>
        )}
        <Collapse in={this.state.expanded}>
          <div>
            <Row>
              <Col id="address" lg={14} xl={12} className="col-xxxl-10">
                <div className="section-header">
                  <Heading level={rootHeaderLevel + 1} className="section-title">
                    Address
                  </Heading>
                  {this.renderEditLink('Address', 1)}
                </div>
                {!(showDomesticAddress || showMonitoredAddress || showForeignAddress || showForeignMonitoringAddress) && <div className="none-text">None</div>}
                {(showDomesticAddress || showMonitoredAddress) && (
                  <Row>
                    {showDomesticAddress && (
                      <Col sm={showDomesticAddress && showMonitoredAddress ? 12 : 24} className="item-group">
                        <p className="subsection-title">Home Address (USA)</p>
                        <div>
                          <b>Address 1:</b> <span>{this.props.details.address_line_1 || '--'}</span>
                        </div>
                        <div>
                          <b>Address 2:</b> <span>{this.props.details.address_line_2 || '--'}</span>
                        </div>
                        <div>
                          <b>Town/City:</b> <span>{this.props.details.address_city || '--'}</span>
                        </div>
                        <div>
                          <b>State:</b> <span>{this.props.details.address_state || '--'}</span>
                        </div>
                        <div>
                          <b>Zip:</b> <span>{this.props.details.address_zip || '--'}</span>
                        </div>
                        <div>
                          <b>County:</b> <span>{this.props.details.address_county || '--'}</span>
                        </div>
                      </Col>
                    )}
                    {showMonitoredAddress && (
                      <Col sm={showDomesticAddress && showMonitoredAddress ? 12 : 24} className="item-group">
                        <p className="subsection-title">Monitoring Address</p>
                        <div>
                          <b>Address 1:</b> <span>{this.props.details.monitored_address_line_1 || '--'}</span>
                        </div>
                        <div>
                          <b>Address 2:</b> <span>{this.props.details.monitored_address_line_2 || '--'}</span>
                        </div>
                        <div>
                          <b>Town/City:</b> <span>{this.props.details.monitored_address_city || '--'}</span>
                        </div>
                        <div>
                          <b>State:</b> <span>{this.props.details.monitored_address_state || '--'}</span>
                        </div>
                        <div>
                          <b>Zip:</b> <span>{this.props.details.monitored_address_zip || '--'}</span>
                        </div>
                        <div>
                          <b>County:</b> <span>{this.props.details.monitored_address_county || '--'}</span>
                        </div>
                      </Col>
                    )}
                  </Row>
                )}
                {(showForeignAddress || showForeignMonitoringAddress) && (
                  <Row>
                    {showForeignAddress && (
                      <Col sm={showForeignAddress && showForeignMonitoringAddress ? 12 : 24} className="item-group">
                        <p className="subsection-title">Home Address (Foreign)</p>
                        <div>
                          <b>Address 1:</b> <span>{this.props.details.foreign_address_line_1 || '--'}</span>
                        </div>
                        <div>
                          <b>Address 2:</b> <span>{this.props.details.foreign_address_line_2 || '--'}</span>
                        </div>
                        <div>
                          <b>Address 3:</b> <span>{this.props.details.foreign_address_line_3 || '--'}</span>
                        </div>
                        <div>
                          <b>Town/City:</b> <span>{this.props.details.foreign_address_city || '--'}</span>
                        </div>
                        <div>
                          <b>State:</b> <span>{this.props.details.foreign_address_state || '--'}</span>
                        </div>
                        <div>
                          <b>Zip:</b> <span>{this.props.details.foreign_address_zip || '--'}</span>
                        </div>
                        <div>
                          <b>Country:</b> <span>{this.props.details.foreign_address_country || '--'}</span>
                        </div>
                      </Col>
                    )}
                    {showForeignMonitoringAddress && (
                      <Col sm={showForeignAddress && showForeignMonitoringAddress ? 12 : 24} className="item-group">
                        <p className="subsection-title">Monitoring Address</p>
                        <div>
                          <b>Address 1:</b> <span>{this.props.details.foreign_monitored_address_line_1 || '--'}</span>
                        </div>
                        <div>
                          <b>Address 2:</b> <span>{this.props.details.foreign_monitored_address_line_2 || '--'}</span>
                        </div>
                        <div>
                          <b>Town/City:</b> <span>{this.props.details.foreign_monitored_address_city || '--'}</span>
                        </div>
                        <div>
                          <b>State:</b> <span>{this.props.details.foreign_monitored_address_state || '--'}</span>
                        </div>
                        <div>
                          <b>Zip:</b> <span>{this.props.details.foreign_monitored_address_zip || '--'}</span>
                        </div>
                        <div>
                          <b>County:</b> <span>{this.props.details.foreign_monitored_address_county || '--'}</span>
                        </div>
                      </Col>
                    )}
                  </Row>
                )}
              </Col>
              <Col lg={10} xl={12} className="col-xxxl-14">
                <Row>
                  <Col id="arrival-information" xl={24} className="col-xxxl-12">
                    <div className="section-header">
                      <Heading level={rootHeaderLevel + 1} className="section-title">
                        Arrival Information
                      </Heading>
                      {this.renderEditLink('Arrival Information', 3)}
                    </div>
                    {!(showArrivalSection || this.props.details.travel_related_notes) && <div className="none-text">None</div>}
                    {showArrivalSection && (
                      <Row>
                        <Col md={12} lg={24} xl={12} className="item-group">
                          <p className="subsection-title">Departed</p>
                          <div>
                            <b>Port of Origin:</b> <span>{this.props.details.port_of_origin || '--'}</span>
                          </div>
                          <div>
                            <b>Date of Departure:</b>{' '}
                            <span>
                              {this.props.details.date_of_departure ? moment(this.props.details.date_of_departure, 'YYYY-MM-DD').format('MM/DD/YYYY') : '--'}
                            </span>
                          </div>
                        </Col>
                        <Col md={12} lg={24} xl={12} className="item-group">
                          <p className="subsection-title">Arrival</p>
                          <div>
                            <b>Port of Entry:</b> <span>{this.props.details.port_of_entry_into_usa || '--'}</span>
                          </div>
                          <div>
                            <b>Date of Arrival:</b>{' '}
                            <span>
                              {this.props.details.date_of_arrival ? moment(this.props.details.date_of_arrival, 'YYYY-MM-DD').format('MM/DD/YYYY') : '--'}
                            </span>
                          </div>
                        </Col>
                        <Col className="item-group">
                          <div>
                            <b>Carrier:</b> <span>{this.props.details.flight_or_vessel_carrier || '--'}</span>
                          </div>
                          <div>
                            <b>Flight or Vessel #:</b> <span>{this.props.details.flight_or_vessel_number || '--'}</span>
                          </div>
                        </Col>
                      </Row>
                    )}
                    {this.props.details.travel_related_notes && (
                      <div className="notes-section">
                        <p className="subsection-title">Notes</p>
                        {this.props.details.travel_related_notes.length < 400 && <div className="notes-text">{this.props.details.travel_related_notes}</div>}
                        {this.props.details.travel_related_notes.length >= 400 && (
                          <React.Fragment>
                            <div className="notes-text">
                              {this.state.expandArrivalNotes
                                ? this.props.details.travel_related_notes
                                : this.props.details.travel_related_notes.slice(0, 400) + ' ...'}
                            </div>
                            <Button
                              variant="link"
                              className="notes-button p-0"
                              onClick={() => this.setState({ expandArrivalNotes: !this.state.expandArrivalNotes })}>
                              {this.state.expandArrivalNotes ? '(Collapse)' : '(View all)'}
                            </Button>
                          </React.Fragment>
                        )}
                      </div>
                    )}
                  </Col>
                  <Col id="planned-travel" xl={24} className="col-xxxl-12">
                    <div className="section-header">
                      <Heading level={rootHeaderLevel + 1} className="section-title">
                        <span className="d-none d-lg-inline d-xl-none d-xxl-inline">Additional </span>Planned Travel
                      </Heading>
                      {this.renderEditLink('Planned Travel', 4)}
                    </div>
                    {!(showPlannedTravel || this.props.details.additional_planned_travel_related_notes) && <div className="none-text">None</div>}
                    {showPlannedTravel && (
                      <div className="item-group">
                        <div>
                          <b>Type:</b> <span>{this.props.details.additional_planned_travel_type || '--'}</span>
                        </div>
                        <div>
                          <b>Place:</b>{' '}
                          <span>
                            {this.props.details.additional_planned_travel_destination_country}
                            {this.props.details.additional_planned_travel_destination_state}
                            {!this.props.details.additional_planned_travel_destination_country &&
                              !this.props.details.additional_planned_travel_destination_state &&
                              '--'}
                          </span>
                        </div>
                        <div>
                          <b>Port of Departure:</b> <span>{this.props.details.additional_planned_travel_port_of_departure || '--'}</span>
                        </div>
                        <div>
                          <b>Start Date:</b>{' '}
                          <span>
                            {this.props.details.additional_planned_travel_start_date
                              ? moment(this.props.details.additional_planned_travel_start_date, 'YYYY-MM-DD').format('MM/DD/YYYY')
                              : '--'}
                          </span>
                        </div>
                        <div>
                          <b>End Date:</b>{' '}
                          <span>
                            {this.props.details.additional_planned_travel_end_date
                              ? moment(this.props.details.additional_planned_travel_end_date, 'YYYY-MM-DD').format('MM/DD/YYYY')
                              : '--'}
                          </span>
                        </div>
                      </div>
                    )}
                    {this.props.details.additional_planned_travel_related_notes && (
                      <div className="notes-section">
                        <p className="subsection-title">Notes</p>
                        {this.props.details.additional_planned_travel_related_notes.length < 400 && (
                          <div className="notes-text">{this.props.details.additional_planned_travel_related_notes}</div>
                        )}
                        {this.props.details.additional_planned_travel_related_notes.length >= 400 && (
                          <React.Fragment>
                            <div className="notes-text">
                              {this.state.expandPlannedTravelNotes
                                ? this.props.details.additional_planned_travel_related_notes
                                : this.props.details.additional_planned_travel_related_notes.slice(0, 400) + ' ...'}
                            </div>
                            <Button
                              variant="link"
                              className="notes-button p-0"
                              onClick={() => this.setState({ expandPlannedTravelNotes: !this.state.expandPlannedTravelNotes })}>
                              {this.state.expandPlannedTravelNotes ? '(Collapse)' : '(View all)'}
                            </Button>
                          </React.Fragment>
                        )}
                      </div>
                    )}
                  </Col>
                </Row>
              </Col>
            </Row>
            <Row>
              <Col id="potential-exposure-information" md={14} xl={12} className={this.props.details.isolation ? 'col-xxxl-8' : 'col-xxxl-10'}>
                <div className="section-header">
                  <Heading level={rootHeaderLevel + 1} className="section-title">
                    Potential Exposure<span className="d-none d-lg-inline"> Information</span>
                  </Heading>
                  {this.renderEditLink('Potential Exposure Information', 5)}
                </div>
                <div className="item-group">
                  <div>
                    <b>Last Date of Exposure:</b>{' '}
                    <span>
                      {this.props.details.last_date_of_exposure ? moment(this.props.details.last_date_of_exposure, 'YYYY-MM-DD').format('MM/DD/YYYY') : '--'}
                    </span>
                  </div>
                  <div>
                    <b>Exposure Location:</b> <span>{this.props.details.potential_exposure_location || '--'}</span>
                  </div>
                  <div>
                    <b>Exposure Country:</b> <span>{this.props.details.potential_exposure_country || '--'}</span>
                  </div>
                </div>
                <p className="subsection-title">Risk Factors</p>
                {!showRiskFactors && <div className="none-text">None specified</div>}
                {showRiskFactors && (
                  <ul className="risk-factors">
                    {this.props.details.contact_of_known_case && (
                      <li>
                        <span className="risk-factor">Close Contact with a Known Case</span>
                        {this.props.details.contact_of_known_case_id && <span className="risk-val">{this.props.details.contact_of_known_case_id}</span>}
                      </li>
                    )}
                    {this.props.details.member_of_a_common_exposure_cohort && (
                      <li>
                        <span className="risk-factor">Member of a Common Exposure Cohort</span>
                        {this.props.details.member_of_a_common_exposure_cohort_type && (
                          <span className="risk-val">{this.props.details.member_of_a_common_exposure_cohort_type}</span>
                        )}
                      </li>
                    )}
                    {this.props.details.travel_to_affected_country_or_area && (
                      <li>
                        <span className="risk-factor">Travel from Affected Country or Area</span>
                      </li>
                    )}
                    {this.props.details.was_in_health_care_facility_with_known_cases && (
                      <li>
                        <span className="risk-factor">Was in Healthcare Facility with Known Cases</span>
                        {this.props.details.was_in_health_care_facility_with_known_cases_facility_name && (
                          <span className="risk-val">{this.props.details.was_in_health_care_facility_with_known_cases_facility_name}</span>
                        )}
                      </li>
                    )}
                    {this.props.details.laboratory_personnel && (
                      <li>
                        <span className="risk-factor">Laboratory Personnel</span>
                        {this.props.details.laboratory_personnel_facility_name && (
                          <span className="risk-val">{this.props.details.laboratory_personnel_facility_name}</span>
                        )}
                      </li>
                    )}
                    {this.props.details.healthcare_personnel && (
                      <li>
                        <span className="risk-factor">Healthcare Personnel</span>
                        {this.props.details.healthcare_personnel_facility_name && (
                          <span className="risk-val">{this.props.details.healthcare_personnel_facility_name}</span>
                        )}
                      </li>
                    )}
                    {this.props.details.crew_on_passenger_or_cargo_flight && (
                      <li>
                        <span className="risk-factor">Crew on Passenger or Cargo Flight</span>
                      </li>
                    )}
                  </ul>
                )}
              </Col>
              {this.props.details.isolation && (
                <Col id="case-information" md={10} xl={12} className="col-xxxl-8">
                  <div className="section-header">
                    <Heading level={rootHeaderLevel + 1} className="section-title">
                      Case Information
                    </Heading>
                    {this.renderEditLink('Case Information', 6)}
                  </div>
                  <div className="item-group">
                    <div>
                      <b>Case Status: </b>
                      <span>{this.props.details.case_status || '--'}</span>
                    </div>
                    {this.props.details.first_positive_lab_at && (
                      <div>
                        <b>First Positive Lab Collected: </b>
                        <span>{moment(this.props.details.first_positive_lab_at, 'YYYY-MM-DD').format('MM/DD/YYYY')}</span>
                      </div>
                    )}
                    <div>
                      <b>Symptom Onset: </b>
                      <span>{this.props.details.symptom_onset ? moment(this.props.details.symptom_onset, 'YYYY-MM-DD').format('MM/DD/YYYY') : '--'}</span>
                    </div>
                  </div>
                </Col>
              )}
              <Col id="exposure-notes" md={10} xl={12} className="notes-section col-xxxl-8">
                <div className="section-header">
                  <Heading level={rootHeaderLevel + 1} className="section-title">
                    Notes
                  </Heading>
                  {this.renderEditLink('Edit Notes', this.props.details.isolation ? 6 : 5)}
                </div>
                {!this.props.details.exposure_notes && <div className="none-text">None</div>}
                {this.props.details.exposure_notes && this.props.details.exposure_notes.length < 400 && (
                  <div className="notes-text">{this.props.details.exposure_notes}</div>
                )}
                {this.props.details.exposure_notes && this.props.details.exposure_notes.length >= 400 && (
                  <React.Fragment>
                    <div className="notes-text">
                      {this.state.expandNotes ? this.props.details.exposure_notes : this.props.details.exposure_notes.slice(0, 400) + ' ...'}
                    </div>
                    <Button variant="link" className="notes-button p-0" onClick={() => this.setState({ expandNotes: !this.state.expandNotes })}>
                      {this.state.expandNotes ? '(Collapse)' : '(View all)'}
                    </Button>
                  </React.Fragment>
                )}
              </Col>
            </Row>
          </div>
        </Collapse>
        {this.state.showSetFlagModal && (
          <FollowUpFlagModal
            show={this.state.showSetFlagModal}
            patient={this.props.details}
            current_user={this.props.current_user}
            jurisdiction_paths={this.props.jurisdiction_paths}
            authenticity_token={this.props.authenticity_token}
            other_household_members={this.props.other_household_members}
            close={() => this.setState({ showSetFlagModal: false })}
            clear_flag={false}
          />
        )}
      </React.Fragment>
    );
  }
}

Patient.propTypes = {
  current_user: PropTypes.object,
  details: PropTypes.object,
  hoh: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  goto: PropTypes.func,
  edit_mode: PropTypes.bool,
  collapse: PropTypes.bool,
  other_household_members: PropTypes.array,
  can_modify_subject_status: PropTypes.bool,
  authenticity_token: PropTypes.string,
  workflow: PropTypes.string,
  headingLevel: PropTypes.number,
};

export default Patient;
