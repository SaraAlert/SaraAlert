import React from 'react';
import { Card, Button } from 'react-bootstrap';
import Patient from '../../Patient';
import { PropTypes } from 'prop-types';

class Review extends React.Component {
  constructor(props) {
    super(props);
    this.state = { submitDisabled: false };
    this.submit = this.submit.bind(this);
  }

  submit(event, groupMember) {
    this.setState({ submitDisabled: true });
    this.props.submit(event, groupMember);
  }

  render() {
    return (
      <React.Fragment>
        <Card className="mx-2 card-square">
          <Card.Header as="h5">Monitoree Review</Card.Header>
          <Card.Body>
            <Patient goto={this.props.goto} details={this.props.currentState || {}} />
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
            {this.props.submit && !this.props.parent_id && this.props.currentState.responder_id === this.props.currentState.id && (
              <Button
                variant="primary"
                size="lg"
                className="float-right btn-square px-5 mr-4"
                disabled={this.state.submitDisabled}
                onClick={event => this.submit(event, true)}>
                Finish and add a Group Member
              </Button>
            )}
          </Card.Body>
        </Card>
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
};

export default Review;
