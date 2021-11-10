import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Form, Modal } from 'react-bootstrap';

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

  handleChange = event => {
    event.persist();
    this.setState(state => {
      return { common_exposure_cohort: { ...state.common_exposure_cohort, [event?.target?.id]: event?.target?.value } };
    });
  };

  render() {
    return (
      <Modal size="lg" backdrop="static" show onHide={this.props.onHide} centered>
        <Modal.Header closeButton>
          <Modal.Title>{this.props.common_exposure_cohort ? 'Update' : 'Add'} Common Exposure Cohort</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form.Group>
            <Form.Label className="input-label">Cohort Type</Form.Label>
            <Form.Control
              id="cohort_type"
              as="select"
              size="lg"
              className="form-square"
              aria-label="Cohort Type Select"
              value={this.state.common_exposure_cohort.cohort_type || ''}
              onChange={this.handleChange}>
              {COHORT_TYPES.map((cohort_type, index) => (
                <option key={`cohort-type-${index}`}>{cohort_type}</option>
              ))}
            </Form.Control>
          </Form.Group>
          <Form.Group>
            <Form.Label className="input-label">Cohort Name/Description</Form.Label>
            <Form.Control
              id="cohort_name"
              as="input"
              list="cohort_names"
              autoComplete="off"
              size="lg"
              className="form-square"
              aria-label="Cohort Name"
              onChange={this.handleChange}
              value={this.state.common_exposure_cohort.cohort_name || ''}
            />
            <datalist id="cohort_names">
              {this.props.cohort_names?.map(cohort_name => {
                return (
                  <option value={cohort_name} key={cohort_name}>
                    {cohort_name}
                  </option>
                );
              })}
            </datalist>
          </Form.Group>
          <Form.Group>
            <Form.Label className="input-label">Cohort Location</Form.Label>
            <Form.Control
              id="cohort_location"
              as="input"
              list="cohort_locations"
              autoComplete="off"
              size="lg"
              className="form-square"
              aria-label="Cohort Location"
              onChange={this.handleChange}
              value={this.state.common_exposure_cohort.cohort_location || ''}
            />
            <datalist id="cohort_locations">
              {this.props.cohort_locations?.map(cohort_location => {
                return (
                  <option value={cohort_location} key={cohort_location}>
                    {cohort_location}
                  </option>
                );
              })}
            </datalist>
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
