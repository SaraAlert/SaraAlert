import React from 'react';
import { Button, Card, Row, Col, Alert } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import confirmDialog from '../util/ConfirmDialog';
import reportError from '../util/ReportError';

class Import extends React.Component {
  constructor(props) {
    super(props);
    this.state = { patients: props.patients, accepted: [], rejected: [], phased: [] };
    this.importAll = this.importAll.bind(this);
    this.importSub = this.importSub.bind(this);
    this.rejectSub = this.rejectSub.bind(this);
    this.handleConfirm = this.handleConfirm.bind(this);
    this.submit = this.submit.bind(this);
  }

  importAll() {
    let willCreate = [];
    for (let i = 0; i < this.state.patients.length; i++) {
      if (!(this.state.accepted.includes(i) || this.state.rejected.includes(i))) {
        willCreate.push(i);
      }
    }
    this.setState({ phased: willCreate });
    this.submit(this.state.phased[0], 0, true);
  }

  importSub(num, bypass) {
    this.submit(this.state.patients[parseInt(num)], num, bypass);
  }

  rejectSub(num) {
    let next = [...this.state.rejected, num];
    this.setState({ rejected: next });
  }

  submit(data, num, bypass) {
    const patient = { patient: { ...data } };
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios({
      method: 'post',
      url: window.BASE_PATH + '/patients',
      data: { ...patient, bypass_duplicate: bypass },
    })
      .then(() => {
        let next = [...this.state.accepted, num];
        this.setState({ accepted: next }, () => {
          if (this.state.phased.length > next + 1) {
            this.submit(this.state.phased[next + 1], next + 1, bypass);
          }
        });
      })
      .catch(err => {
        reportError(err);
      });
  }

  handleConfirm = async confirmText => {
    if (await confirmDialog(confirmText)) {
      this.importAll();
    }
  };

  render() {
    if (this.state.patients.length === this.state.accepted.length + this.state.rejected.length) {
      location.href = '/';
    }
    return (
      <React.Fragment>
        <div className="m-4">
          {this.state.phased.length > 0 && <h5>Saving...</h5>}
          <h5>Please review the monitorees that are about to be imported below. You can individually accept each monitoree, or accept all at once.</h5>
          <Button
            variant="primary"
            className="btn-lg my-2"
            onClick={() =>
              this.handleConfirm(
                'Are you sure you want to import all monitorees? Note: This will not import already rejected or re-import already accepted monitorees listed below, but will import any potential duplicates.'
              )
            }>
            Accept All
          </Button>
          {this.state.patients.map((patient, index) => {
            return (
              <Card
                body
                key={`p-${index}`}
                className="card-square mt-3"
                bg="light"
                border={this.state.accepted.includes(index) ? 'success' : this.state.rejected.includes(index) ? 'danger' : ''}>
                <React.Fragment>
                  {patient.appears_to_be_duplicate && <Alert variant="danger">Warning: This monitoree already appears to exist in the system!</Alert>}
                  <Row>
                    <Col>
                      <b>State/Local ID:</b> {patient.user_defined_id_statelocal}
                      <br />
                      <b>CDC ID:</b> {patient.user_defined_id_cdc}
                      <br />
                      <b>First Name:</b> {patient.first_name}
                      <br />
                      <b>Last Name:</b> {patient.last_name}
                      <br />
                      <b>DOB:</b> {patient.date_of_birth}
                      <br />
                      <b>Language:</b> {patient.primary_language}
                      <br />
                      <b>Flight or Vessel Number:</b> {patient.flight_or_vessel_number}
                    </Col>
                    <Col>
                      <b>Home Address Line 1:</b> {patient.address_line_1}
                      <br />
                      <b>Home Town/City:</b> {patient.address_city}
                      <br />
                      <b>Home State:</b> {patient.address_state}
                      <br />
                      <b>Home Zip:</b> {patient.address_zip}
                      <br />
                      <b>Monitored Address Line 1:</b> {patient.monitored_address_line_1}
                      <br />
                      <b>Monitored Town/City:</b> {patient.monitored_address_city}
                      <br />
                      <b>Monitored State:</b> {patient.monitored_address_state}
                      <br />
                      <b>Monitored Zip:</b> {patient.monitored_address_zip}
                    </Col>
                    <Col>
                      <b>Phone Number 1:</b> {patient.primary_telephone}
                      <br />
                      <b>Phone Number 2:</b> {patient.secondary_telephone}
                      <br />
                      <b>Email:</b> {patient.email}
                      <br />
                      <b>Exposure Location:</b> {patient.potential_exposure_location}
                      <br />
                      <b>Date of Departure:</b> {patient.date_of_departure}
                      <br />
                      <b>Close Contact w/ Known Case:</b> {patient.contact_of_known_case}
                      <br />
                      <b>Was in HC Fac. w/ Known Cases:</b> {patient.was_in_health_care_facility_with_known_cases}
                    </Col>
                  </Row>
                </React.Fragment>
                {!(this.state.accepted.includes(index) || this.state.rejected.includes(index)) && (
                  <React.Fragment>
                    <Button
                      variant="danger"
                      className="my-2 ml-3 float-right"
                      onClick={() => {
                        this.rejectSub(index);
                      }}>
                      Reject
                    </Button>
                    <Button
                      variant="primary"
                      className="my-2 float-right"
                      onClick={() => {
                        this.importSub(index, true);
                      }}>
                      Accept
                    </Button>
                  </React.Fragment>
                )}
              </Card>
            );
          })}
        </div>
      </React.Fragment>
    );
  }
}

Import.propTypes = {
  patients: PropTypes.array,
  authenticity_token: PropTypes.string,
};

export default Import;
