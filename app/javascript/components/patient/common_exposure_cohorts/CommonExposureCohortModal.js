import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Form, Modal } from 'react-bootstrap';
import CreatableSelect from 'react-select/creatable';
import Select from 'react-select';

import { cursorPointerStyleLg, bootstrapSelectTheme } from '../../../packs/stylesheets/ReactSelectStyling';

const COHORT_TYPES = [
  '',
  'Adult Congregate Living Facility',
  'Child Care Facility',
  'Community Event or Mass Gathering',
  'Correctional Facility',
  'Group Home',
  'Healthcare Facility',
  'Place of Worship',
  'School or University',
  'Shelter',
  'Substance Abuse Treatment Center',
  'Workplace',
  'Other',
];

class CommonExposureCohortModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      common_exposure_cohort: props.common_exposure_cohort || {},
      showCohortModal: false,
    };
  }

  handleChange = (field, data) => {
    this.setState(state => {
      return { common_exposure_cohort: { ...state.common_exposure_cohort, [field]: data?.value } };
    });
  };

  mapSelectOptions = options => {
    return options.map(option => {
      return { label: option, value: option };
    });
  };

  mapSelectValue = value => {
    return { label: value || '', value: value || '' };
  };

  render() {
    return (
      <Modal size="lg" backdrop="static" show onHide={this.props.onHide} centered>
        <Modal.Header closeButton>
          <Modal.Title>{this.props.common_exposure_cohort ? 'Update' : 'Add'} Common Exposure Cohort</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form.Group>
            <Form.Label htmlFor="cohort-type-select">Cohort Type</Form.Label>
            <Select
              inputId="cohort-type-select"
              name="cohort-type"
              value={this.mapSelectValue(this.state.common_exposure_cohort.cohort_type)}
              options={this.mapSelectOptions(COHORT_TYPES)}
              onChange={data => this.handleChange('cohort_type', data)}
              isClearable
              placeholder=""
              styles={cursorPointerStyleLg}
              theme={theme => bootstrapSelectTheme(theme, 'lg')}
            />
          </Form.Group>
          <Form.Group>
            <Form.Label htmlFor="cohort-name-select">Cohort Name/Description</Form.Label>
            <CreatableSelect
              inputId="cohort-name-select"
              name="cohort-name"
              value={this.mapSelectValue(this.state.common_exposure_cohort.cohort_name)}
              options={this.mapSelectOptions(this.props.cohort_names || [])}
              onChange={data => this.handleChange('cohort_name', data)}
              isClearable
              placeholder=""
              formatCreateLabel={value => value}
              styles={cursorPointerStyleLg}
              theme={theme => bootstrapSelectTheme(theme, 'lg')}
            />
          </Form.Group>
          <Form.Group>
            <Form.Label htmlFor="cohort-location-select">Cohort Location</Form.Label>
            <CreatableSelect
              inputId="cohort-location-select"
              name="cohort-location"
              value={this.mapSelectValue(this.state.common_exposure_cohort.cohort_location)}
              options={this.mapSelectOptions(this.props.cohort_locations || [])}
              onChange={data => this.handleChange('cohort_location', data)}
              isClearable
              placeholder=""
              formatCreateLabel={value => value}
              styles={cursorPointerStyleLg}
              theme={theme => bootstrapSelectTheme(theme, 'lg')}
            />
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button id="cohort-modal-cancel-button" variant="secondary btn-square" onClick={this.props.onHide}>
            Cancel
          </Button>
          <Button
            id="cohort-modal-save-button"
            variant="primary btn-square"
            disabled={
              !(
                this.state.common_exposure_cohort.cohort_type ||
                this.state.common_exposure_cohort.cohort_name ||
                this.state.common_exposure_cohort.cohort_location
              )
            }
            onClick={() => this.props.onChange(this.state.common_exposure_cohort, this.props.common_exposure_cohort_index)}>
            {this.props.common_exposure_cohort ? 'Update' : 'Save'}
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }
}

CommonExposureCohortModal.propTypes = {
  common_exposure_cohort: PropTypes.object,
  common_exposure_cohort_index: PropTypes.number,
  cohort_names: PropTypes.array,
  cohort_locations: PropTypes.array,
  onChange: PropTypes.func,
  onHide: PropTypes.func,
};

export default CommonExposureCohortModal;
