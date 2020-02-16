import React from 'react';
import { Button, Card, Modal } from 'react-bootstrap';
import Patient from './Patient';
import BreadcrumbPath from './BreadcrumbPath';
import Assessment from './assessment/Assessment';
import { PropTypes } from 'prop-types';

class PatientPage extends React.Component {
  constructor(props) {
    super(props);
    this.state = { showAddAssessment: false };
    this.reloadHook = this.reloadHook.bind(this);
  }

  reloadHook() {
    // Optional reload, specifically for assessments
    location.href = '/patients/' + this.props.patient.id;
  }

  render() {
    return (
      <React.Fragment>
        <BreadcrumbPath
          current_user={this.props.current_user}
          crumbs={[
            new Object({ value: 'Return To Dashboard', href: this.props.dashboardUrl ? this.props.dashboardUrl : null }),
            new Object({ value: 'Subject View', href: null }),
          ]}
        />
        <Card className="mx-2 card-square">
          <Card.Header as="h5">
            Subject Details {this.props.patient_id ? `(ID: ${this.props.patient_id})` : ''}{' '}
            {this.props.patient.id && <a href={'/patients/' + this.props.patient.id + '/edit'}>(edit)</a>}
          </Card.Header>
          <Card.Body>
            <Patient details={this.props.patient || {}} />
          </Card.Body>
        </Card>
        {this.props.canAddAssessments && (
          <React.Fragment>
            <Button variant="primary" size="lg" className="mx-2 my-4 btn-square px-4" onClick={() => this.setState({ showAddAssessment: true })}>
              Add Assessment For Subject
            </Button>
            <Modal show={this.state.showAddAssessment} onHide={() => this.setState({ showAddAssessment: false })}>
              <Modal.Header closeButton></Modal.Header>
              <Modal.Body>
                <Assessment
                  patient_submission_token={this.props.patient.submission_token}
                  authenticity_token={this.props.authenticity_token}
                  reloadHook={this.reloadHook}
                />
              </Modal.Body>
            </Modal>
          </React.Fragment>
        )}
      </React.Fragment>
    );
  }
}

PatientPage.propTypes = {
  patient_id: PropTypes.string,
  current_user: PropTypes.object,
  patient: PropTypes.object,
  dashboardUrl: PropTypes.string,
  authenticity_token: PropTypes.string,
  patient_submission_token: PropTypes.string,
  canAddAssessments: PropTypes.bool,
};

export default PatientPage;
