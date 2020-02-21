import React from 'react';
import { Col, Row, Button } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class Patient extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    if (!this.props.details) {
      return <React.Fragment>No monitoree details to show.</React.Fragment>;
    }
    return (
      <React.Fragment>
        {this.props?.details?.responder_id && this.props.details.responder_id != this.props.details.id && (
          <Row className="pb-4 my-2 mx-4">
            The reporting responsibility for this monitoree is handled by another monitoree.&nbsp;
            <a href={'/patients/' + this.props.details.responder_id}>Click here to view that monitoree</a>.
          </Row>
        )}
        <Row className="g-border-bottom-2 pb-4 my-2 mx-2">
          <Col md="11">
            <Row>
              <Col>
                <div className="float-left">
                  <h5>
                    <u>Identification</u>:{' '}
                    {`${this.props.details.first_name ? this.props.details.first_name : ''}${
                      this.props.details.middle_name ? ' ' + this.props.details.middle_name : ''
                    }${this.props.details.last_name ? ' ' + this.props.details.last_name : ''}`}
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
                <span className="font-weight-normal">DOB:</span>{' '}
                <span className="font-weight-light">{this.props.details.date_of_birth && `${this.props.details.date_of_birth}`}</span>
                <br />
                <span className="font-weight-normal">Age:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.age ? this.props.details.age : ''}`}</span>
                <br />
                <span className="font-weight-normal">Language:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.primary_language ? this.props.details.primary_language : ''}`}</span>
                <br />
                <span className="font-weight-normal">State/Local ID:</span>{' '}
                <span className="font-weight-light">{`${
                  this.props.details.user_defined_id_statelocal ? this.props.details.user_defined_id_statelocal : ''
                }`}</span>
                <br />
                <span className="font-weight-normal">CDC ID:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.user_defined_id_cdc ? this.props.details.user_defined_id_cdc : ''}`}</span>
                <br />
                <span className="font-weight-normal">NNDSS ID:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.user_defined_id_nndss ? this.props.details.user_defined_id_nndss : ''}`}</span>
              </Col>
              <Col className="text-truncate">
                <span className="font-weight-normal">Sex:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.sex ? this.props.details.sex : ''}`}</span>
                <br />
                <span className="font-weight-normal">Race:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.white ? 'White' : ''}${
                  this.props.details.black_or_african_american ? ' Black or African American' : ''
                }${this.props.details.asian ? ' Asian' : ''}${this.props.details.american_indian_or_alaska_native ? ' American Indian or Alaska Native' : ''}${
                  this.props.details.native_hawaiian_or_other_pacific_islander ? ' Native Hawaiian or Other Pacific Islander' : ''
                }`}</span>
                <br />
                <span className="font-weight-normal">Ethnicity:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.ethnicity ? this.props.details.ethnicity : ''}`}</span>
                <br />
                <span className="font-weight-normal">Nationality:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.nationality ? this.props.details.nationality : ''}`}</span>
                <br />
              </Col>
            </Row>
            {/* TODO: This should be adjusted when we start setting the jurisdiction during the enrollment process */}
            {this.props.details.jurisdiction_path && (
              <Row className="mt-4">
                <Col>
                  <span className="font-weight-normal">Monitoring Jurisdiction:</span>{' '}
                  <span className="font-weight-light">{`${this.props.details.jurisdiction_path.join(', ')}`}</span>
                </Col>
              </Row>
            )}
          </Col>
          <Col md="1"></Col>
          <Col md="11">
            <Row>
              <Col>
                <div className="float-left">
                  <h5>
                    <u>Address</u>
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
                <span className="font-weight-light">
                  {this.props.details.address_line_1 && `${this.props.details.address_line_1}`}
                  {this.props.details.address_line_2 && ` ${this.props.details.address_line_2}`}
                  {this.props.details.foreign_address_line_1 && `${this.props.details.foreign_address_line_1}`}
                  {this.props.details.foreign_address_line_2 && ` ${this.props.details.foreign_address_line_2}`}
                </span>
                <br />
                <span className="font-weight-light">
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
        </Row>
        <Row className="g-border-bottom-2 pb-4 mb-2 mt-4 mx-2">
          <Col md="11">
            <Row>
              <Col>
                <div className="float-left">
                  <h5>
                    <u>Contact Information</u>
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
                <span className="font-weight-normal">Phone:</span>{' '}
                <span className="font-weight-light">{this.props.details.primary_telephone && `${this.props.details.primary_telephone}`}</span>
                <br />
                <span className="font-weight-normal">Preferred Contact Time:</span>{' '}
                <span className="font-weight-light">{this.props.details.preferred_contact_time && `${this.props.details.preferred_contact_time}`}</span>
                <br />
                <span className="font-weight-normal">Type:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.primary_telephone_type ? this.props.details.primary_telephone_type : ''}`}</span>
                <br />
                <span className="font-weight-normal">Email:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.email ? this.props.details.email : ''}`}</span>
                <br />
                <span className="font-weight-normal">Preferred Contact:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.preferred_contact_method ? this.props.details.preferred_contact_method : ''}`}</span>
              </Col>
            </Row>
          </Col>
          <Col md="1"></Col>
          <Col md="11">
            <Row>
              <Col>
                <div className="float-left">
                  <h5>
                    <u>Arrival Information</u>
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
                <h6>DEPARTED</h6>
                <span className="font-weight-light">{this.props.details.port_of_origin && `${this.props.details.port_of_origin}`}</span>
                <br />
                <span className="font-weight-light">{`${this.props.details.date_of_departure ? this.props.details.date_of_departure : ''}`}</span>
              </Col>
              <Col className="text-truncate">
                <h6>ARRIVAL</h6>
                <span className="font-weight-light">{`${this.props.details.port_of_entry_into_usa ? this.props.details.port_of_entry_into_usa : ''}`}</span>
                <br />
                <span className="font-weight-light">{`${this.props.details.date_of_arrival ? this.props.details.date_of_arrival : ''}`}</span>
              </Col>
            </Row>
            <Row>
              <Col className="text-truncate pt-1">
                <span className="font-weight-light">{this.props.details.flight_or_vessel_carrier && `${this.props.details.flight_or_vessel_carrier}`}</span>
                <br />
                <span className="font-weight-light">{this.props.details.flight_or_vessel_number && `${this.props.details.flight_or_vessel_number}`}</span>
              </Col>
            </Row>
          </Col>
        </Row>
        <Row className="pb-2 mb-2 mt-4 mx-2">
          <Col md="11">
            <Row>
              <Col>
                <div className="float-left">
                  <h5>
                    <u>Additional Planned Travel</u>
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
                <span className="font-weight-normal">Type:</span>{' '}
                <span className="font-weight-light">
                  {this.props.details.additional_planned_travel_type && `${this.props.details.additional_planned_travel_type}`}
                </span>
                <br />
                <span className="font-weight-normal">Place:</span>{' '}
                <span className="font-weight-light">
                  {`${
                    this.props.details.additional_planned_travel_destination_country ? this.props.details.additional_planned_travel_destination_country : ''
                  }`}
                  {`${this.props.details.additional_planned_travel_destination_state ? this.props.details.additional_planned_travel_destination_state : ''}`}
                </span>
                <br />
                <span className="font-weight-normal">Port Of Departure:</span>{' '}
                <span className="font-weight-light">{`${
                  this.props.details.additional_planned_travel_port_of_departure ? this.props.details.additional_planned_travel_port_of_departure : ''
                }`}</span>
                <br />
                <span className="font-weight-normal">End Date:</span>{' '}
                <span className="font-weight-light">{`${
                  this.props.details.additional_planned_travel_start_date ? this.props.details.additional_planned_travel_start_date : ''
                }`}</span>
                <br />
                <span className="font-weight-normal">Start Date:</span>{' '}
                <span className="font-weight-light">{`${
                  this.props.details.additional_planned_travel_end_date ? this.props.details.additional_planned_travel_end_date : ''
                }`}</span>
              </Col>
            </Row>
          </Col>
          <Col md="1"></Col>
          <Col md="11">
            <Row>
              <Col>
                <div className="float-left">
                  <h5>
                    <u>Potential Exposure Information</u>
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
              <Col className="text-truncate">
                <h6>LAST EXPOSURE</h6>
                <span className="font-weight-light">
                  {`${this.props.details.potential_exposure_location ? this.props.details.potential_exposure_location : ''}`}
                  {`${this.props.details.potential_exposure_location ? <br /> : ''}`}
                  {`${this.props.details.potential_exposure_country ? ' ' + this.props.details.potential_exposure_country : ''}`}
                  {`${this.props.details.potential_exposure_country ? <br /> : ''}`}
                </span>
                <span className="font-weight-light">{`${this.props.details.last_date_of_exposure ? this.props.details.last_date_of_exposure : ''}`}</span>
                <br />
                <span className="font-weight-light text-danger">
                  {this.props.details.contact_of_known_case
                    ? 'CLOSE CONTACT WITH A KNOWN CASE: ' + (this.props.details.contact_of_known_case_id ? this.props.details.contact_of_known_case_id : '')
                    : ''}
                  {this.props.details.contact_of_known_case ? <br /> : ''}
                </span>
                <span className="font-weight-light text-danger">
                  {this.props.details.travel_to_affected_country_or_area ? 'TRAVEL TO AFFECTED COUNTRY OR AREA' : ''}
                  {this.props.details.travel_to_affected_country_or_area ? <br /> : ''}
                </span>
                <span className="font-weight-light text-danger">
                  {this.props.details.was_in_health_care_facility_with_known_cases ? 'WAS IN HEALTH CARE FACILITY WITH KNOWN CASES' : ''}
                  {this.props.details.was_in_health_care_facility_with_known_cases ? <br /> : ''}
                </span>
                <span className="font-weight-light text-danger">
                  {this.props.details.laboratory_personnel ? 'LABORATORY PERSONNEL' : ''}
                  {this.props.details.laboratory_personnel ? <br /> : ''}
                </span>
                <span className="font-weight-light text-danger">
                  {this.props.details.healthcare_personnel ? 'HEALTHCARE PERSONNEL' : ''}
                  {this.props.details.healthcare_personnel ? <br /> : ''}
                </span>
                <span className="font-weight-light text-danger">
                  {this.props.details.crew_on_passenger_or_cargo_flight ? 'CREW ON PASSENGER OR CARGO FLIGHT' : ''}
                  {this.props.details.crew_on_passenger_or_cargo_flight ? <br /> : ''}
                </span>
              </Col>
            </Row>
          </Col>
        </Row>
      </React.Fragment>
    );
  }
}

Patient.propTypes = {
  patient: PropTypes.object,
  details: PropTypes.object,
  goto: PropTypes.func,
};

export default Patient;
