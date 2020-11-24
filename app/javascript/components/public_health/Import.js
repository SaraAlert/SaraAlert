import React from 'react';
import { PropTypes } from 'prop-types';
import { Alert, Button, Card, Col, ProgressBar, Row } from 'react-bootstrap';
import axios from 'axios';
import moment from 'moment-timezone';
import confirmDialog from '../util/ConfirmDialog';
import reportError from '../util/ReportError';

class Import extends React.Component {
  constructor(props) {
    super(props);
    const patientsWithAge = this.props.patients.map(patient => {
      // If patient does not have `age`, we need to compute it
      if (!Object.prototype.hasOwnProperty.call(patient, 'age')) {
        if (patient.date_of_birth) {
          // if the `age` field is set, use that. Else calculate it based off DoB
          const age = patient['age'] ? patient['age'] : moment().diff(moment(patient.date_of_birth), 'years');
          patient['age'] = age >= 0 ? age : undefined;
        } else {
          patient['age'] = undefined;
        }
      }
      return patient;
    });
    this.state = {
      patients: patientsWithAge,
      errors: props.errors,
      accepted: [],
      rejected: [],
      phased: [],
      progress: 0,
      importDuplicates: false,
      isPaused: false,
      acceptedAllStarted: false,
    };
  }

  importAll = () => {
    let willCreate = [];
    for (let i = 0; i < this.state.patients.length; i++) {
      if (!(this.state.accepted.includes(i) || this.state.rejected.includes(i))) {
        let patient = this.state.patients[parseInt(i)];
        if (!patient.duplicate_data.is_duplicate || this.state.importDuplicates) {
          willCreate.push(patient);
        }
      }
    }
    if (willCreate.length > 0) {
      this.setState({ phased: willCreate }, () => {
        this.submit(this.state.phased[0], 0, true);
      });
    } else {
      // if there are no monitorees/cases to import, go back to root after pressing the import button
      location.reload();
    }
  };

  importSub = (num, bypass) => {
    this.submit(this.state.patients[parseInt(num)], num, bypass);
  };

  rejectSub = num => {
    let next = [...this.state.rejected, num];
    this.setState({ rejected: next });
  };

  submit = (data, num, bypass) => {
    const patientData = { ...data };
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios({
      method: 'post',
      url: window.BASE_PATH + '/patients',
      data: { patient: { ...patientData }, bypass_duplicate: bypass },
    })
      .then(() => {
        let next = [...this.state.accepted, num];
        this.setState({ accepted: next, progress: num }, () => {
          if (this.state.phased.length > num + 1) {
            if (!this.state.isPaused) {
              this.submit(this.state.phased[num + 1], num + 1, bypass);
            }
          } else if (this.state.phased.length != 0) {
            // if there are no monitorees/cases to import, and import wasn't done one at a time go back to root after pressing the import button
            location.reload();
          }
        });
      })
      .catch(err => {
        reportError(err);
      });
  };

  handleExtraOptionToggle = value => {
    this.setState({ importDuplicates: value });
  };

  stopImport = async buttonText => {
    this.setState({ isPaused: true }, async () => {
      const confirmText = 'You are about to stop the import process. Are you sure you want to do this?';
      const options = {
        title: 'Stop Import',
        okLabel: 'Proceed to Stop',
        cancelLabel: 'Continue to Import',
        additionalNote: `Records imported prior to clicking “${buttonText}” will not be deleted from the system.`,
      };
      if (await confirmDialog(confirmText, options)) {
        this.setState({ isPaused: false });
        location.href = this.props.workflow === 'exposure' ? '/public_health' : '/public_health/isolation';
      } else {
        this.setState({ isPaused: false });
        if (this.state.acceptedAllStarted) {
          this.submit(this.state.phased[this.state.progress + 1], this.state.progress + 1, true);
        }
      }
    });
  };

  handleConfirm = async confirmText => {
    this.setState({ acceptedAllStarted: true }, async () => {
      let duplicateCount = this.state.patients.filter(pat => pat.duplicate_data.is_duplicate).length;
      let duplicatePrompt =
        duplicateCount != 0 ? `Include the ${duplicateCount} potential duplicate ${this.props.workflow === 'exposure' ? 'monitorees' : 'cases'}` : undefined;
      if (
        await confirmDialog(confirmText, {
          title: this.props.workflow === 'exposure' ? 'Import Monitorees' : 'Import Cases',
          extraOption: duplicatePrompt,
          extraOptionChange: this.handleExtraOptionToggle,
        })
      ) {
        this.importAll();
      } else {
        this.setState({ acceptedAllStarted: false });
      }
    });
  };

  /**
   * Gets rendered warning text for when duplicates are detected.
   * @param {Object} dupFieldData - Data concerning the possible duplicates types and the specific fields in them.
   */
  getDuplicateWarningText = dupFieldData => {
    let text = `Warning: This ${this.props.workflow === 'exposure' ? 'monitoree' : 'case'} already appears to exist in the system! `;

    for (const fieldData of dupFieldData) {
      text += `There ${fieldData.count > 1 ? `are ${fieldData.count} records` : 'is 1 record'}  with matching values in the following field(s): `;
      let field;
      for (let i = 0; i < fieldData.fields.length; i++) {
        // parseInt() to satisfy eslint-security
        field = fieldData.fields[parseInt(i)];
        if (fieldData.fields.length > 1) {
          text += i == fieldData.fields.length - 1 ? `and ${field}. ` : `${field}, `;
        } else {
          text += `${field}. `;
        }
      }
    }

    return (
      <Alert variant="warning">
        <span>{text}</span>
      </Alert>
    );
  };

  render() {
    if (this.state.patients.length === this.state.accepted.length + this.state.rejected.length && this.state.errors.length == 0) {
      location.href = '/';
    }
    return (
      <React.Fragment>
        {this.state.errors.length != 0 && (
          <div className="mx-3 mt-1 mb-2">
            <h5>The following errors were found in your import file, please fix them and then try re-importing.</h5>
          </div>
        )}
        {this.state.errors.map((error, index) => {
          return (
            <Alert key={index} variant="danger" className="mt-3 mx-3">
              {error}
            </Alert>
          );
        })}
        {this.state.errors.length == 0 && (
          <div className="mx-3 mt-1 mb-2">
            <h5>
              {`Please review the ${this.props.workflow === 'exposure' ? 'monitoree' : 'case'} records that are about to be imported.
              You can individually accept or reject each record below.
              You can also choose to import all unique records or all records (including duplicates) by clicking the 'Import All' button.`}
            </h5>
            {this.state.acceptedAllStarted ? (
              <Button variant="primary" className="btn-lg mt-2" disabled={true}>
                <i className="fas fa-upload"></i> Import All
              </Button>
            ) : (
              <Button
                variant="primary"
                className="btn-lg mt-2"
                onClick={() =>
                  this.handleConfirm(
                    `This will import all records listed below that you did not manually accept or reject. If potential duplicates have been detected, check the box if you would like to import them.`
                  )
                }>
                <i className="fas fa-upload"></i> Import All
              </Button>
            )}

            {this.state.acceptedAllStarted && (
              <Button variant="danger" className="btn-lg mt-2 ml-2" onClick={() => this.stopImport('Stop Import')}>
                <i className="fas fa-hand-paper"></i> Stop Import
              </Button>
            )}
            {this.state.phased.length > 0 && (
              <ProgressBar animated striped className="my-3" now={Math.round((this.state.progress + 1 / this.state.phased.length) * 100)} />
            )}
            {this.state.patients.map((patient, index) => {
              return (
                <Card
                  body
                  key={`p-${index}`}
                  className="card-square mt-3"
                  bg="light"
                  border={this.state.accepted.includes(index) ? 'success' : this.state.rejected.includes(index) ? 'danger' : ''}>
                  <React.Fragment>
                    {patient.duplicate_data.is_duplicate && this.getDuplicateWarningText(patient.duplicate_data.duplicate_field_data)}
                    {(patient.jurisdiction_path || patient.assigned_user) && (
                      <Alert variant="info">
                        Note:
                        {patient.jurisdiction_path && (
                          <span>{` This ${this.props.workflow === 'exposure' ? 'monitoree' : 'case'} will be imported into '${
                            patient.jurisdiction_path
                          }'.`}</span>
                        )}
                        {patient.assigned_user && (
                          <span>{` This ${this.props.workflow === 'exposure' ? 'monitoree' : 'case'} will be assigned to user '${
                            patient.assigned_user
                          }'.`}</span>
                        )}
                      </Alert>
                    )}
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
                        <b>Close Contact w/ Known Case:</b> {patient.contact_of_known_case?.toString()}
                        <br />
                        <b>Was in HC Fac. w/ Known Cases:</b> {patient.was_in_health_care_facility_with_known_cases?.toString()}
                      </Col>
                    </Row>
                  </React.Fragment>
                  {!(this.state.accepted.includes(index) || this.state.rejected.includes(index)) && (
                    <React.Fragment>
                      <Button
                        variant="primary"
                        className="mt-2 ml-3 float-right"
                        onClick={() => {
                          this.importSub(index, true);
                        }}>
                        <i className="fas fa-check"></i> Accept
                      </Button>
                      <Button
                        variant="danger"
                        className="mt-2 float-right"
                        onClick={() => {
                          this.rejectSub(index);
                        }}>
                        <i className="fas fa-times"></i> Reject
                      </Button>
                    </React.Fragment>
                  )}
                </Card>
              );
            })}
          </div>
        )}
      </React.Fragment>
    );
  }
}

Import.propTypes = {
  workflow: PropTypes.string,
  patients: PropTypes.array,
  errors: PropTypes.array,
  authenticity_token: PropTypes.string,
};

export default Import;
