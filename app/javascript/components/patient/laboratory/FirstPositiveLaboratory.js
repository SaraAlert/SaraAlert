import React from 'react';
import { PropTypes } from 'prop-types';
import { Button } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import moment from 'moment';

import confirmDialog from '../../util/ConfirmDialog';
import LaboratoryModal from './LaboratoryModal';

class FirstPositiveLaboratory extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showModal: false,
    };
  }

  handleDelete = async () => {
    const options = {
      title: 'Delete Positive Lab Result',
      okLabel: 'Delete',
      cancelLabel: 'Cancel',
      okVariant: 'danger',
    };
    if (await confirmDialog('Are you sure you want to delete this lab result?', options)) {
      this.props.onChange(null);
    }
  };

  render() {
    return (
      <React.Fragment>
        {this.props.lab ? (
          <div className={this.props.displayedLabClass || 'my-2'}>
            <div className="first-positive-lab-result-header pb-1">
              <span className="input-label">FIRST POSITIVE LAB RESULT</span>
              <span data-for="delete-first_positive_lab_tooltip" data-tip="" className="edit-link">
                <Button
                  variant="link"
                  id="delete-first_positive_lab"
                  className="py-0 px-1 icon-btn-dark"
                  onClick={this.handleDelete}
                  disabled={this.props.disableDelete}
                  aria-label="Delete Positive Lab Result">
                  <i className="fas fa-trash"></i>
                </Button>
              </span>
              {this.props.disableDelete && (
                <ReactTooltip id="delete-first_positive_lab_tooltip" multiline={true} place="left" type="dark" effect="solid" className="tooltip-container">
                  Existing lab results must be deleted from the Lab Results table in the monitoree&apos;s record
                </ReactTooltip>
              )}
              <div className="edit-link">
                <Button
                  variant="link"
                  id="edit-first_positive_lab"
                  className="py-0 px-1 icon-btn-dark"
                  onClick={() => this.setState({ showModal: true })}
                  aria-label="Edit Positive Lab Result">
                  <i className="fas fa-edit fa-fw"></i>
                </Button>
              </div>
            </div>
            <div>
              <span className="first-positive-lab-result-field-name">Type: </span>
              <span className="first-positive-lab-result-field-value">{this.props.lab.lab_type || '--'}</span>
            </div>
            <div>
              <span className="first-positive-lab-result-field-name">Specimen Collection Date: </span>
              <span className="first-positive-lab-result-field-value">
                {this.props.lab.specimen_collection ? moment(this.props.lab.specimen_collection, 'YYYY-MM-DD').format('MM/DD/YYYY') : '--'}
              </span>
            </div>
            <div>
              <span className="first-positive-lab-result-field-name">Report Date: </span>
              <span className="first-positive-lab-result-field-value">
                {this.props.lab.report ? moment(this.props.lab.report, 'YYYY-MM-DD').format('MM/DD/YYYY') : '--'}
              </span>
            </div>
            <div>
              <span className="first-positive-lab-result-field-name">Result: </span>
              <span className="first-positive-lab-result-field-value">{this.props.lab.result || '--'}</span>
            </div>
          </div>
        ) : (
          <div className="mb-2">
            <div className="input-label mb-2">POSITIVE LAB RESULT</div>
            <Button variant="primary" size={this.props.size || 'md'} onClick={() => this.setState({ showModal: true })}>
              <i className="fas fa-plus-square mr-2"></i>
              Enter Lab Result
            </Button>
          </div>
        )}
        {this.state.showModal && (
          <LaboratoryModal
            currentLabData={this.props.lab}
            firstPositiveLab={true}
            onSave={lab => {
              this.setState({ showModal: false }, () => {
                this.props.onChange(lab);
              });
            }}
            onClose={() => this.setState({ showModal: false })}
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
  disableDelete: PropTypes.bool,
  onChange: PropTypes.func,
  size: PropTypes.oneOf(['sm', 'md', 'lg']),
  displayedLabClass: PropTypes.string,
};

export default FirstPositiveLaboratory;
