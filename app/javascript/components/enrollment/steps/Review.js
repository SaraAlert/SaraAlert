import React from 'react';
import { Card, Button, Modal } from 'react-bootstrap';
import Patient from '../../Patient';
import { PropTypes } from 'prop-types';

class Review extends React.Component {
  constructor(props) {
    super(props);
    this.state = { submitDisabled: false, showGroupAddNotification: false };
    this.submit = this.submit.bind(this);
    this.toggleGroupAddNotification = this.toggleGroupAddNotification.bind(this);
    this.reenableSubmit = this.reenableSubmit.bind(this);
  }

  submit(event, groupMember) {
    this.setState({ submitDisabled: true });
    this.props.submit(event, groupMember, this.reenableSubmit);
  }

  reenableSubmit() {
    this.setState({ submitDisabled: false });
  }

  toggleGroupAddNotification() {
    let current = this.state.showGroupAddNotification;
    this.setState({
      showGroupAddNotification: !current,
    });
  }

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            Household enrollment allows for the Head of Household to submit reports on behalf of other members of the household. The head of household is the
            first household member enrolled. By clicking “continue”, any additional household members who are added will have their daily reports submitted by
            the Head of Household.
          </p>
          <p>
            Any household members who wish to report on their own behalf should be enrolled separately and not be added using the “Finish and Add a Household
            Member” button. Select “Cancel” then “Finish” to return to the main enrollment screen.
          </p>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="primary btn-square" onClick={submit}>
            Continue
          </Button>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Card className="mx-2 card-square">
          <Card.Header as="h5">Monitoree Review</Card.Header>
          <Card.Body>
            <Patient
              goto={this.props.goto}
              details={{ ...this.props.currentState.patient } || {}}
              jurisdictionPath={this.props.jurisdictionPaths[this.props.currentState.patient.jurisdiction_id]}
            />
            <div className="pb-4"></div>
            {this.props.previous && (
              <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>
                Previous
              </Button>
            )}
            {this.props.submit && (
              <Button
                variant="secondary"
                size="lg"
                className="float-right btn-square px-5"
                disabled={this.state.submitDisabled}
                onClick={() => {
                  window.history.back();
                }}>
                Cancel
              </Button>
            )}
            {this.props.submit && (
              <Button variant="primary" size="lg" className="float-right btn-square px-5 mr-4" disabled={this.state.submitDisabled} onClick={this.submit}>
                Finish
              </Button>
            )}
            {this.props.submit && !this.props.parent_id && this.props.currentState.responder_id === this.props.currentState.id && this.props.canAddGroup && (
              <Button
                variant="primary"
                size="lg"
                className="float-right btn-square px-5 mr-4"
                disabled={this.state.submitDisabled}
                onClick={this.toggleGroupAddNotification}>
                Finish and Add a Household Member
              </Button>
            )}
          </Card.Body>
        </Card>
        {this.state.showGroupAddNotification &&
          this.createModal('Enroll Household Members', this.toggleGroupAddNotification, event => this.submit(event, true))}
      </React.Fragment>
    );
  }
}

Review.propTypes = {
  currentState: PropTypes.object,
  goto: PropTypes.func,
  previous: PropTypes.func,
  next: PropTypes.func,
  submit: PropTypes.func,
  parent_id: PropTypes.string,
  canAddGroup: PropTypes.bool,
  jurisdictionPaths: PropTypes.object,
};

export default Review;
