import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Col, Form, Row, Table } from 'react-bootstrap';
// import { Col, Row Button, Collapse, Card, Table, Form } from 'react-bootstrap';
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

    // const showDomesticAddress =
    //   this.props.details.address_line_1 ||
    //   this.props.details.address_line_2 ||
    //   this.props.details.address_city ||
    //   this.props.details.address_state ||
    //   this.props.details.address_zip;
    // const showForeignAddress =
    //   this.props.details.foreign_address_line_1 ||
    //   this.props.details.foreign_address_line_2 ||
    //   this.props.details.foreign_address_city ||
    //   this.props.details.foreign_address_zip ||
    //   this.props.details.foreign_address_country;
    // const showArrivalSection =
    //   this.props.details.port_of_origin ||
    //   this.props.details.date_of_departure ||
    //   this.props.details.port_of_entry_into_usa ||
    //   this.props.details.date_of_arrival ||
    //   this.props.details.flight_or_vessel_carrier ||
    //   this.props.details.flight_or_vessel_number;
    // const showPlannedTravel =
    //   this.props.details.additional_planned_travel_type ||
    //   this.props.details.additional_planned_travel_destination_country ||
    //   this.props.details.additional_planned_travel_destination_state ||
    //   this.props.details.additional_planned_travel_port_of_departure ||
    //   this.props.details.additional_planned_travel_start_date ||
    //   this.props.details.additional_planned_travel_end_date;
    // const showRiskFactors =
    //   this.props.details.contact_of_known_case ||
    //   this.props.details.member_of_a_common_exposure_cohort ||
    //   this.props.details.travel_to_affected_country_or_area ||
    //   this.props.details.was_in_health_care_facility_with_known_cases ||
    //   this.props.details.laboratory_personnel ||
    //   this.props.details.healthcare_personnel ||
    //   this.props.details.crew_on_passenger_or_cargo_flight;

    console.log(this.props.details);
    return (
      <React.Fragment>
        <Row id="monitoree-details-header">
          <Col sm={12} className="h3">
            <span>
              {`${this.props.details.first_name ? this.props.details.first_name : ''}${
                this.props.details.middle_name ? ' ' + this.props.details.middle_name : ''
              }${this.props.details.last_name ? ' ' + this.props.details.last_name : ''} `}
            </span>
            {this.props?.dependents && this.props?.dependents?.length > 0 && <BadgeHOH patientId={String(this.props.details.id)} location={'right'} />}
            <div className="clearfix"></div>
          </Col>
          <Col sm={12}>
            <div className="jurisdiction-user-box">
              <div id="jurisdiction-path">
                <b>
                  <span className="d-none d-md-inline">Assigned</span> Jurisdiction:
                </b>{' '}
                {this.props.jurisdiction_path || '--'}
              </div>
              <div id="assigned-user">
                <b>Assigned User:</b> {this.props.details.assigned_user || '--'}
              </div>
            </div>
          </Col>
        </Row>
        <Row>
          {/* TO DO: ADD XXL CLASES HERE (with large)*/}
          <Col lg={14}>
            <div className="section-header my-3">
              <h4 className="section-title">Identification</h4>
              <div className="edit-link">
                {this.props.goto && (
                  <Button variant="link" className="py-0" onClick={() => this.props.goto(0)} aria-label="Edit Identification">
                    Edit
                  </Button>
                )}
              </div>
            </div>
            <Row>
              <Col sm={10}>
                <div>
                  <b>DOB:</b> <span>{this.props.details.date_of_birth && moment(this.props.details.date_of_birth, 'YYYY-MM-DD').format('MM/DD/YYYY')}</span>
                </div>
                <div>
                  <b>Age:</b> <span>{this.props.details.age || '--'}</span>
                </div>
                <div>
                  <b>Language:</b> <span>{this.props.details.primary_language || '--'}</span>
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
              <Col sm={14}>
                <div>
                  <b>Birth:</b> <span>{this.props.details.sex || '--'}</span>
                </div>
                <div>
                  <b>Gender:</b> <span>{this.props.details.gender_identity || '--'}</span>
                </div>
                <div>
                  <b>Sex:</b> <span>{this.props.details.sexual_orientation || '--'}</span>
                </div>
                <div>
                  <b>Race:</b>{' '}
                  <span>{`${this.props.details.white ? 'White' : ''}${this.props.details.black_or_african_american ? ' Black or African American' : ''}${
                    this.props.details.asian ? ' Asian' : ''
                  }${this.props.details.american_indian_or_alaska_native ? ' American Indian or Alaska Native' : ''}${
                    this.props.details.native_hawaiian_or_other_pacific_islander ? ' Native Hawaiian or Other Pacific Islander' : ''
                  }`}</span>
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
          <Col lg={10}>
            <div className="section-header my-3">
              <h4 className="section-title">Contact Information</h4>
              <div className="edit-link">
                {this.props.goto && (
                  <Button variant="link" className="py-0" onClick={() => this.props.goto(2)} aria-label="Edit Contact Information">
                    Edit
                  </Button>
                )}
              </div>
            </div>
            <div>
              <div>
                <b>Phone:</b> <span>{this.props.details.primary_telephone ? `${this.formatPhoneNumber(this.props.details.primary_telephone)}` : '--'}</span>
                {this.props.details.blocked_sms && (
                  <Form.Label className="tooltip-whitespace nav-input-label font-weight-bold">
                    &nbsp;SMS Blocked <InfoTooltip tooltipTextKey="blockedSMS" location="top"></InfoTooltip>
                  </Form.Label>
                )}
              </div>
              <div>
                <b>Preferred Contact Time:</b> <span>{this.props.details.preferred_contact_time || '--'}</span>
              </div>
              <div>
                <b>Type:</b> <span>{this.props.details.primary_telephone_type || '--'}</span>
              </div>
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
                    {this.props.details.preferred_contact_method || '--'}
                    <Form.Label className="tooltip-whitespace">
                      <InfoTooltip tooltipTextKey="blockedSMSContactMethod" location="top"></InfoTooltip>
                    </Form.Label>
                  </span>
                )}
              </div>
            </div>
          </Col>
        </Row>

        {/* TO DO: FIX THIS STYLING */}
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
                  <MoveToHousehold patient={this.props?.details} authenticity_token={this.props.authenticity_token} />
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
