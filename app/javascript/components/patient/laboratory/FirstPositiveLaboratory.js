import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Form } from 'react-bootstrap';
import moment from 'moment';

import LaboratoryModal from './LaboratoryModal';

class FirstPositiveLaboratory extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showModal: false,
    };
  }

  render() {
    return (
      <React.Fragment>
        {this.props.lab ? (
          <div className={this.props.displayedLabClass || 'my-2'}>
            <div className="first-positive-lab-result-header">
              <Form.Label className="input-label mb-1">FIRST POSITIVE LAB RESULT</Form.Label>
              <div className="edit-link">
                <Button variant="link" id="delete-first_positive_lab" className="py-0 px-1 icon-btn-dark" onClick={() => this.props.onChange(null)}>
                  <i className="fas fa-times fa-fw"></i>
                </Button>
              </div>
              <div className="edit-link">
                <Button variant="link" id="edit-first_positive_lab" className="py-0 px-1 icon-btn-dark" onClick={() => this.setState({ showModal: true })}>
                  <i className="fas fa-edit fa-fw"></i>
                </Button>
              </div>
            </div>
            <div>
              <span className="first-positive-lab-result-field-name">Type: </span>
              <span>{this.props.lab.lab_type || '--'}</span>
            </div>
            <div>
              <span className="first-positive-lab-result-field-name">Specimen Collection Date: </span>
              <span>{this.props.lab.specimen_collection ? moment(this.props.lab.specimen_collection, 'YYYY-MM-DD').format('MM/DD/YYYY') : '--'}</span>
            </div>
            <div>
              <span className="first-positive-lab-result-field-name">Report Date: </span>
              <span>{this.props.lab.report ? moment(this.props.lab.report, 'YYYY-MM-DD').format('MM/DD/YYYY') : '--'}</span>
            </div>
            <div>
              <span className="first-positive-lab-result-field-name">Result: </span>
              <span>{this.props.lab.result || '--'}</span>
            </div>
          </div>
        ) : (
          <div className="mb-2">
            <div>
              <Form.Label className="input-label">POSITIVE LAB RESULT</Form.Label>
            </div>
            <Button variant="primary" size={this.props.size || 'md'} onClick={() => this.setState({ showModal: true })}>
              <i className="fas fa-plus-square mr-2"></i>
              Enter Lab Result
            </Button>
          </div>
        )}
        {this.state.showModal && (
          <LaboratoryModal
            lab={this.props.lab}
            specimenCollectionRequired={true}
            onlyPositiveResult={true}
            submit={lab => {
              this.setState({ showModal: false }, () => {
                this.props.onChange(lab);
              });
            }}
            cancel={() => this.setState({ showModal: false })}
            editMode={!!this.props.lab}
            loading={false}
          />
        )}
      </React.Fragment>
    );
  }
}

FirstPositiveLaboratory.propTypes = {
  lab: PropTypes.object,
  onChange: PropTypes.func,
  size: PropTypes.oneOf(['sm', 'md', 'lg']),
  displayedLabClass: PropTypes.string,
};

export default FirstPositiveLaboratory;
