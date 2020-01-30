import React from "react"
import { Button, Col, Row } from 'react-bootstrap';

class Patient extends React.Component {

  constructor(props) {
    super(props);
  }

  render () {
    if (!!!this.props.details) {
      return (<React.Fragment></React.Fragment>);
    }
    return (
      <React.Fragment>
        <Row>
          <Col>
            <Row>
              <Col>
                <span className="font-weight-normal">DOB:</span> <span className="font-weight-light">{this.props.details.dob_day && this.props.details.dob_month && this.props.details.dob_year && `${this.props.details.dob_day}-${this.props.details.dob_month}-${this.props.details.dob_year}`}</span><br />
                <span className="font-weight-normal">Age:</span> <span className="font-weight-light">{`${this.props.details.age ? this.props.details.age : ''}`}</span><br />
                <span className="font-weight-normal">Language:</span> <span className="font-weight-light">{`${this.props.details.primary_language ? this.props.details.primary_language : ''}`}</span>
              </Col>
              <Col>
                <span className="font-weight-normal">Sex:</span> <span className="font-weight-light">{`${this.props.details.sex ? this.props.details.sex : ''}`}</span><br />
                <span className="font-weight-normal">Race:</span> <span className="font-weight-light">{`${this.props.details.white ? 'White' : ''}${this.props.details.black_or_african_american ? ' Black or African American' : ''}${this.props.details.asian ? ' Asian' : ''}${this.props.details.american_indian_or_alaska_native ? ' American Indian or Alaska Native' : ''}${this.props.details.native_hawaiian_or_other_pacific_islander ? ' Native Hawaiian or Other Pacific Islander' : ''}`}</span><br />
                <span className="font-weight-normal">Ethnicity:</span> <span className="font-weight-light">{`${this.props.details.ethnicity ? this.props.details.ethnicity : ''}`}</span>
              </Col>
            </Row>
          </Col>
          <Col>
            <Row>
              <Col>
              </Col>
              <Col>
              </Col>
            </Row>
          </Col>
        </Row>
        <Row>
          <Col></Col>
          <Col></Col>
        </Row>
      </React.Fragment>
    );
  }
}

export default Patient
