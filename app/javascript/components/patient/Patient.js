import React from 'react';
import { PropTypes } from 'prop-types';
import { Col, Row, Button, Collapse, Card, Table, Form } from 'react-bootstrap';
import moment from 'moment';

import BadgeHOH from '../util/BadgeHOH';
import ChangeHOH from '../subject/ChangeHOH';
import MoveToHousehold from '../subject/MoveToHousehold';
import RemoveFromHousehold from '../subject/RemoveFromHousehold';
import InfoTooltip from '../util/InfoTooltip';

class Patient extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      expandNotes: false,
    };
  }

  formatPhoneNumber(phone) {
    const match = phone
      .replace('+1', '')
      .replace(/\D/g, '')
      .match(/^(\d{3})(\d{3})(\d{4})$/);
    return match ? +match[1] + '-' + match[2] + '-' + match[3] : '';
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
      this.props.details.address_zip;
    const showForeignAddress =
      this.props.details.foreign_address_line_1 ||
      this.props.details.foreign_address_line_2 ||
      this.props.details.foreign_address_city ||
      this.props.details.foreign_address_zip ||
      this.props.details.foreign_address_country;
    const showArrivalSection =
      this.props.details.port_of_origin ||
      this.props.details.date_of_departure ||
      this.props.details.port_of_entry_into_usa ||
      this.props.details.date_of_arrival ||
      this.props.details.flight_or_vessel_carrier ||
      this.props.details.flight_or_vessel_number;
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
        <Row id="monitoree-details-header">
          <Col className="mt-1">
            <h4>
              <span className="pr-2">
                {`${this.props.details.first_name ? this.props.details.first_name : ''}${
                  this.props.details.middle_name ? ' ' + this.props.details.middle_name : ''
                }${this.props.details.last_name ? ' ' + this.props.details.last_name : ''}`}
              </span>
              {this.props?.dependents && this.props?.dependents?.length > 0 && <BadgeHOH patientId={String(this.props.details.id)} location={'right'} />}
            </h4>
          </Col>
          <Col md="auto" className="jursdiction-user-box mr-3">
            <Row id="jurisdiction-path">
              <Col>
                <b>Assigned Jurisdiction:</b> {this.props.jurisdiction_path || '--'}
              </Col>
            </Row>
            <Row id="assigned-user">
              <Col>
                <b>Assigned User:</b> {this.props.details.assigned_user || '--'}
              </Col>
            </Row>
          </Col>
        </Row>
        <Row className="pt-4 mx-1 mb-2">
          <Col id="identification" md="12">
            <Row>
              <Col>
                <div className="float-left">
                  <h5>
                    <b>IDENTIFICATION</b>
                  </h5>
                </div>
                <div>
                  {this.props.goto && (
                    <Button variant="link" className="pt-0" onClick={() => this.props.goto(0)}>
                      <h5>(Edit)</h5>
                    </Button>
                  )}
                </div>
                <div className="clearfix"></div>
              </Col>
            </Row>
            <Row>
              <Col className="text-truncate" md="auto">
                <Row>
                  <Col>
                    <b>DOB:</b> <span>{this.props.details.date_of_birth && moment(this.props.details.date_of_birth, 'YYYY-MM-DD').format('MM/DD/YYYY')}</span>
                  </Col>
                </Row>
                <Row>
                  <Col>
                    <b>Age:</b> <span>{this.props.details.age || '--'}</span>
                  </Col>
                </Row>
                <Row>
                  <Col>
                    <b>Language:</b> <span>{this.props.details.primary_language || '--'}</span>
                  </Col>
                </Row>
                <Row>
                  <Col>
                    <b>State/Local ID:</b> <span>{this.props.details.user_defined_id_statelocal || '--'}</span>
                  </Col>
                </Row>
                <Row>
                  <Col>
                    <b>CDC ID:</b> <span>{this.props.details.user_defined_id_cdc || '--'}</span>
                  </Col>
                </Row>
                <Row>
                  <Col>
                    <b>NNDSS ID:</b> <span>{this.props.details.user_defined_id_nndss || '--'}</span>
                  </Col>
                </Row>
              </Col>
              <Col className="text-truncate pr-2">
                <Row>
                  <Col>
                    <b>Birth Sex:</b> <span>{this.props.details.sex || '--'}</span>
                  </Col>
                </Row>
                <Row>
                  <Col>
                    <b>Gender Identity:</b> <span>{this.props.details.gender_identity || '--'}</span>
                  </Col>
                </Row>
                <Row>
                  <Col>
                    <b>Sexual Orientation:</b> <span>{this.props.details.sexual_orientation || '--'}</span>
                  </Col>
                </Row>
                <Row>
                  <Col>
                    <b>Race:</b>{' '}
                    <span>{`${this.props.details.white ? 'White' : ''}${this.props.details.black_or_african_american ? ' Black or African American' : ''}${
                      this.props.details.asian ? ' Asian' : ''
                    }${this.props.details.american_indian_or_alaska_native ? ' American Indian or Alaska Native' : ''}${
                      this.props.details.native_hawaiian_or_other_pacific_islander ? ' Native Hawaiian or Other Pacific Islander' : ''
                    }`}</span>
                  </Col>
                </Row>
                <Row>
                  <Col>
                    <b>Ethnicity:</b> <span>{this.props.details.ethnicity || '--'}</span>
                  </Col>
                </Row>
                <Row>
                  <Col>
                    <b>Nationality:</b> <span>{this.props.details.nationality || '--'}</span>
                  </Col>
                </Row>
              </Col>
            </Row>
          </Col>
          <Col id="contact-information" md="12">
            <Row>
              <Col>
                <div className="float-left">
                  <h5>
                    <b>CONTACT INFORMATION</b>
                  </h5>
                </div>
                <div>
                  {this.props.goto && (
                    <Button variant="link" className="pt-0" onClick={() => this.props.goto(2)}>
                      <h5>(Edit)</h5>
                    </Button>
                  )}
                </div>
                <div className="clearfix"></div>
              </Col>
            </Row>
            <Row>
              <Col className="text-truncate">
                <Row>
                  <Col>
                    <b>Phone:</b> <span>{this.props.details.primary_telephone ? `${this.formatPhoneNumber(this.props.details.primary_telephone)}` : '--'}</span>
                	{this.props.details.blocked_sms && (
                  		<Form.Label className="tooltip-whitespace nav-input-label font-weight-bold">
                    		&nbsp;SMS Blocked <InfoTooltip tooltipTextKey="blockedSMS" location="top"></InfoTooltip>
                  		</Form.Label>
                	)}
                  </Col>
                </Row>
                <Row>
                  <Col>
                    <b>Preferred Contact Time:</b> <span>{this.props.details.preferred_contact_time || '--'}</span>
                  </Col>
                </Row>
                <Row>
                  <Col>
                    <b>Type:</b> <span>{this.props.details.primary_telephone_type || '--'}</span>
                  </Col>
                </Row>
                <Row>
                  <Col>
                    <b>Email:</b> <span>{this.props.details.email || '--'}</span>
                  </Col>
                </Row>
                <Row>
                  <Col>
                    <b>Preferred Reporting Method:</b>{' '}
                                    {(!this.props.details.blocked_sms || !this.props.details.preferred_contact_method.includes('SMS')) && (
                  <span className="font-weight-light">{`${
                    this.props.details.preferred_contact_method ? this.props.details.preferred_contact_method : '--'
                  }`}</span>
                )}
					                {this.props.details.blocked_sms && this.props.details.preferred_contact_method.includes('SMS') && (
                  		<span className="font-weight-bold text-danger">
                    		{`${this.props.details.preferred_contact_method ? this.props.details.preferred_contact_method : '--'}`}
                    	<Form.Label className="tooltip-whitespace">
                      		<InfoTooltip tooltipTextKey="blockedSMSContactMethod" location="top"></InfoTooltip>
                    	</Form.Label>
                  		</span>
                	)}
                  </Col>
                </Row>
              </Col>
            </Row>
          </Col>
        </Row>
        <Collapse in={!this.props.hideBody}>
          <Card.Body className="mx-0 px-0 my-0 py-0">
            <Row className="g-border-bottom-2 mx-2 pb-4 mb-2"></Row>
            <Row className="g-border-bottom-2 pb-4 mb-2 mt-4 mx-1">
              <Col id="address" md="7">
                <Row>
                  <Col>
                    <div className="float-left">
                      <h5>
                        <b>ADDRESS</b>
                      </h5>
                    </div>
                    <div>
                      {this.props.goto && (
                        <Button variant="link" className="pt-0" onClick={() => this.props.goto(1)}>
                          <h5>(Edit)</h5>
                        </Button>
                      )}
                    </div>
                    <div className="clearfix"></div>
                  </Col>
                </Row>
                <Row>
                  <Col className="text-truncate">
                    {!showDomesticAddress && !showForeignAddress && (
                      <Row className="py-1">
                        <Col className="text-truncate">
                          <span className="none-text">None</span>
                        </Col>
                      </Row>
                    )}
                    {showDomesticAddress ||
                      (showForeignAddress && (
                        <Row className="py-1">
                          <Col>
                            <b>HOME ADDRESS</b>
                          </Col>
                        </Row>
                      ))}
                    {showDomesticAddress && (
                      <React.Fragment>
                        <Row>
                          <Col>
                            <b>Address 1:</b> <span>{this.props.details.address_line_1 || '--'}</span>
                          </Col>
                        </Row>
                        <Row>
                          <Col>
                            <b>Address 2:</b> <span>{this.props.details.address_line_2 || '--'}</span>
                          </Col>
                        </Row>
                        <Row>
                          <Col>
                            <b>Town/City:</b> <span>{this.props.details.address_city || '--'}</span>
                          </Col>
                          <Col>
                            <b>State:</b> <span>{this.props.details.address_state || '--'}</span>
                          </Col>
                          <Col>
                            <b>Zip:</b> <span>{this.props.details.address_zip || '--'}</span>
                          </Col>
                        </Row>
                      </React.Fragment>
                    )}
                    {showForeignAddress && (
                      <React.Fragment>
                        <Row>
                          <Col>
                            <b>Address 1:</b> <span>{this.props.details.foreign_address_line_1 || '--'}</span>
                          </Col>
                        </Row>
                        <Row>
                          <Col>
                            <b>Address 2:</b> <span>{this.props.details.foreign_address_line_2 || '--'}</span>
                          </Col>
                        </Row>
                        <Row>
                          <Col>
                            <b>Town/City:</b> <span>{this.props.details.foreign_address_city || '--'}</span>
                          </Col>
                          <Col>
                            <b>Zip:</b> <span>{this.props.details.foreign_address_zip || '--'}</span>
                          </Col>
                        </Row>
                        <Row>
                          <Col>
                            <b>Country:</b> <span>{this.props.details.foreign_address_country || '--'}</span>
                          </Col>
                        </Row>
                      </React.Fragment>
                    )}
                  </Col>
                </Row>
              </Col>
              <Col id="arrival-information" md="10">
                <Row>
                  <Col>
                    <div className="float-left">
                      <h5>
                        <b>ARRIVAL INFORMATION</b>
                      </h5>
                    </div>
                    <div>
                      {this.props.goto && (
                        <Button variant="link" className="pt-0" onClick={() => this.props.goto(3)}>
                          <h5>(Edit)</h5>
                        </Button>
                      )}
                    </div>
                    <div className="clearfix"></div>
                  </Col>
                </Row>
                <Row>
                  {!showArrivalSection && (
                    <Col className="text-truncate">
                      <span className="none-text">None</span>
                    </Col>
                  )}
                  {showArrivalSection && (
                    <React.Fragment>
                      <Col>
                        <Row>
                          <Col className="text-truncate departed-col">
                            <Row className="py-1">
                              <Col>
                                <b>DEPARTED</b>
                              </Col>
                            </Row>
                            <Row>
                              <Col>
                                <b>Port of Origin:</b> <span>{this.props.details.port_of_origin || '--'}</span>
                              </Col>
                            </Row>
                            <Row>
                              <Col>
                                <b>Date of Departure:</b>{' '}
                                <span>
                                  {this.props.details.date_of_departure
                                    ? moment(this.props.details.date_of_departure, 'YYYY-MM-DD').format('MM/DD/YYYY')
                                    : '--'}
                                </span>
                              </Col>
                            </Row>
                          </Col>
                          <Col className="text-truncate arrival-col">
                            <Row className="py-1">
                              <Col>
                                <b>ARRIVAL</b>
                              </Col>
                            </Row>
                            <Row>
                              <Col>
                                <b>Port of Entry:</b> <span>{this.props.details.port_of_entry_into_usa || '--'}</span>
                              </Col>
                            </Row>
                            <Row>
                              <Col>
                                <b>Date of Arrival:</b>{' '}
                                <span>
                                  {this.props.details.date_of_arrival ? moment(this.props.details.date_of_arrival, 'YYYY-MM-DD').format('MM/DD/YYYY') : '--'}
                                </span>
                              </Col>
                            </Row>
                          </Col>
                        </Row>
                        <Row className="carrier-row">
                          <Col className="text-truncate pt-1">
                            <Row>
                              <Col>
                                <b>Carrier:</b> <span>{this.props.details.flight_or_vessel_carrier || '--'}</span>
                              </Col>
                            </Row>
                            <Row>
                              <Col>
                                <b>Flight or Vessel Number:</b> <span>{this.props.details.flight_or_vessel_number || '--'}</span>
                              </Col>
                            </Row>
                          </Col>
                        </Row>
                      </Col>
                    </React.Fragment>
                  )}
                </Row>
              </Col>
              <Col id="planned-travel" md="7">
                <Row>
                  <Col>
                    <div className="float-left">
                      <h5>
                        <b>PLANNED TRAVEL</b>
                      </h5>
                    </div>
                    <div>
                      {this.props.goto && (
                        <Button variant="link" className="pt-0" onClick={() => this.props.goto(4)}>
                          <h5>(Edit)</h5>
                        </Button>
                      )}
                    </div>
                    <div className="clearfix"></div>
                  </Col>
                </Row>
                <Row>
                  <Col className="text-truncate">
                    {!showPlannedTravel && <span className="none-text">None</span>}
                    {showPlannedTravel && (
                      <React.Fragment>
                        <Row>
                          <Col>
                            <b>Type:</b> <span>{this.props.details.additional_planned_travel_type || '--'}</span>
                          </Col>
                        </Row>
                        <Row>
                          <Col>
                            <b>Place:</b>{' '}
                            <span>
                              {this.props.details.additional_planned_travel_destination_country}
                              {this.props.details.additional_planned_travel_destination_state}
                              {!this.props.details.additional_planned_travel_destination_country &&
                                !this.props.details.additional_planned_travel_destination_state &&
                                '--'}
                            </span>
                          </Col>
                        </Row>
                        <Row>
                          <Col>
                            <b>Port Of Departure:</b> <span>{this.props.details.additional_planned_travel_port_of_departure || '--'}</span>
                          </Col>
                        </Row>
                        <Row>
                          <Col>
                            <b>End Date:</b>{' '}
                            <span>
                              {this.props.details.additional_planned_travel_start_date
                                ? moment(this.props.details.additional_planned_travel_start_date, 'YYYY-MM-DD').format('MM/DD/YYYY')
                                : '--'}
                            </span>
                          </Col>
                        </Row>
                        <Row>
                          <Col>
                            <b>Start Date:</b>{' '}
                            <span>
                              {this.props.details.additional_planned_travel_end_date
                                ? moment(this.props.details.additional_planned_travel_end_date, 'YYYY-MM-DD').format('MM/DD/YYYY')
                                : '--'}
                            </span>
                          </Col>
                        </Row>
                      </React.Fragment>
                    )}
                  </Col>
                </Row>
              </Col>
            </Row>
            <Row className="g-border-bottom-2 pb-4 mb-2 mt-4 mx-1">
              <Col id="potential-exposure-information" md="12">
                <Row>
                  <Col>
                    <div className="float-left">
                      <h5>
                        <b>POTENTIAL EXPOSURE INFORMATION</b>
                      </h5>
                    </div>
                    <div>
                      {this.props.goto && (
                        <Button variant="link" className="pt-0" onClick={() => this.props.goto(5)}>
                          <h5>(Edit)</h5>
                        </Button>
                      )}
                    </div>
                    <div className="clearfix"></div>
                  </Col>
                </Row>
                <Row className="pt-2">
                  <Col>
                    <Row>
                      <Col>
                        <b>Last Date of Exposure:</b> <span>{moment(this.props.details.last_date_of_exposure, 'YYYY-MM-DD').format('MM/DD/YYYY')}</span>
                      </Col>
                    </Row>
                    <Row className="pt-2">
                      <Col>
                        <b>Exposure Location:</b> <span>{this.props.details.potential_exposure_location || '--'}</span>
                      </Col>
                      <Col>
                        <b>Exposure Country:</b> <span>{this.props.details.potential_exposure_country || '--'}</span>
                      </Col>
                    </Row>
                    <Row className="pt-3">
                      <Col>
                        <b>Risk Factors</b>
                      </Col>
                    </Row>
                    {!showRiskFactors && <span className="none-text">None</span>}
                    {showRiskFactors && (
                      <React.Fragment>
                        {this.props.details.contact_of_known_case && (
                          <Row>
                            <Col>
                              <b className="text-danger">CLOSE CONTACT WITH A KNOWN CASE</b>
                              {this.props.details.contact_of_known_case_id && <span>{`: ${this.props.details.contact_of_known_case_id}`}</span>}
                            </Col>
                          </Row>
                        )}
                        {this.props.details.member_of_a_common_exposure_cohort && (
                          <Row>
                            <Col>
                              <b className="text-danger">MEMBER OF A COMMON EXPOSURE COHORT</b>
                              {this.props.details.member_of_a_common_exposure_cohort_type && (
                                <span>{`: ${this.props.details.member_of_a_common_exposure_cohort_type}`}</span>
                              )}
                            </Col>
                          </Row>
                        )}
                        {this.props.details.travel_to_affected_country_or_area && (
                          <Row>
                            <Col>
                              <b className="text-danger">TRAVEL FROM AFFECTED COUNTRY OR AREA</b>
                            </Col>
                          </Row>
                        )}
                        {this.props.details.was_in_health_care_facility_with_known_cases && (
                          <Row>
                            <Col>
                              <b className="text-danger">WAS IN HEALTH CARE FACILITY WITH KNOWN CASES</b>
                              {this.props.details.was_in_health_care_facility_with_known_cases_facility_name && (
                                <span>{`: ${this.props.details.was_in_health_care_facility_with_known_cases_facility_name}`}</span>
                              )}
                            </Col>
                          </Row>
                        )}
                        {this.props.details.laboratory_personnel && (
                          <Row>
                            <Col>
                              <b className="text-danger">LABORATORY PERSONNEL</b>
                              {this.props.details.laboratory_personnel_facility_name && (
                                <span>{`: ${this.props.details.laboratory_personnel_facility_name}`}</span>
                              )}
                            </Col>
                          </Row>
                        )}
                        {this.props.details.healthcare_personnel && (
                          <Row>
                            <Col>
                              <b className="text-danger">HEALTHCARE PERSONNEL</b>
                              {this.props.details.healthcare_personnel_facility_name && (
                                <span>{`: ${this.props.details.healthcare_personnel_facility_name}`}</span>
                              )}
                            </Col>
                          </Row>
                        )}
                        {this.props.details.crew_on_passenger_or_cargo_flight && (
                          <Row>
                            <Col>
                              <b className="text-danger">CREW ON PASSENGER OR CARGO FLIGHT</b>
                            </Col>
                          </Row>
                        )}
                      </React.Fragment>
                    )}
                  </Col>
                </Row>
              </Col>
              <Col id="exposure-notes" md="12">
                <Row>
                  <Col>
                    <div className="float-left">
                      <h5>
                        <b>EXPOSURE NOTES</b>
                      </h5>
                    </div>
                    <div className="clearfix"></div>
                  </Col>
                </Row>
                <Row>
                  <Col>
                    {this.props.details.exposure_notes && (
                      <React.Fragment>
                        {this.props.details.exposure_notes.length < 500 && (
                          <Row>
                            <Col>
                              <span>{this.props.details.exposure_notes}</span>
                            </Col>
                          </Row>
                        )}
                        {this.props.details.exposure_notes.length >= 500 && (
                          <React.Fragment>
                            <Row>
                              <Col>
                                <span>
                                  {this.state.expandNotes ? this.props.details.exposure_notes : this.props.details.exposure_notes.slice(0, 500) + ' ...'}
                                </span>
                              </Col>
                            </Row>
                            <Row>
                              <Col>
                                <Button variant="link" className="px-0 btn btn-link" onClick={() => this.setState({ expandNotes: !this.state.expandNotes })}>
                                  {this.state.expandNotes ? '(Collapse)' : '(View all)'}
                                </Button>
                              </Col>
                            </Row>
                          </React.Fragment>
                        )}
                      </React.Fragment>
                    )}
                    {!this.props.details.exposure_notes && <span className="none-text">None</span>}
                  </Col>
                </Row>
              </Col>
            </Row>
            {(this.props.details.isolation || (!this.props.details.isolation && this.props.details.exposure_notes)) && (
              <Row className="g-border-bottom-2 pb-4 mb-2 mt-4 mx-1">
                <Col id="case-information" md="12">
                  <Row>
                    <Col>
                      <div className="float-left">
                        <h5>
                          <b>CASE INFORMATION</b>
                        </h5>
                      </div>
                      <div>
                        {this.props.goto && (
                          <Button variant="link" className="pt-0" onClick={() => this.props.goto(5)}>
                            <h5>(Edit)</h5>
                          </Button>
                        )}
                      </div>
                      <div className="clearfix"></div>
                    </Col>
                  </Row>
                  <Row>
                    <Col className="text-truncate">
                      <Row>
                        <Col>
                          <b>Symptom Onset:</b>{' '}
                          <span>{this.props.details.symptom_onset ? moment(this.props.details.symptom_onset, 'YYYY-MM-DD').format('MM/DD/YYYY') : '--'}</span>
                        </Col>
                      </Row>
                      <Row>
                        <Col>
                          <b>Case Status:</b> <span>{this.props.details.case_status || '--'}</span>
                        </Col>
                      </Row>
                    </Col>
                  </Row>
                </Col>
              </Row>
            )}
          </Card.Body>
        </Collapse>
        {this.props?.details?.responder_id && this.props.details.responder_id != this.props.details.id && (
          <div id="household-member-not-hoh" className="pt-2">
            <Row className="mx-3">
              The reporting responsibility for this monitoree is handled by another monitoree.&nbsp;
              <a href={'/patients/' + this.props.details.responder_id}>Click here to view that monitoree</a>.
            </Row>
            <Row className="pb-2 mx-3">
              <RemoveFromHousehold patient={this.props?.details} dependents={this.props?.dependents} authenticity_token={this.props.authenticity_token} />
            </Row>
          </div>
        )}
        {this.props?.dependents && this.props?.dependents?.length > 0 && (
          <Row id="head-of-household" className="pb-3 mx-3 pt-3">
            <Col>
              <Row className="pb-2">This monitoree is responsible for handling the reporting of the following other monitorees:</Row>
              <Row>
                <Table striped bordered hover size="sm">
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Workflow</th>
                      <th>Monitoring Status</th>
                      <th>Continuous Exposure?</th>
                    </tr>
                  </thead>
                  <tbody>
                    {this.props?.dependents?.map((member, index) => {
                      return (
                        <tr key={`dl-${index}`}>
                          <td>
                            <a href={'/patients/' + member.id}>
                              {member.last_name}, {member.first_name} {member.middle_name || ''}
                            </a>
                          </td>
                          <td>{member.isolation ? 'Isolation' : 'Exposure'}</td>
                          <td>{member.monitoring ? 'Actively Monitoring' : 'Not Monitoring'}</td>
                          <td>{member.continuous_exposure ? 'Yes' : 'No'}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </Table>
              </Row>
              <Row>
                <ChangeHOH patient={this.props?.details} dependents={this.props?.dependents} authenticity_token={this.props.authenticity_token} />
              </Row>
            </Col>
          </Row>
        )}
        {this.props?.dependents &&
          this.props?.dependents?.length == 0 &&
          this.props?.details?.responder_id &&
          this.props.details.responder_id == this.props.details.id && (
            <Row id="no-household" className="pb-3 mx-3 pt-2">
              <Col>
                <Row>This monitoree is not a member of a household:</Row>
                {this.props?.dependents?.map((member, index) => {
                  return (
                    <Row key={'gm' + index}>
                      <a href={'/patients/' + member.id}>
                        {member.last_name}, {member.first_name} {member.middle_name || ''}
                      </a>
                    </Row>
                  );
                })}
                <Row>
                  <MoveToHousehold patient={this.props?.details} dependents={this.props?.dependents} authenticity_token={this.props.authenticity_token} />
                </Row>
              </Col>
            </Row>
          )}
      </React.Fragment>
    );
  }
}

Patient.propTypes = {
  dependents: PropTypes.array,
  details: PropTypes.object,
  jurisdiction_path: PropTypes.string,
  goto: PropTypes.func,
  hideBody: PropTypes.bool,
  authenticity_token: PropTypes.string,
};

export default Patient;
