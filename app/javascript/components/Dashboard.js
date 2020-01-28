import React from "react"
import PropTypes from "prop-types"
import { Button } from 'react-bootstrap';

class Dashboard extends React.Component {
  render () {
    return (
      <React.Fragment>
        <Button>Test</Button>
      </React.Fragment>
    );
  }
}

Dashboard.propTypes = {
  name: PropTypes.string
};

export default Dashboard
