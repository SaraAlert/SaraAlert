import React from "react"
import { Card, Button } from 'react-bootstrap';
import Patient from '../../Patient';

class Review extends React.Component {

  constructor(props) {
    super(props);
  }

  render () {
    return (
      <React.Fragment>
        <Card className="mx-4 card-square">
          <Card.Header as="h5">Subject Review</Card.Header>
          <Card.Body>
            <Patient goto={this.props.goto} details={this.props.currentState || {}} />
            <div className="pb-4"></div>
            {this.props.previous && <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>Previous</Button>}
            {this.props.next && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.next}>{!!this.props.lastIndex && "Back"}{!!!this.props.lastIndex && "Next"}</Button>}
            {this.props.submit && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.submit}>Finish</Button>}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

export default Review