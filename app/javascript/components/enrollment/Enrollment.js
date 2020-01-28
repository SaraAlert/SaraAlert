import React from "react"
import PropTypes from "prop-types"
import { Button } from 'react-bootstrap';
import StepWizard from 'react-step-wizard';

class Enrollment extends React.Component {



  render () {
    return (
      <React.Fragment>
        <Button>Test</Button>
      </React.Fragment>
    );
  }
}

Enrollment.propTypes = {
  name: PropTypes.string
};

export default Enrollment
