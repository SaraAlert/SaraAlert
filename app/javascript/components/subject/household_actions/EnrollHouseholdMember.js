import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Modal } from 'react-bootstrap';

class EnrollHouseholdMember extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      loading: false,
      showModal: false,
    };
  }

  toggleModal = () => {
    let current = this.state.showModal;
    this.setState({ showModal: !current });
  };

  createModal() {
    return (
      <Modal size="lg" show centered onHide={this.toggleModal}>
        <Modal.Header>
          <Modal.Title>Enroll Household Member</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {this.props.isHoh ? (
            <div>
              Use &quot;Enroll Household Member&quot; if you would like this Head of Household to report on behalf of another monitoree{' '}
              <b>who is not yet enrolled</b> in Sara Alert. This Head of Household will report on behalf of the new household member. If the household member is
              already enrolled, please navigate to that record and use the &quot;Move to Household&quot; button.
            </div>
          ) : (
            <div>
              Use &quot;Enroll Household Member&quot; if you would like this monitoree to report on behalf of another monitoree <b>who is not yet enrolled</b>{' '}
              in Sara Alert. This monitoree will become the Head of Household for the new household member. If the household member is already enrolled, please
              navigate to that record and use the &quot;Move to Household&quot; button.
            </div>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.toggleModal}>
            Cancel
          </Button>
          <Button
            variant="primary btn-square"
            href={`${window.BASE_PATH}/patients/${this.props.responderId}/group`}
            onClick={() => {
              this.setState({ loading: true });
            }}
            disabled={this.state.loading}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Continue
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Button size="sm" className="my-2" onClick={this.toggleModal}>
          <i className="fas fa-user-plus"></i> Enroll Household Member
        </Button>
        {this.state.showModal && this.createModal()}
      </React.Fragment>
    );
  }
}

EnrollHouseholdMember.propTypes = {
  responderId: PropTypes.number,
  isHoh: PropTypes.bool,
};

export default EnrollHouseholdMember;
