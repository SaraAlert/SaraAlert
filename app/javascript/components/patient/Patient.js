import React from 'react';
import { PropTypes } from 'prop-types';
import { Col, Row, Button, Collapse, Card } from 'react-bootstrap';
import moment from 'moment';

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
        {this.props.jurisdiction_path && (
          <Row id="jurisdiction-path" className="mx-1">
            <Col className="text-truncate">
              <span className="font-weight-normal">Assigned Jurisdiction:</span> <span className="font-weight-light">{this.props.jurisdiction_path}</span>
            </Col>
          </Row>
        )}
        {this.props.details.assigned_user && (
          <Row id="assigned-user" className="mx-1">
            <Col className="text-truncate">
              <span className="font-weight-normal">Assigned User:</span> <span className="font-weight-light">{this.props.details.assigned_user}</span>
            </Col>
          </Row>
        )}
        <Row className="pt-4 mx-1 mb-4">
          <Col id="identification" md="11">
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
                <span className="font-weight-light">
                  {this.props.details.date_of_birth && `${moment(this.props.details.date_of_birth, 'YYYY-MM-DD').format('MM/DD/YYYY')}`}
                </span>
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
                <span className="font-weight-normal">Birth Sex:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.sex ? this.props.details.sex : ''}`}</span>
                <br />
                <span className="font-weight-normal">Gender Identity:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.gender_identity ? this.props.details.gender_identity : ''}`}</span>
                <br />
                <span className="font-weight-normal">Sexual Orientation:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.sexual_orientation ? this.props.details.sexual_orientation : ''}`}</span>
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
          </Col>
          <Col md="2"></Col>
          <Col id="contact-information" md="11">
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
                <span className="font-weight-light">
                  {this.props.details.primary_telephone && `${this.formatPhoneNumber(this.props.details.primary_telephone)}`}
                </span>
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
                <span className="font-weight-normal">Preferred Reporting Method:</span>{' '}
                <span className="font-weight-light">{`${this.props.details.preferred_contact_method ? this.props.details.preferred_contact_method : ''}`}</span>
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
              <Col md="13"></Col>
            </Row>
          </Card.Body>
        </Collapse>
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
