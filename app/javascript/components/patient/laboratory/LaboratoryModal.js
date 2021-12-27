import React from 'react';
import { PropTypes } from 'prop-types';
import { Alert, Button, Col, Form, Modal, Row } from 'react-bootstrap';
import moment from 'moment';
import ReactTooltip from 'react-tooltip';

import DateInput from '../../util/DateInput';

class LaboratoryModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      lab_type: this.props.currentLabData?.lab_type || '',
      specimen_collection: this.props.currentLabData?.specimen_collection,
      report: this.props.currentLabData?.report,
      result: this.props.currentLabData?.result || (this.props.onlyPositiveResult ? 'positive' : ''),
      reportInvalid: false,
    };
  }

  handleChange = event => {
    this.setState({ [event.target.id]: event.target.value }, this.clearSymptomOnset);
  };

  handleDateChange = (field, date) => {
    this.setState({ [field]: date }, () => {
      this.setState(state => {
        return {
          reportInvalid: state.report && state.specimen_collection && moment(state.report).isBefore(state.specimen_collection, 'day'),
        };
      }, this.clearSymptomOnset);
    });
  };

  // Clear symptom onset if user decides to undo changes
  clearSymptomOnset = () => {
    if (this.state.result == 'positive' && this.state.specimen_collection != null) {
      this.setState({ symptom_onset: null });
    }
  };

  submit = () => {
    this.props.onSave(
      {
        lab_type: this.state.lab_type,
        specimen_collection: this.state.specimen_collection,
        report: this.state.report,
        result: this.state.result,
      },
      this.state.symptom_onset
    );
  };

  render() {
    // Data is valid as long as at least one field has a value
    const isValid = this.props.onlyPositiveResult
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
                <Form.Label className="input-label">Lab Test Type</Form.Label>
                <Form.Control as="select" className="form-control-lg" onChange={this.handleChange} value={this.state.lab_type}>
                  <option></option>
                  <option>PCR</option>
                  <option>Antigen</option>
                  <option>Total Antibody</option>
                  <option>IgG Antibody</option>
                  <option>IgM Antibody</option>
                  <option>IgA Antibody</option>
                  <option>Other</option>
                </Form.Control>
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label htmlFor="specimen_collection" className="input-label">
                  Specimen Collection Date {this.props.specimenCollectionRequired && '*'}
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
                />
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label htmlFor="report" className="input-label">
                  Report Date
                </Form.Label>
                <DateInput
                  id="report"
                  date={this.state.report}
                  minDate={'2020-01-01'}
                  maxDate={moment().format('YYYY-MM-DD')}
                  onChange={date => this.handleDateChange('report', date)}
                  isClearable
                  placement="bottom"
                  isInvalid={this.state.reportInvalid}
                  customClass="form-control-lg"
                  ariaLabel="Report Date Input"
                />
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.reportInvalid && <span>Report Date cannot be before Specimen Collection Date.</span>}
                </Form.Control.Feedback>
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col} controlId="result">
                <Form.Label className="input-label">Result {this.props.onlyPositiveResult && '*'}</Form.Label>
                <Form.Control as="select" className="form-control-lg" onChange={this.handleChange} value={this.state.result}>
                  {this.props.onlyPositiveResult ? (
                    <option>positive</option>
                  ) : (
                    <React.Fragment>
                      <option></option>
                      <option>positive</option>
                      <option>negative</option>
                      <option>indeterminate</option>
                      <option>other</option>
                    </React.Fragment>
                  )}
                </Form.Control>
              </Form.Group>
            </Row>
            {this.props.editMode &&
              this.props.isolation &&
              this.props.only_positive_lab &&
              (this.state.result !== 'positive' || this.state.specimen_collection == null) && (
                <div>
                  <Alert variant="warning" className="mt-2 mb-3 alert-warning-text">
                    Warning: Since this record does not have a Symptom Onset Date, updating this lab from a positive result or clearing the Specimen Collection
                    Date may result in the record not ever being eligible to appear on the Records Requiring Review line list. Please consider undoing these
                    changes or entering a Symptom Onset Date:
                  </Alert>
                  <Form.Label className="input-label">SYMPTOM ONSET</Form.Label>
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
            <Button variant="primary btn-square" disabled={this.props.loading || this.state.reportInvalid || !isValid} onClick={this.submit}>
              {this.props.editMode ? 'Update' : 'Create'}
            </Button>
          </span>
          {/* Typically we pair the ReactTooltip up directly next to the mount point. However, due to the disabled attribute on the button */}
          {/* above, this Tooltip should be placed outside the parent component (to prevent unwanted parent opacity settings from being inherited) */}
          {/* This does not impact component functionality at all. */}
          {!isValid && (
            <ReactTooltip id="submit-tooltip" place="top" type="dark" effect="solid" multiline={this.props.onlyPositiveResult}>
              {this.props.onlyPositiveResult ? 'Please enter specimen collection date.' : 'Please enter at least one field.'}
            </ReactTooltip>
          )}
        </Modal.Footer>
      </Modal>
    );
  }
}

LaboratoryModal.propTypes = {
  currentLabData: PropTypes.object,
  specimenCollectionRequired: PropTypes.bool,
  onlyPositiveResult: PropTypes.bool,
  onSave: PropTypes.func,
  onClose: PropTypes.func,
  editMode: PropTypes.bool,
  loading: PropTypes.bool,
  only_positive_lab: PropTypes.bool,
  isolation: PropTypes.bool,
};

export default LaboratoryModal;
