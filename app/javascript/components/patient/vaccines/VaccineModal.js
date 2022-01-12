import React from 'react';
import PropTypes from 'prop-types';
import { Button, Modal, Row, Col, Form } from 'react-bootstrap';
import moment from 'moment';
import * as yup from 'yup';
import ReactTooltip from 'react-tooltip';
import Select from 'react-select';
import { bootstrapSelectTheme, vaccineModalSelectStyling } from '../../../packs/stylesheets/ReactSelectStyling';
import DateInput from '../../util/DateInput';

const MAX_NOTES_LENGTH = 2000;

class VaccineModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      product_name: this.props.currentVaccineData?.product_name,
      // If there is not already a group name, default to the first option
      group_name: this.props.currentVaccineData?.group_name
        ? this.props.currentVaccineData.group_name
        : this.props.group_name_options
        ? this.props.group_name_options[0]
        : null,
      administration_date: this.props.currentVaccineData?.administration_date,
      dose_number: this.props.currentVaccineData?.dose_number,
      notes: this.props.currentVaccineData?.notes || '',
      // Sorting so that the blank option shows up at the top
      sorted_dose_number_options: this.props.dose_number_options ? this.props.dose_number_options.sort() : [],
      loading: false,
      errors: {},
    };
  }

  handleProductNameChange = data => {
    this.setState({ product_name: data.value });
  };

  handleGroupNameChange = data => {
    // Resets product name if selected because product name options are dependent on group name
    this.setState({ group_name: data.value, product_name: null });
  };

  handleAdministrationDateChange = newDate => {
    this.setState({ administration_date: newDate });
  };

  handleDoseNumberChange = data => {
    this.setState({ dose_number: data.value });
  };

  handleNotesChange = event => {
    const val = event.target.value;
    this.setState({ notes: val });
  };

  /**
   * Gets the list of product name options based on the currently selected vaccine group.
   * Appends the additional product name options that are available no matter the group.
   */
  getProductNameOptions = () => {
    const product_names = this.props.vaccine_mapping ? this.props.vaccine_mapping[this.state.group_name]?.vaccines?.map(vaccine => vaccine.product_name) : [];
    return product_names ? product_names.concat(this.props.additional_product_name_options) : [];
  };

  /**
   * Takes it an array of dropdown options and formats them as React Select requires.
   * @param {String[]} options
   */
  getDropdownOptions = options => {
    const formattedOptions = options?.map(option => {
      return { label: option, value: option };
    });
    return formattedOptions;
  };

  /**
   * Validates vaccine data and submits if valid, otherwise displays errors in modal
   */
  submit = () => {
    schema
      .validate({ ...this.state }, { abortEarly: false })
      .then(() => {
        this.setState({ loading: true }, () => {
          this.props.onSave({
            product_name: this.state.product_name,
            group_name: this.state.group_name,
            administration_date: this.state.administration_date,
            dose_number: this.state.dose_number,
            notes: this.state.notes,
          });
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
    const defaultGroupNameOption = this.props.group_name_options ? this.props.group_name_options[0] : '';

    // Data is valid and can be saved if there is both a group name and product name selected.
    const isValid = this.state.group_name && this.state.product_name;

    return (
      <Modal size="lg" show centered onHide={this.props.onClose}>
        <h1 className="sr-only">{this.props.editMode ? 'Edit' : 'Add New'} Vaccination</h1>
        <Modal.Header>
          <Modal.Title>{this.props.editMode ? 'Edit' : 'Add New'} Vaccination</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Form.Group as={Col}>
                <Form.Label htmlFor="group-name-select" className="input-label">
                  Vaccine Group{schema?.fields?.group_name?._exclusive?.required && '*'}
                </Form.Label>
                <Select
                  inputId="group-name-select"
                  name="group_name"
                  defaultValue={
                    this.props.currentVaccineData?.group_name
                      ? { label: this.props.currentVaccineData.group_name, value: this.props.currentVaccineData.group_name }
                      : { label: defaultGroupNameOption, value: defaultGroupNameOption }
                  }
                  value={{ label: this.state.group_name, value: this.state.group_name }}
                  options={this.getDropdownOptions(this.props.group_name_options)}
                  onChange={this.handleGroupNameChange}
                  placeholder=""
                  theme={bootstrapSelectTheme}
                  styles={vaccineModalSelectStyling}
                />
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['group_name']}
                </Form.Control.Feedback>
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label htmlFor="product-name-select" className="input-label">
                  Product Name{schema?.fields?.product_name?._exclusive?.required && '*'}
                </Form.Label>
                <Select
                  inputId="product-name-select"
                  name="product_name"
                  defaultValue={
                    this.props.currentVaccineData?.product_name
                      ? { label: this.props.currentVaccineData.product_name, value: this.props.currentVaccineData.product_name }
                      : ''
                  }
                  value={this.state.product_name ? { label: this.state.product_name, value: this.state.product_name } : ''}
                  options={this.getDropdownOptions(this.getProductNameOptions())}
                  onChange={this.handleProductNameChange}
                  placeholder=""
                  theme={bootstrapSelectTheme}
                  styles={vaccineModalSelectStyling}
                />
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['product_name']}
                </Form.Control.Feedback>
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label htmlFor="administration-date" className="input-label">
                  Administration Date{schema?.fields?.administration_date?._exclusive?.required && '*'}
                </Form.Label>
                <DateInput
                  isInvalid={!!this.state.errors['adminstration_date']}
                  id="administration-date"
                  date={this.state.administration_date}
                  minDate={'1900-01-01'}
                  maxDate={moment().format('YYYY-MM-DD')}
                  onChange={this.handleAdministrationDateChange}
                  placement="bottom"
                  customClass="form-control-lg"
                  ariaLabel="Administration Date Input"
                />
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['adminstration_date']}
                </Form.Control.Feedback>
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label htmlFor="dose-number-select" className="input-label">
                  Dose Number{schema?.fields?.dose_number?._exclusive?.required && '*'}
                </Form.Label>
                <Select
                  inputId="dose-number-select"
                  name="dose_number"
                  defaultValue={
                    this.props.currentVaccineData?.dose_number
                      ? { label: this.props.currentVaccineData.dose_number, value: this.props.currentVaccineData.dose_number }
                      : ''
                  }
                  value={this.state.dose_number ? { label: this.state.dose_number, value: this.state.dose_number } : ''}
                  options={this.getDropdownOptions(this.props.dose_number_options)}
                  onChange={this.handleDoseNumberChange}
                  placeholder=""
                  styles={vaccineModalSelectStyling}
                  theme={bootstrapSelectTheme}
                />
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['dose_number']}
                </Form.Control.Feedback>
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col} controlId="notes">
                <Form.Label className="input-label">Notes{schema?.fields?.notes?._exclusive?.required && '*'}</Form.Label>
                <Form.Control
                  as="textarea"
                  rows="5"
                  className="form-square"
                  value={this.state.notes}
                  placeholder={'Enter any additional information about this vaccination...'}
                  maxLength={MAX_NOTES_LENGTH}
                  onChange={this.handleNotesChange}
                  isInvalid={!!this.state.errors['notes']}
                />
                <Form.Control.Feedback className="d-block" type="invalid">
                  {this.state.errors['notes']}
                </Form.Control.Feedback>
                <div className="character-limit-text">{this.state.notes ? MAX_NOTES_LENGTH - this.state.notes.length : 2000} characters remaining</div>
              </Form.Group>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.onClose}>
            Cancel
          </Button>
          <span data-for="submit-tooltip" data-tip="" className="ml-1">
            <Button variant="primary btn-square" disabled={this.state.loading || !isValid} onClick={this.submit}>
              {this.state.loading && (
                <React.Fragment>
                  <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
                </React.Fragment>
              )}
              {this.props.editMode ? 'Update' : 'Create'}
            </Button>
          </span>
          {/* Typically we pair the ReactTooltip up directly next to the mount point. However, due to the disabled attribute on the button */}
          {/* above, this Tooltip should be placed outside the parent component (to prevent unwanted parent opacity settings from being inherited) */}
          {/* This does not impact component functionality at all. */}
          {!isValid && (
            <ReactTooltip id="submit-tooltip" multiline={true} place="top" type="dark" effect="solid" className="tooltip-container text-left">
              Please select at least a Vaccine Group and a Product Name.
            </ReactTooltip>
          )}
        </Modal.Footer>
      </Modal>
    );
  }
}

const schema = yup.object().shape({
  group_name: yup.string().required('Please select a vaccine group.').max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  product_name: yup.string().required('Please select a product name.').max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  administration_date: yup
    .date('Date must correspond to the "mm/dd/yyyy" format.')
    .min(moment('1900-01-01'), 'Specimen Collection Date must fall after January 1, 2020.')
    .max(moment(), 'Specimen Collection Date cannot be in the future.')
    .nullable(),
  dose_number: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  notes: yup.string().max(2000, 'Max length exceeded, please limit to 2000 characters.').nullable(),
});

VaccineModal.propTypes = {
  currentVaccineData: PropTypes.object,
  onClose: PropTypes.func,
  onSave: PropTypes.func,
  editMode: PropTypes.bool,
  vaccine_mapping: PropTypes.object,
  group_name_options: PropTypes.array,
  additional_product_name_options: PropTypes.array,
  dose_number_options: PropTypes.array,
};

export default VaccineModal;
