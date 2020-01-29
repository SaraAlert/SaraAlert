import React from "react"
import PropTypes from "prop-types"
import { Wizard, Steps, Step } from 'react-albus';
import Identification from './steps/Identification';

class Enrollment extends React.Component {

  constructor(props) {
    super(props);
    this.state = {};
    this.setEnrollmentState = this.setEnrollmentState.bind(this);
  }

  setEnrollmentState(state) {
    this.setState(state, () => {
      debugger
    });
  }

  render () {
    return (
      <React.Fragment>
        <Wizard>
          <Steps>
            <Step
              id="identification"
              render={({ next }) => (<Identification next={next} setEnrollmentState={this.setEnrollmentState} />)}
            />
            <Step
              id="identification1"
              render={({ next, previous }) => (<Identification next={next} previous={previous} />)}
            />
            <Step
              id="identification2"
              render={({ previous }) => (<Identification previous={previous} />)}
            />
          </Steps>
        </Wizard>
      </React.Fragment>
    );
  }
}

Enrollment.propTypes = {
  patient: PropTypes.object
};

export default Enrollment
