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
import libphonenumber from 'google-libphonenumber';

const PNF = libphonenumber.PhoneNumberFormat;
const phoneUtil = libphonenumber.PhoneNumberUtil.getInstance();

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

  submit(_event, groupMember, reenableSubmit) {
    window.onbeforeunload = null;
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    let data = new Object({ patient: this.state.enrollmentState });
    data.patient.primary_telephone = data.patient.primary_telephone
      ? phoneUtil.format(phoneUtil.parse(data.patient.primary_telephone, 'US'), PNF.E164)
      : data.patient.primary_telephone;
    data.patient.secondary_telephone = data.patient.secondary_telephone
      ? phoneUtil.format(phoneUtil.parse(data.patient.secondary_telephone, 'US'), PNF.E164)
      : data.patient.secondary_telephone;
    const message = this.props.editMode ? 'Monitoree Successfully Updated.' : 'Monitoree Successfully Saved.';
    if (this.props.parent_id) {
      data['responder_id'] = this.props.parent_id;
    }
    data['bypass_duplicate'] = false;
    axios({
      method: this.props.editMode ? 'patch' : 'post',
      url: this.props.editMode ? '/patients/' + this.props.patient.id : '/patients',
      data: data,
    })
      .then(response => {
        if (response['data']['duplicate']) {
          // Duplicate, ask if want to continue with create
          if (window.confirm('This monitoree appears to be a duplicate of an existing record in the system. Are you sure you want to enroll this monitoree?')) {
            data['bypass_duplicate'] = true;
            axios({
              method: this.props.editMode ? 'patch' : 'post',
              url: this.props.editMode ? '/patients/' + this.props.patient.id : '/patients',
              data: data,
            })
              .then(response => {
                toast.success(message, {
                  onClose: () => (location.href = groupMember ? '/patients/' + response['data']['id'] + '/group' : '/patients/' + response['data']['id']),
                });
              })
              .catch(() => {
                toast.error(
                  <div>
                    <div> Failed to communicate with the Sara Alert System Server. </div>
                    <div> If the error continues, please contact a System Administrator. </div>
                  </div>,
                  {
                    autoClose: 10000,
                  }
                );
              });
          } else {
            window.onbeforeunload = function() {
              return 'All progress will be lost. Are you sure?';
            };
            reenableSubmit();
          }
        } else {
          // Success, inform user and redirect to home
          toast.success(message, {
            onClose: () => (location.href = groupMember ? '/patients/' + response['data']['id'] + '/group' : '/patients/' + response['data']['id']),
          });
        }
      })
      .catch(() => {
        toast.error(
          <div>
            <div> Failed to communicate with the Sara Alert System Server. </div>
            <div> If the error continues, please contact a System Administrator. </div>
          </div>,
          {
            autoClose: 10000,
          }
        );
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
          <Carousel.Item>
            <Review
              goto={this.goto}
              submit={this.submit}
              previous={this.previous}
              setEnrollmentState={this.setEnrollmentState}
              currentState={this.state.enrollmentState}
              parentId={this.props.parent_id}
              canAddGroup={this.props.can_add_group}
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
  parent_id: PropTypes.number,
  can_add_group: PropTypes.bool,
};

export default Enrollment;
