import React from "react"
import PropTypes from "prop-types"
import { Carousel } from 'react-bootstrap';
import Identification from './steps/Identification';
import Address from './steps/Address';
import Contact from './steps/Contact';
import Arrival from './steps/Arrival';
import Exposure from './steps/Exposure';
import Review from './steps/Review';
import Risk from './steps/Risk';
import AdditionalPlannedTravel from './steps/AdditionalPlannedTravel';

class Enrollment extends React.Component {

  constructor(props) {
    super(props);
    this.state = { index: 0, direction: null };
    this.setEnrollmentState = this.setEnrollmentState.bind(this);
    this.next = this.next.bind(this);
    this.previous = this.previous.bind(this);
    this.goto = this.goto.bind(this);
  }

  setEnrollmentState(state) {
    this.setState(state);
  }

  next() {
    let index = this.state.index;
    this.setState({index: index + 1, direction: "next"});
  }

  previous() {
    let index = this.state.index;
    this.setState({index: index - 1, direction: "prev"});
  }

  goto(targetIndex) {
    let index = this.state.index;
    if (targetIndex > index) {
      this.setState({index: targetIndex, direction: "next"});
    } else if (targetIndex < index) {
      this.setState({index: targetIndex, direction: "prev"});
    }
  }

  render () {
    return (
      <React.Fragment>
        <Carousel controls={false} indicators={false} interval={null} keyboard={false} activeIndex={this.state.index} direction={this.state.direction}>
          <Carousel.Item>
            <Identification goto={this.goto} next={this.next} setEnrollmentState={this.setEnrollmentState} currentState={this.state} />
          </Carousel.Item>
          <Carousel.Item>
            <Address goto={this.goto} next={this.next} previous={this.previous} setEnrollmentState={this.setEnrollmentState} currentState={this.state} />
          </Carousel.Item>
          <Carousel.Item>
            <Contact goto={this.goto} next={this.next} previous={this.previous} setEnrollmentState={this.setEnrollmentState} currentState={this.state} />
          </Carousel.Item>
          <Carousel.Item>
            <Arrival goto={this.goto} next={this.next} previous={this.previous} setEnrollmentState={this.setEnrollmentState} currentState={this.state} />
          </Carousel.Item>
          <Carousel.Item>
            <AdditionalPlannedTravel goto={this.goto} next={this.next} previous={this.previous} setEnrollmentState={this.setEnrollmentState} currentState={this.state} />
          </Carousel.Item>
          <Carousel.Item>
            <Exposure goto={this.goto} next={this.next} previous={this.previous} setEnrollmentState={this.setEnrollmentState} currentState={this.state} />
          </Carousel.Item>
          <Carousel.Item>
            <Risk goto={this.goto} next={this.next} previous={this.previous} setEnrollmentState={this.setEnrollmentState} currentState={this.state} />
          </Carousel.Item>
          <Carousel.Item>
            <Review goto={this.goto} previous={this.previous} setEnrollmentState={this.setEnrollmentState} currentState={this.state} />
          </Carousel.Item>
        </Carousel>
      </React.Fragment>
    );
  }
}

Enrollment.propTypes = {
  patient: PropTypes.object
};

export default Enrollment
