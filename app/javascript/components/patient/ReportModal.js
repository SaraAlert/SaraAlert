import React from 'react';
import { Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import Assessment from '../assessment/Assessment';

class ReportModal extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <Modal show={this.props.show} onHide={this.props.onClose} backdrop="static" aria-labelledby="contained-modal-title-vcenter" centered>
        <Modal.Header closeButton></Modal.Header>
        <Modal.Body>
          <Assessment
            current_user={this.props.current_user}
            assessment={this.props.assessment}
            threshold_hash={this.props.threshold_condition_hash}
            symptoms={this.props.symptoms}
            idPre={this.props.idPre}
            patient_submission_token={this.props.patient.submission_token}
            patient_initials={this.props.patient.initials}
            patient_age={this.props.calculated_age}
            authenticity_token={this.props.authenticity_token}
            reload={true}
            patient_id={this.props.patient.id}
            updateId={this.props.updateId}
            translations={this.props.translations}
            lang={'en'}
          />
        </Modal.Body>
      </Modal>
    );
  }
}

ReportModal.propTypes = {
  show: PropTypes.bool,
  onClose: PropTypes.func,
  current_user: PropTypes.object,
  assessment: PropTypes.object,
  threshold_hash: PropTypes.string,
  symptoms: PropTypes.array,
  translations: PropTypes.object,
  patient: PropTypes.object,
  calculated_age: PropTypes.number,
  threshold_condition_hash: PropTypes.string,
  updateId: PropTypes.number,
  idPre: PropTypes.string,
  authenticity_token: PropTypes.string,
};

export default ReportModal;
