import React from "react"
import PropTypes from "prop-types"
import axios from "axios"
import { Carousel } from 'react-bootstrap';
import Identification from './steps/Identification';
import Address from './steps/Address';
import Contact from './steps/Contact';
import Arrival from './steps/Arrival';
import Exposure from './steps/Exposure';
import Review from './steps/Review';
import Risk from './steps/Risk';
import AdditionalPlannedTravel from './steps/AdditionalPlannedTravel';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

class Enrollment extends React.Component {

  constructor(props) {
    super(props);
    this.state = { index: 0, direction: null };
    this.setEnrollmentState = this.setEnrollmentState.bind(this);
    this.submit = this.submit.bind(this);
    this.next = this.next.bind(this);
    this.previous = this.previous.bind(this);
    this.goto = this.goto.bind(this);
  }

  setEnrollmentState(enrollmentState) {
    let currentEnrollmentState = this.state.enrollmentState;
    this.setState( { enrollmentState: { ...currentEnrollmentState, ...enrollmentState } } );
  }

  submit() {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token
    axios.post('/patients', { patient: this.state.enrollmentState }).then(function (response) {
      // Inform user and redirect to home on success
      toast.success('Record Successfully Saved', { onClose: () => location.href = '/' });
    }).catch(function (error) {
      // TODO: Figure out what to do on error
      console.log(error);
    });
  }

  next() {
    let index = this.state.index;
    let lastIndex = this.state.lastIndex;
    if (lastIndex) {
      this.setState({direction: "next"}, () => {
        this.setState({index: lastIndex + 1, lastIndex: null});
      });
    } else {
      this.setState({direction: "next"}, () => {
        this.setState({index: index + 1, lastIndex: null});
      });
    }
  }

  previous() {
    let index = this.state.index;
    this.setState({direction: "prev"}, () => {
      this.setState({index: index - 1, lastIndex: null});
    });
  }

  goto(targetIndex) {
    let index = this.state.index;
    if (targetIndex > index) {
      this.setState({direction: "next"}, () => {
        this.setState({index: targetIndex, lastIndex: index});
      });
    } else if (targetIndex < index) {
      this.setState({direction: "prev"}, () => {
        this.setState({index: targetIndex, lastIndex: index});
      });
    }
  }

  render () {
    return (
      <React.Fragment>
        <Carousel controls={false} indicators={false} interval={null} keyboard={false} activeIndex={this.state.index} direction={this.state.direction} onSelect={() => {}}>
          <Carousel.Item>
            <Identification goto={this.goto} next={this.next} lastIndex={this.state.lastIndex} setEnrollmentState={this.setEnrollmentState} currentState={this.state.enrollmentState} />
          </Carousel.Item>
          <Carousel.Item>
            <Address goto={this.goto} next={this.next} previous={this.previous} lastIndex={this.state.lastIndex} setEnrollmentState={this.setEnrollmentState} currentState={this.state.enrollmentState} />
          </Carousel.Item>
          <Carousel.Item>
            <Contact goto={this.goto} next={this.next} previous={this.previous} lastIndex={this.state.lastIndex} setEnrollmentState={this.setEnrollmentState} currentState={this.state.enrollmentState} />
          </Carousel.Item>
          <Carousel.Item>
            <Arrival goto={this.goto} next={this.next} previous={this.previous} lastIndex={this.state.lastIndex} setEnrollmentState={this.setEnrollmentState} currentState={this.state.enrollmentState} />
          </Carousel.Item>
          <Carousel.Item>
            <AdditionalPlannedTravel goto={this.goto} next={this.next} previous={this.previous} lastIndex={this.state.lastIndex} setEnrollmentState={this.setEnrollmentState} currentState={this.state.enrollmentState} />
          </Carousel.Item>
          <Carousel.Item>
            <Exposure goto={this.goto} next={this.next} previous={this.previous} lastIndex={this.state.lastIndex} setEnrollmentState={this.setEnrollmentState} currentState={this.state.enrollmentState} />
          </Carousel.Item>
          {/* { TODO: Risk factors */}
          <Carousel.Item>
            <Review goto={this.goto} submit={this.submit} previous={this.previous} lastIndex={this.state.lastIndex} setEnrollmentState={this.setEnrollmentState} currentState={this.state.enrollmentState} />
          </Carousel.Item>
        </Carousel>
        <ToastContainer position="top-center" autoClose={3000} closeOnClick pauseOnVisibilityChange draggable pauseOnHover />
      </React.Fragment>
    );
  }
}

Enrollment.propTypes = {
  patient: PropTypes.object
};

export default Enrollment
