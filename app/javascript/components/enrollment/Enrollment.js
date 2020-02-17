import React from 'react';
import PropTypes from 'prop-types';
import axios from 'axios';
import { debounce, pickBy, identity } from 'lodash';
import { Carousel } from 'react-bootstrap';
import Identification from './steps/Identification';
import Address from './steps/Address';
import Contact from './steps/Contact';
import Arrival from './steps/Arrival';
import Exposure from './steps/Exposure';
import Review from './steps/Review';
import AdditionalPlannedTravel from './steps/AdditionalPlannedTravel';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import BreadcrumbPath from '../BreadcrumbPath';

class Enrollment extends React.Component {
  constructor(props) {
    super(props);
    this.state = { index: this.props.editMode ? 6 : 0, direction: null, enrollmentState: pickBy(this.props.patient, identity) };
    this.setEnrollmentState = debounce(this.setEnrollmentState.bind(this), 1000);
    this.submit = this.submit.bind(this);
    this.next = this.next.bind(this);
    this.previous = this.previous.bind(this);
    this.goto = this.goto.bind(this);
  }

  componentDidMount() {
    window.onbeforeunload = function() {
      return 'All progress will be lost. Are you sure?';
    };
  }

  setEnrollmentState(enrollmentState) {
    let currentEnrollmentState = this.state.enrollmentState;
    this.setState({ enrollmentState: { ...currentEnrollmentState, ...enrollmentState } });
  }

  submit(_event, groupMember) {
    window.onbeforeunload = null;
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    const data = new Object({ patient: this.state.enrollmentState });
    const message = this.props.editMode ? 'Subject Successfully Updated.' : 'Subject Successfully Saved.';
    if (this.props.parent_id) {
      data['responder_id'] = this.props.parent_id;
    }
    axios({
      method: this.props.editMode ? 'patch' : 'post',
      url: this.props.editMode ? '/patients/' + this.props.patient.id : '/patients',
      data: data,
    })
      .then(function(data) {
        // Inform user and redirect to home on success
        toast.success(message, {
          onClose: () => (location.href = groupMember ? '/patients/' + data['data']['id'] + '/group' : '/patients/' + data['data']['id']),
        });
      })
      .catch(function(error) {
        // TODO: Figure out what to do on error
        console.log(error);
      });
  }

  next() {
    let index = this.state.index;
    let lastIndex = this.state.lastIndex;
    if (lastIndex) {
      this.setState({ direction: 'next' }, () => {
        this.setState({ index: lastIndex, lastIndex: null });
      });
    } else {
      this.setState({ direction: 'next' }, () => {
        this.setState({ index: index + 1, lastIndex: null });
      });
    }
  }

  previous() {
    let index = this.state.index;
    this.setState({ direction: 'prev' }, () => {
      this.setState({ index: index - 1, lastIndex: null });
    });
  }

  goto(targetIndex) {
    let index = this.state.index;
    if (targetIndex > index) {
      this.setState({ direction: 'next' }, () => {
        this.setState({ index: targetIndex, lastIndex: index });
      });
    } else if (targetIndex < index) {
      this.setState({ direction: 'prev' }, () => {
        this.setState({ index: targetIndex, lastIndex: index });
      });
    }
  }

  render() {
    return (
      <React.Fragment>
        <BreadcrumbPath
          current_user={this.props.current_user}
          crumbs={[new Object({ value: 'Return To Dashboard', href: '/' }), new Object({ value: 'Register New Subject', href: null })]}
        />
        <Carousel
          controls={false}
          indicators={false}
          interval={null}
          keyboard={false}
          activeIndex={this.state.index}
          direction={this.state.direction}
          onSelect={() => {}}>
          <Carousel.Item>
            <Identification goto={this.goto} next={this.next} setEnrollmentState={this.setEnrollmentState} currentState={this.state.enrollmentState} />
          </Carousel.Item>
          <Carousel.Item>
            <Address
              goto={this.goto}
              next={this.next}
              previous={this.previous}
              setEnrollmentState={this.setEnrollmentState}
              currentState={this.state.enrollmentState}
            />
          </Carousel.Item>
          <Carousel.Item>
            <Contact
              goto={this.goto}
              next={this.next}
              previous={this.previous}
              setEnrollmentState={this.setEnrollmentState}
              currentState={this.state.enrollmentState}
            />
          </Carousel.Item>
          <Carousel.Item>
            <Arrival
              goto={this.goto}
              next={this.next}
              previous={this.previous}
              setEnrollmentState={this.setEnrollmentState}
              currentState={this.state.enrollmentState}
            />
          </Carousel.Item>
          <Carousel.Item>
            <AdditionalPlannedTravel
              goto={this.goto}
              next={this.next}
              previous={this.previous}
              setEnrollmentState={this.setEnrollmentState}
              currentState={this.state.enrollmentState}
            />
          </Carousel.Item>
          <Carousel.Item>
            <Exposure
              goto={this.goto}
              next={this.next}
              previous={this.previous}
              setEnrollmentState={this.setEnrollmentState}
              currentState={this.state.enrollmentState}
            />
          </Carousel.Item>
          {/* TODO: Risk factors */}
          <Carousel.Item>
            <Review
              goto={this.goto}
              submit={this.submit}
              previous={this.previous}
              setEnrollmentState={this.setEnrollmentState}
              currentState={this.state.enrollmentState}
              parentId={this.props.parent_id}
            />
          </Carousel.Item>
        </Carousel>
        <ToastContainer position="top-center" autoClose={3000} closeOnClick pauseOnVisibilityChange draggable pauseOnHover />
      </React.Fragment>
    );
  }
}

Enrollment.propTypes = {
  current_user: PropTypes.object,
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  enrollmentState: PropTypes.object,
  editMode: PropTypes.bool,
  parent_id: PropTypes.string,
};

export default Enrollment;
