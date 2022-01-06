import React from 'react';
import { PropTypes } from 'prop-types';
import { Alert, Button, Col, Form, Modal, Row } from 'react-bootstrap';
import moment from 'moment';
import ReactTooltip from 'react-tooltip';
import * as yup from 'yup';
import _ from 'lodash';
import DateInput from '../../util/DateInput';

class LaboratoryModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      lab_type: this.props.currentLabData?.lab_type || '',
      specimen_collection: this.props.currentLabData?.specimen_collection,
      report: this.props.currentLabData?.report,
      result: this.props.currentLabData?.result || (this.props.firstPositiveLab ? 'positive' : ''),
      symptom_onset: null,
      loading: false,
      errors: {},
    };
    this.updateValidations();
  }

  updateValidations() {
    let reportDate = '2020-01-01';
    let reportMessage = 'Report Date must fall after January 1, 2020.';
    if (this.state.report && this.state.specimen_collection) {
      // if both dates are set, ensure the report date falls after the specimen collection date
      reportDate = this.state.specimen_collection;
      reportMessage = 'Report Date cannot be before Specimen Collection Date.';
    }

    if (this.props.firstPositiveLab) {
      schema = yup.object().shape({
        lab_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
        specimen_collection: yup
          .date('Date must correspond to the "mm/dd/yyyy" format.')
          .required('Please enter Specimen Collection Date.')
          .min(moment('2020-01-01'), 'Specimen Collection Date must fall after January 1, 2020.')
          .max(moment(), 'Specimen Collection Date can not be in the future.')
          .nullable(),
        report: yup
          .date('Date must correspond to the "mm/dd/yyyy" format.')
          .min(moment(reportDate), reportMessage)
          .max(moment(), 'Report Date can not be in the future.')
          .nullable(),
        result: yup.string().required('Please select a lab result.').max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
      });
    } else {
      schema = yup.object().shape({
        lab_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
        specimen_collection: yup
          .date('Date must correspond to the "mm/dd/yyyy" format.')
          .min(moment('2020-01-01'), 'Specimen Collection Date must fall after January 1, 2020.')
          .max(moment(), 'Specimen Collection Date can not be in the future.')
          .nullable(),
        report: yup
          .date('Date must correspond to the "mm/dd/yyyy" format.')
          .min(moment(reportDate), reportMessage)
          .max(moment(), 'Report Date can not be in the future.')
          .nullable(),
        result: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
      });
    }
  }

  handleChange = event => {
    this.setState({ [event.target.id]: event.target.value }, () => {
      this.updateValidations();
      this.clearSymptomOnset();
    });
  };

  handleDateChange = (field, date) => {
    this.setState({ [field]: date }, () => {
      this.updateValidations();
      this.clearSymptomOnset();
    });
  };

  /**
   * Clear symptom onset if user decides to undo changes
   */
  clearSymptomOnset = () => {
    if (this.state.result === 'positive' && !_.isNil(this.state.specimen_collection)) {
      this.setState({ symptom_onset: null });
    }
  };

  /**
   * Validates close contact data and submits if valid, otherwise displays errors in modal
   */
  submit = () => {
    schema
      .validate({ ...this.state }, { abortEarly: false })
      .then(() => {
        this.setState({ loading: true }, () => {
          this.props.onSave(
            {
              lab_type: this.state.lab_type,
              specimen_collection: this.state.specimen_collection,
              report: this.state.report,
              result: this.state.result,
            },
            this.state.symptom_onset
          );
        });
      })
      .catch(err => {
        // Validation errors, update state to display to user
        if (err && err.inner) {
          let issues = {};
          for (const issue of err.inner) {
            issues[issue['path']] = issue['errors'];
          }
          this.setState({ errors: issues });
        }
      });
  };

  render() {
    // Data is valid as long as at least one field has a value
    const isValid = this.props.firstPositiveLab
      ? this.state.result && this.state.specimen_collection
      : this.state.lab_type || this.state.specimen_collection || this.state.report || this.state.result;

    return (
      <Modal size="lg" className="laboratory-modal-container" show centered onHide={this.props.onClose}>
        <h1 className="sr-only">{this.props.editMode ? 'Edit' : 'Add New'} Lab Result</h1>
        <Modal.Header>
          <Modal.Title>{this.props.editMode ? 'Edit' : 'Add New'} Lab Result</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Form.Group as={Col} controlId="lab_type">
                <Form.Label className="input-label">Lab Test Type{schema?.fields?.lab_type?._exclusive?.required && '*'}</Form.Label>
                <Form.Control
                  as="select"
                  className="form-control-lg"
                  onChange={this.handleChange}
                  value={this.state.lab_type}
                  isInvalid={!!this.state.errors['lab_type']}>
                  <option></option>
                  <option>PCR</option>
                  <option>Antigen</option>
                  <option>Total Antibody</option>
                  <option>IgG Antibody</option>
                  <option>IgM Antibody</option>
                  <option>IgA Antibody</option>
                  <option>Other</option>
                </Form.Control>
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['lab_type']}
                </Form.Control.Feedback>
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label htmlFor="specimen_collection" className="input-label">
                  Specimen Collection Date{schema?.fields?.specimen_collection?._exclusive?.required && '*'}
                </Form.Label>
                <DateInput
                  id="specimen_collection"
                  date={this.state.specimen_collection}
                  minDate={'2020-01-01'}
                  maxDate={moment().format('YYYY-MM-DD')}
                  onChange={date => this.handleDateChange('specimen_collection', date)}
                  isClearable
                  placement="bottom"
                  customClass="form-control-lg"
                  ariaLabel="Specimen Collection Date Input"
                  isInvalid={!!this.state.errors['specimen_collection']}
                />
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['specimen_collection']}
                </Form.Control.Feedback>
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label htmlFor="report" className="input-label">
                  Report Date{schema?.fields?.report?._exclusive?.required && '*'}
                </Form.Label>
                <DateInput
                  id="report"
                  date={this.state.report}
                  minDate={'2020-01-01'}
                  maxDate={moment().format('YYYY-MM-DD')}
                  onChange={date => this.handleDateChange('report', date)}
                  isClearable
                  placement="bottom"
                  customClass="form-control-lg"
                  ariaLabel="Report Date Input"
                  isInvalid={!!this.state.errors['report']}
                />
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['report']}
                </Form.Control.Feedback>
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col} controlId="result">
                <Form.Label className="input-label">Result{schema?.fields?.result?._exclusive?.required && '*'}</Form.Label>
                <Form.Control
                  as="select"
                  className="form-control-lg"
                  onChange={this.handleChange}
                  value={this.state.result}
                  disabled={this.props.firstPositiveLab}
                  isInvalid={!!this.state.errors['result']}>
                  <option></option>
                  <option>positive</option>
                  <option>negative</option>
                  <option>indeterminate</option>
                  <option>other</option>
                </Form.Control>
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['result']}
                </Form.Control.Feedback>
              </Form.Group>
            </Row>
            {this.props.editMode &&
              this.props.isolation &&
              this.props.only_positive_lab &&
              (this.state.result !== 'positive' || this.state.specimen_collection === null) && (
                <div className="symptom-onset-warning">
                  <Alert variant="warning" className="alert-warning-textmt-2 mb-3">
                    <b>Warning:</b> Since this record does not have a Symptom Onset Date, updating this lab from a positive result or clearing the Specimen
                    Collection Date may result in the record not ever being eligible to appear on the Records Requiring Review line list. Please consider
                    undoing these changes or entering a Symptom Onset Date:
                  </Alert>
                  <Form.Label htmlFor="symptom_onset_lab" className="input-label">
                    Symptom Onset
                  </Form.Label>
                  <DateInput
                    id="symptom_onset_lab"
                    date={this.state.symptom_onset}
                    minDate={'2020-01-01'}
                    maxDate={moment().format('YYYY-MM-DD')}
                    onChange={date => this.setState({ symptom_onset: date })}
                    isClearable={true}
                    placement="bottom"
                    customClass="form-control-lg"
                    ariaLabel="Symptom Onset Date Input"
                  />
                </div>
              )}
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.onClose}>
            Cancel
          </Button>
          <span data-for="submit-tooltip" data-tip="" className="ml-1">
            <Button variant="primary btn-square" disabled={this.state.loading || !isValid} onClick={this.submit}>
              {this.props.editMode ? 'Update' : 'Create'}
            </Button>
          </span>
          {/* Typically we pair the ReactTooltip up directly next to the mount point. However, due to the disabled attribute on the button */}
          {/* above, this Tooltip should be placed outside the parent component (to prevent unwanted parent opacity settings from being inherited) */}
          {/* This does not impact component functionality at all. */}
          {!isValid && (
            <ReactTooltip id="submit-tooltip" place="top" type="dark" effect="solid" multiline={this.props.firstPositiveLab}>
              <span>{this.props.firstPositiveLab ? 'Please enter Specimen Collection Date.' : 'Please enter at least one field.'}</span>
            </ReactTooltip>
          )}
        </Modal.Footer>
      </Modal>
    );
  }
}

var schema = yup.object().shape({
  lab_type: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  specimen_collection: yup
    .date('Date must correspond to the "mm/dd/yyyy" format.')
    .min(moment('2020-01-01'), 'Specimen Collection Date must fall after January 1, 2020.')
    .max(moment(), 'Specimen Collection Date can not be in the future.')
    .nullable(),
  report: yup
    .date('Date must correspond to the "mm/dd/yyyy" format.')
    .min(moment('2020-01-01'), 'Report Date must fall after January 1, 2020.')
    .max(moment(), 'Report Date can not be in the future.')
    .nullable(),
  result: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
});

LaboratoryModal.propTypes = {
  currentLabData: PropTypes.object,
  firstPositiveLab: PropTypes.bool,
  onSave: PropTypes.func,
  onClose: PropTypes.func,
  editMode: PropTypes.bool,
  loading: PropTypes.bool,
  only_positive_lab: PropTypes.bool,
  isolation: PropTypes.bool,
};

export default LaboratoryModal;
