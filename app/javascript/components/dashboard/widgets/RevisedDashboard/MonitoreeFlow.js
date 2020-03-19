import React from 'react';
import { Card } from 'react-bootstrap';
import { PropTypes } from 'prop-types';

class MonitoreeFlow extends React.Component {
  constructor(props) {
    super(props);
    // let data = {};
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <Card.Header as="h5" className="text-left">
            Monitoree Flow Over Time - FIXME
          </Card.Header>
          <Card.Body>
            <h4> TODO </h4>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

MonitoreeFlow.propTypes = {
  stats: PropTypes.object,
};

export default MonitoreeFlow;
