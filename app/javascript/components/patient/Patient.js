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
          <Col md="auto">
            <span className="jurisdiction-user-box">
              <span id="jurisdiction-path">
                <b>Assigned Jurisdiction:</b> {this.props.jurisdiction_path ? this.props.jurisdiction_path : '--'}
              </span>
              <br />
              <span id="assigned-user">
                <b>Assigned User:</b> {this.props.details.assigned_user ? this.props.details.assigned_user : '--'}
              </span>
            </span>
          </Col>
        </Row>
        <Row className="pt-4 mx-1 mb-2">
          <Col id="identification" md="11">
            <Row>
              <Col>
                <div className="float-left">
                  <h5>
                    <b>IDENTIFICATION</b>
                  </h5>
                </div>
                <div className="float-right">
                  {this.props.goto && (
                    <Button variant="link" className="pt-0" onClick={() => this.props.goto(0)}>
                      <h5>Edit</h5>
                    </Button>
                  )}
                </div>
                <div className="clearfix"></div>
              </Col>
            </Row>
            <Row>
              <Col className="text-truncate">
                <b>DOB:</b> <span>{this.props.details.date_of_birth && `${moment(this.props.details.date_of_birth, 'YYYY-MM-DD').format('MM/DD/YYYY')}`}</span>
                <br />
                <b>Age:</b> <span>{`${this.props.details.age ? this.props.details.age : '--'}`}</span>
                <br />
                <b>Language:</b> <span>{`${this.props.details.primary_language ? this.props.details.primary_language : '--'}`}</span>
                <br />
                <b>State/Local ID:</b> <span>{`${this.props.details.user_defined_id_statelocal ? this.props.details.user_defined_id_statelocal : '--'}`}</span>
                <br />
                <b>CDC ID:</b> <span>{`${this.props.details.user_defined_id_cdc ? this.props.details.user_defined_id_cdc : '--'}`}</span>
                <br />
                <b>NNDSS ID:</b> <span>{`${this.props.details.user_defined_id_nndss ? this.props.details.user_defined_id_nndss : '--'}`}</span>
              </Col>
              <Col className="text-truncate">
                <b>Birth Sex:</b> <span>{`${this.props.details.sex ? this.props.details.sex : '--'}`}</span>
                <br />
                <b>Gender Identity:</b> <span>{`${this.props.details.gender_identity ? this.props.details.gender_identity : '--'}`}</span>
                <br />
                <b>Sexual Orientation:</b> <span>{`${this.props.details.sexual_orientation ? this.props.details.sexual_orientation : '--'}`}</span>
                <br />
                <b>Race:</b>{' '}
                <span>{`${this.props.details.white ? 'White' : ''}${this.props.details.black_or_african_american ? ' Black or African American' : ''}${
                  this.props.details.asian ? ' Asian' : ''
                }${this.props.details.american_indian_or_alaska_native ? ' American Indian or Alaska Native' : ''}${
                  this.props.details.native_hawaiian_or_other_pacific_islander ? ' Native Hawaiian or Other Pacific Islander' : ''
                }`}</span>
                <br />
                <b>Ethnicity:</b> <span>{`${this.props.details.ethnicity ? this.props.details.ethnicity : '--'}`}</span>
                <br />
                <b>Nationality:</b> <span>{`${this.props.details.nationality ? this.props.details.nationality : '--'}`}</span>
                <br />
              </Col>
            </Row>
          </Col>
          <Col md="2"></Col>
          <Col id="contact-information" md="11">
            <Row>
              <Col>
                <div className="float-left">
                  <h5>
                    <b>CONTACT INFORMATION</b>
                  </h5>
                </div>
                <div className="float-right">
                  {this.props.goto && (
                    <Button variant="link" className="pt-0" onClick={() => this.props.goto(2)}>
                      <h5>Edit</h5>
                    </Button>
                  )}
                </div>
                <div className="clearfix"></div>
              </Col>
            </Row>
            <Row>
              <Col className="text-truncate">
                <b>Phone:</b> <span>{this.props.details.primary_telephone ? `${this.formatPhoneNumber(this.props.details.primary_telephone)}` : '--'}</span>
                <span className="text-danger">{this.props.details.blocked_sms && ' This Phone Number Has Blocked SMS Communication With Sara Alert'}</span>
                {this.props.details.blocked_sms && (
                  <Form.Label className="nav-input-label text-danger">
                  SMS Communication Blocked <InfoTooltip tooltipTextKey="blockedSMS" location="right"></InfoTooltip>
                  </Form.Label>
                )}
                <br />
                <b>Preferred Contact Time:</b> <span>{this.props.details.preferred_contact_time ? `${this.props.details.preferred_contact_time}` : '--'}</span>
                <br />
                <b>Type:</b> <span>{`${this.props.details.primary_telephone_type ? this.props.details.primary_telephone_type : '--'}`}</span>
                <br />
                <b>Email:</b> <span>{`${this.props.details.email ? this.props.details.email : '--'}`}</span>
                <br />
                <b>Preferred Reporting Method:</b>{' '}
                <span>{`${this.props.details.preferred_contact_method ? this.props.details.preferred_contact_method : '--'}`}</span>
              </Col>
            </Row>
          </Col>
        </Row>
        <Collapse in={!this.props.hideBody}>
          <Card.Body className="mx-0 px-0 my-0 py-0">
            <Row className="g-border-bottom-2 mx-2 pb-4 mb-2"></Row>
            <Row className="g-border-bottom-2 pb-4 mb-2 mt-4 mx-1">
              <Col id="address" md="11">
                <Row>
                  <Col>
                    <div className="float-left">
                      <h5>
                        <b>ADDRESS</b>
                      </h5>
                    </div>
                    <div className="float-right">
                      {this.props.goto && (
                        <Button variant="link" className="pt-0" onClick={() => this.props.goto(1)}>
                          <h5>Edit</h5>
                        </Button>
                      )}
                    </div>
                    <div className="clearfix"></div>
                  </Col>
                </Row>
                <Row>
                  <Col className="text-truncate">
                    <span>
                      {this.props.details.address_line_1 && `${this.props.details.address_line_1}`}
                      {this.props.details.address_line_2 && ` ${this.props.details.address_line_2}`}
                      {this.props.details.foreign_address_line_1 && `${this.props.details.foreign_address_line_1}`}
                      {this.props.details.foreign_address_line_2 && ` ${this.props.details.foreign_address_line_2}`}
                    </span>
                    <br />
                    <span>
                      {this.props.details.address_city ? this.props.details.address_city : ''}
                      {this.props.details.address_state ? ` ${this.props.details.address_state}` : ''}
                      {this.props.details.address_county ? ` ${this.props.details.address_county}` : ''}
                      {this.props.details.address_zip ? ` ${this.props.details.address_zip}` : ''}
                      {this.props.details.foreign_address_city ? this.props.details.foreign_address_city : ''}
                      {this.props.details.foreign_address_country ? ` ${this.props.details.foreign_address_country}` : ''}
                      {this.props.details.foreign_address_zip ? ` ${this.props.details.foreign_address_zip}` : ''}
                    </span>
                    <br />
                  </Col>
                </Row>
              </Col>
              <Col md="2"></Col>
              <Col id="arrival-information" md="11">
                <Row>
                  <Col>
                    <div className="float-left">
                      <h5>
                        <b>ARRIVAL INFORMATION</b>
                      </h5>
                    </div>
                    <div className="float-right">
                      {this.props.goto && (
                        <Button variant="link" className="pt-0" onClick={() => this.props.goto(3)}>
                          <h5>Edit</h5>
                        </Button>
                      )}
                    </div>
                    <div className="clearfix"></div>
                  </Col>
                </Row>
                <Row>
                  <Col className="text-truncate">
                    <b>DEPARTED</b>
                    <br />
                    <span>{this.props.details.port_of_origin && `${this.props.details.port_of_origin}`}</span>
                    <br />
                    <span>{`${
                      this.props.details.date_of_departure ? moment(this.props.details.date_of_departure, 'YYYY-MM-DD').format('MM/DD/YYYY') : ''
                    }`}</span>
                  </Col>
                  <Col className="text-truncate">
                    <b>ARRIVAL</b>
                    <br />
                    <span>{`${this.props.details.port_of_entry_into_usa ? this.props.details.port_of_entry_into_usa : ''}`}</span>
                    <br />
                    <span>{`${this.props.details.date_of_arrival ? moment(this.props.details.date_of_arrival, 'YYYY-MM-DD').format('MM/DD/YYYY') : ''}`}</span>
                  </Col>
                </Row>
                <Row>
                  <Col className="text-truncate pt-1">
                    <span>{this.props.details.flight_or_vessel_carrier && `${this.props.details.flight_or_vessel_carrier}`}</span>
                    <br />
                    <span>{this.props.details.flight_or_vessel_number && `${this.props.details.flight_or_vessel_number}`}</span>
                  </Col>
                </Row>
              </Col>
            </Row>
            <Row className="g-border-bottom-2 pb-4 mb-2 mt-4 mx-1">
              <Col id="additional-planned-travel" md="11">
                <Row>
                  <Col>
                    <div className="float-left">
                      <h5>
                        <b>ADDITIONAL PLANNED TRAVEL</b>
                      </h5>
                    </div>
                    <div className="float-right">
                      {this.props.goto && (
                        <Button variant="link" className="pt-0" onClick={() => this.props.goto(4)}>
                          <h5>Edit</h5>
                        </Button>
                      )}
                    </div>
                    <div className="clearfix"></div>
                  </Col>
                </Row>
                <Row>
                  <Col className="text-truncate">
                    <b>Type:</b>{' '}
                    <span>{this.props.details.additional_planned_travel_type ? `${this.props.details.additional_planned_travel_type}` : '--'}</span>
                    <br />
                    <b>Place:</b>{' '}
                    <span>
                      {`${
                        this.props.details.additional_planned_travel_destination_country ? this.props.details.additional_planned_travel_destination_country : ''
                      }`}
                      {`${
                        this.props.details.additional_planned_travel_destination_state ? this.props.details.additional_planned_travel_destination_state : ''
                      }`}
                      {!this.props.details.additional_planned_travel_destination_country &&
                        !this.props.details.additional_planned_travel_destination_state &&
                        '--'}
                    </span>
                    <br />
                    <b>Port Of Departure:</b>{' '}
                    <span>{`${
                      this.props.details.additional_planned_travel_port_of_departure ? this.props.details.additional_planned_travel_port_of_departure : '--'
                    }`}</span>
                    <br />
                    <b>End Date:</b>{' '}
                    <span>{`${
                      this.props.details.additional_planned_travel_start_date
                        ? moment(this.props.details.additional_planned_travel_start_date, 'YYYY-MM-DD').format('MM/DD/YYYY')
                        : '--'
                    }`}</span>
                    <br />
                    <b>Start Date:</b>{' '}
                    <span>{`${
                      this.props.details.additional_planned_travel_end_date
                        ? moment(this.props.details.additional_planned_travel_end_date, 'YYYY-MM-DD').format('MM/DD/YYYY')
                        : '--'
                    }`}</span>
                  </Col>
                </Row>
              </Col>
              <Col md="2"></Col>
              <Col id="exposure-case-information" md="11">
                <Row>
                  <Col>
                    <div className="float-left">
                      <h5>
                        {!this.props.details.isolation && <b>POTENTIAL EXPOSURE INFORMATION</b>}
                        {this.props.details.isolation && <b>CASE INFORMATION</b>}
                      </h5>
                    </div>
                    <div className="float-right">
                      {this.props.goto && (
                        <Button variant="link" className="pt-0" onClick={() => this.props.goto(5)}>
                          <h5>Edit</h5>
                        </Button>
                      )}
                    </div>
                    <div className="clearfix"></div>
                  </Col>
                </Row>
                <Row>
                  {!this.props.details.isolation && (
                    <Col className="text-truncate">
                      <b>LAST EXPOSURE</b>
                      <br />
                      {(this.props.details.potential_exposure_location || this.props.details.potential_exposure_country) && (
                        <React.Fragment>
                          <span>
                            {`${this.props.details.potential_exposure_location ? this.props.details.potential_exposure_location : ''}`}
                            {`${this.props.details.potential_exposure_country ? ' ' + this.props.details.potential_exposure_country : ''}`}
                          </span>
                          <br />
                        </React.Fragment>
                      )}
                      {this.props.details.last_date_of_exposure && (
                        <React.Fragment>
                          <span>{moment(this.props.details.last_date_of_exposure, 'YYYY-MM-DD').format('MM/DD/YYYY')}</span>
                          <br />
                        </React.Fragment>
                      )}
                      {this.props.details.contact_of_known_case && (
                        <React.Fragment>
                          <span className="text-danger">CLOSE CONTACT WITH A KNOWN CASE: {this.props.details.contact_of_known_case_id}</span>
                          <br />
                        </React.Fragment>
                      )}
                      {this.props.details.member_of_a_common_exposure_cohort && (
                        <React.Fragment>
                          <span className="text-danger">MEMBER OF A COMMON EXPOSURE COHORT: {this.props.details.member_of_a_common_exposure_cohort_type}</span>
                          <br />
                        </React.Fragment>
                      )}
                      {this.props.details.travel_to_affected_country_or_area && (
                        <React.Fragment>
                          <span className="text-danger">TRAVEL FROM AFFECTED COUNTRY OR AREA</span>
                          <br />
                        </React.Fragment>
                      )}
                      {this.props.details.was_in_health_care_facility_with_known_cases && (
                        <React.Fragment>
                          <span className="text-danger">
                            WAS IN HEALTH CARE FACILITY WITH KNOWN CASES: {this.props.details.was_in_health_care_facility_with_known_cases_facility_name || ''}
                          </span>
                          <br />
                        </React.Fragment>
                      )}
                      {this.props.details.laboratory_personnel && (
                        <React.Fragment>
                          <span className="text-danger">LABORATORY PERSONNEL: {this.props.details.laboratory_personnel_facility_name || ''}</span>
                          <br />
                        </React.Fragment>
                      )}
                      {this.props.details.healthcare_personnel && (
                        <React.Fragment>
                          <span className="text-danger">HEALTHCARE PERSONNEL: {this.props.details.healthcare_personnel_facility_name || ''}</span>
                          <br />
                        </React.Fragment>
                      )}
                      {this.props.details.crew_on_passenger_or_cargo_flight && (
                        <React.Fragment>
                          <span className="text-danger">CREW ON PASSENGER OR CARGO FLIGHT</span>
                          <br />
                        </React.Fragment>
                      )}
                    </Col>
                  )}
                  {this.props.details.isolation && (
                    <Col className="text-truncate">
                      {this.props.details.symptom_onset && (
                        <React.Fragment>
                          <span>
                            <b>Symptom Onset:</b> {moment(this.props.details.symptom_onset, 'YYYY-MM-DD').format('MM/DD/YYYY')}
                          </span>
                          <br />
                        </React.Fragment>
                      )}
                      {this.props.details.case_status && (
                        <React.Fragment>
                          <span>
                            <b>Case Status:</b> {this.props.details.case_status}
                          </span>
                          <br />
                        </React.Fragment>
                      )}
                    </Col>
                  )}
                </Row>
              </Col>
            </Row>
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
