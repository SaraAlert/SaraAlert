import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Col, Form, Modal, Row } from 'react-bootstrap';
import moment from 'moment';

import DateInput from '../util/DateInput';

class LaboratoryForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      lab_type: this.props.lab?.lab_type || '',
      specimen_collection: this.props.lab?.specimen_collection,
      report: this.props.lab?.report,
      result: this.props.lab?.result || (this.props.onlyPositiveResult ? 'positive' : ''),
      reportInvalid: false,
    };
  }

  handleChange = event => {
    this.setState({ [event.target.id]: event.target.value });
  };

  handleDateChange = (field, date) => {
    this.setState({ [field]: date }, () => {
      this.setState(state => {
        return {
          reportInvalid: moment(state.report).isBefore(state.specimen_collection, 'day'),
        };
      });
    });
  };

  submit = () => {
    this.props.submit({
      lab_type: this.state.lab_type,
      specimen_collection: this.state.specimen_collection,
      report: this.state.report,
      result: this.state.result,
    });
  };

  render() {
    return (
      <Modal size="lg" show centered onHide={this.props.cancel}>
        <h1 className="sr-only">Lab Result</h1>
        <Modal.Header>
          <Modal.Title>Lab Result</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Form.Group as={Col} controlId="lab_type">
                <Form.Label className="nav-input-label">Lab Test Type</Form.Label>
                <Form.Control as="select" className="form-control-lg" onChange={this.handleChange} value={this.state.lab_type}>
                  <option disabled></option>
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
                <Form.Label htmlFor="specimen_collection" className="nav-input-label">
                  Specimen Collection Date
                </Form.Label>
                <DateInput
                  id="specimen_collection"
                  date={this.state.specimen_collection}
                  minDate={'2020-01-01'}
                  maxDate={moment().format('YYYY-MM-DD')}
                  onChange={date => this.handleDateChange('specimen_collection', date)}
                  placement="bottom"
                  customClass="form-control-lg"
                  ariaLabel="Specimen Collection Date Input"
                />
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label htmlFor="report" className="nav-input-label">
                  Report Date
                </Form.Label>
                <DateInput
                  id="report"
                  date={this.state.report}
                  minDate={'2020-01-01'}
                  maxDate={moment().format('YYYY-MM-DD')}
                  onChange={date => this.handleDateChange('report', date)}
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
                <Form.Label className="nav-input-label">Result</Form.Label>
                <Form.Control as="select" className="form-control-lg" onChange={this.handleChange} value={this.state.result}>
                  {this.props.onlyPositiveResult ? (
                    <option>positive</option>
                  ) : (
                    <React.Fragment>
                      <option disabled></option>
                      <option>positive</option>
                      <option>negative</option>
                      <option>indeterminate</option>
                      <option>other</option>
                    </React.Fragment>
                  )}
                </Form.Control>
              </Form.Group>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.cancel}>
            Cancel
          </Button>
          <Button variant="primary btn-square" disabled={this.props.loading || this.state.reportInvalid} onClick={this.submit}>
            {this.props.editMode ? 'Update' : 'Create'}
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

LaboratoryForm.propTypes = {
  lab: PropTypes.object,
  onlyPositiveResult: PropTypes.bool,
  submit: PropTypes.func,
  cancel: PropTypes.func,
  editMode: PropTypes.bool,
  loading: PropTypes.bool,
};

export default LaboratoryForm;
