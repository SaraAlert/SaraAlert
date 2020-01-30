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
            <Patient className="pb-3" details={this.props.currentState} />
            {this.props.previous && <Button variant="outline-primary" size="lg" className="btn-square px-5" onClick={this.props.previous}>Previous</Button>}
            {this.props.next && <Button variant="outline-primary" size="lg" className="float-right btn-square px-5" onClick={this.props.next}>Next</Button>}
            {this.props.finish && <Button variant="primary" size="lg" className="float-right btn-square px-5" onClick={this.props.finish}>Finish</Button>}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

export default Review