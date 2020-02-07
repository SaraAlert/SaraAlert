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

  submit() {
    this.setState({ submitDisabled: true });
    this.props.submit();
  }

  render() {
    return (
      <React.Fragment>
        <Card className="mx-2 card-square">
          <Card.Header as="h5">Subject Review</Card.Header>
          <Card.Body>
            <Patient goto={this.props.goto} details={this.props.currentState || {}} />
            <div className="pb-4"></div>
            {this.props.previous && (
              <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>
                Previous
              </Button>
            )}
            {this.props.next && (
              <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.next}>
                Next
              </Button>
            )}
            {this.props.submit && (
              <Button variant="primary" size="lg" className="float-right btn-square px-5" disabled={this.state.submitDisabled} onClick={this.submit}>
                Finish
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
};

export default Review;
