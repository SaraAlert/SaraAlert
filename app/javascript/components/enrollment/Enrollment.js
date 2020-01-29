import React from "react"
import PropTypes from "prop-types"
import { Wizard, Steps, Step } from 'react-albus';
import Identification from './steps/Identification';
import Address from './steps/Address';
import { SwitchTransition, CSSTransition } from 'react-transition-group'

class Enrollment extends React.Component {

  constructor(props) {
    super(props);
    this.state = { currentStep: "identification" };
    this.setEnrollmentState = this.setEnrollmentState.bind(this);
  }

  setEnrollmentState(state) {
    this.setState(state);
  }

  render () {
    return (
      <React.Fragment>
          <Wizard render={({ step }) => (
            <SwitchTransition mode={"out-in"}>
              <CSSTransition key={step.id} classNames="stept" timeout={{ enter: 250, exit: 250 }} >
                <Steps key={step.id} step={step.id ? step : undefined}>
                  <Step
                    id="identification"
                    render={({ next }) => (step.id && <Identification next={next} setEnrollmentState={this.setEnrollmentState} currentState={this.state} />)}
                  />
                  <Step
                    id="address"
                    render={({ previous }) => (step.id && <Address previous={previous} setEnrollmentState={this.setEnrollmentState} currentState={this.state} />)}
                  />
                </Steps>
              </CSSTransition>
            </SwitchTransition>
          )}
        />
      </React.Fragment>
    );
  }
}

Enrollment.propTypes = {
  patient: PropTypes.object
};

export default Enrollment
