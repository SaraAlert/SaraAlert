import React from 'react';
import PropTypes from 'prop-types';
import { Carousel } from 'react-bootstrap';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import { pickBy, identity } from 'lodash';
import axios from 'axios';
import libphonenumber from 'google-libphonenumber';
import _ from 'lodash';

import Identification from './steps/Identification';
import Address from './steps/Address';
import Contact from './steps/Contact';
import Arrival from './steps/Arrival';
import AdditionalPlannedTravel from './steps/AdditionalPlannedTravel';
import Exposure from './steps/Exposure';
import Review from './steps/Review';
import confirmDialog from '../util/ConfirmDialog';
import reportError from '../util/ReportError';

const PNF = libphonenumber.PhoneNumberFormat;
const phoneUtil = libphonenumber.PhoneNumberUtil.getInstance();

class Enrollment extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      index: this.props.editMode ? 6 : 0,
      direction: null,
      enrollmentState: {
        patient: pickBy(this.props.patient, identity),
        propagatedFields: {},
        isolation: !!this.props.patient.isolation,
        blocked_sms: this.props.blocked_sms,
      },
    };
  }

  componentDidMount() {
    window.onbeforeunload = function() {
      return 'All progress will be lost. Are you sure?';
    };
  }

  setEnrollmentState = enrollmentState => {
    let currentEnrollmentState = this.state.enrollmentState;
    this.setState({
      enrollmentState: {
        patient: { ...currentEnrollmentState.patient, ...enrollmentState.patient },
        propagatedFields: { ...currentEnrollmentState.propagatedFields, ...enrollmentState.propagatedFields },
        isolation: Object.prototype.hasOwnProperty.call(enrollmentState, 'isolation') ? !!enrollmentState.isolation : currentEnrollmentState.isolation,
        blocked_sms: enrollmentState.blocked_sms,
      },
    });
  };

  handleConfirmDuplicate = async (data, groupMember, message, reenableSubmit, confirmText) => {
    if (await confirmDialog(confirmText)) {
      data['bypass_duplicate'] = true;
      axios({
        method: this.props.editMode ? 'patch' : 'post',
        url: window.BASE_PATH + (this.props.editMode ? '/patients/' + this.props.patient.id : '/patients'),
        data: data,
      })
        .then(response => {
          toast.success(message, {
            onClose: () =>
              (location.href =
                window.BASE_PATH + (groupMember ? '/patients/' + response['data']['responder_id'] + '/group' : '/patients/' + response['data']['id'])),
          });
        })
        .catch(err => {
          reportError(err);
        });
    } else {
      window.onbeforeunload = function() {
        return 'All progress will be lost. Are you sure?';
      };
      reenableSubmit();
    }
  };

  submit = (_event, groupMember, reenableSubmit) => {
    window.onbeforeunload = null;
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;

    let diffKeys = Object.keys(this.state.enrollmentState.patient).filter(
      k => _.get(this.state.enrollmentState.patient, k) !== _.get(this.props.patient, k) || k === 'id'
    );

    // Manually add preferred contact method for new enrollment if it is not changed
    if (!this.editMode && !diffKeys.includes('preferred_contact_method')) {
      diffKeys.push('preferred_contact_method');
    }

    // Manually add close contact keys to diffKeys if enrolling from a close contact
    // They are passed in as props and thus are not added by triggering the onChange
    if (!this.editMode && this.props.cc_id) {
      const closeContactKeys = ['first_name', 'last_name', 'primary_telephone', 'email', 'contact_of_known_case', 'contact_of_known_case_id', 'exposure_notes'];
      closeContactKeys.forEach(key => {
        // only add the key if it is not already there
        if (!diffKeys.includes(key)) {
          diffKeys.push(key);
        }
      });
    }

    let data = new Object({
      patient: this.props.parent_id ? this.state.enrollmentState.patient : _.pick(this.state.enrollmentState.patient, diffKeys),
      propagated_fields: this.state.enrollmentState.propagatedFields,
    });

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
    if (this.props.cc_id) {
      data['cc_id'] = this.props.cc_id;
    }
    if (data.patient.symptom_onset !== undefined && data.patient.symptom_onset !== null && data.patient.symptom_onset !== this.props.patient.symptom_onset) {
      data.patient.user_defined_symptom_onset = true;
    }
    data['bypass_duplicate'] = false;
    axios({
      method: this.props.editMode ? 'patch' : 'post',
      url: window.BASE_PATH + (this.props.editMode ? '/patients/' + this.props.patient.id : '/patients'),
      data: data,
    })
      .then(response => {
        if (response.data && response.data.is_duplicate) {
          const dupFieldData = response.data.duplicate_field_data;
          const patientType = this.state.enrollmentState.isolation ? 'case' : 'monitoree';

          let text = `This ${patientType} already appears to exist in the system! `;

          if (dupFieldData) {
            // Format matching fields and associated counts for text display
            for (const fieldData of dupFieldData) {
              text += `There ${fieldData.count > 1 ? `are ${fieldData.count} records` : 'is 1 record'}  with matching values in the following field(s): `;
              let field;
              for (let i = 0; i < fieldData.fields.length; i++) {
                // parseInt() to satisfy eslint-security
                field = fieldData.fields[parseInt(i)];
                if (fieldData.fields.length > 1) {
                  text += i == fieldData.fields.length - 1 ? `and ${field}. ` : `${field}, `;
                } else {
                  text += `${field}. `;
                }
              }
            }
          }
          text += ` Are you sure you want to enroll this ${patientType}?`;

          // Duplicate, ask if want to continue with create
          this.handleConfirmDuplicate(data, groupMember, message, reenableSubmit, text);
        } else {
          // Success, inform user and redirect to home
          toast.success(message, {
            onClose: () =>
              (location.href =
                window.BASE_PATH + (groupMember ? '/patients/' + response['data']['responder_id'] + '/group' : '/patients/' + response['data']['id'])),
          });
        }
      })
      .catch(err => {
        reportError(err);
      });
  };

  next = () => {
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
  };

  previous = () => {
    let index = this.state.index;
    this.setState({ direction: 'prev' }, () => {
      this.setState({ index: index - 1, lastIndex: null });
    });
  };

  goto = targetIndex => {
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
  };

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
            <Address currentState={this.state.enrollmentState} setEnrollmentState={this.setEnrollmentState} previous={this.previous} next={this.next} />
          </Carousel.Item>
          <Carousel.Item>
            <Contact
              currentState={this.state.enrollmentState}
              setEnrollmentState={this.setEnrollmentState}
              previous={this.previous}
              next={this.next}
              blocked_sms={this.props.blocked_sms}
            />
          </Carousel.Item>
          <Carousel.Item>
            <Arrival currentState={this.state.enrollmentState} setEnrollmentState={this.setEnrollmentState} previous={this.previous} next={this.next} />
          </Carousel.Item>
          <Carousel.Item>
            <AdditionalPlannedTravel
              currentState={this.state.enrollmentState}
              setEnrollmentState={this.setEnrollmentState}
              previous={this.previous}
              next={this.next}
            />
          </Carousel.Item>
          <Carousel.Item>
            <Exposure
              currentState={this.state.enrollmentState}
              setEnrollmentState={this.setEnrollmentState}
              previous={this.previous}
              next={this.next}
              patient={this.props.patient}
              has_dependents={this.props.has_dependents}
              jurisdiction_paths={this.props.jurisdiction_paths}
              assigned_users={this.props.assigned_users}
              authenticity_token={this.props.authenticity_token}
            />
          </Carousel.Item>
          <Carousel.Item>
            <Review
              currentState={this.state.enrollmentState}
              previous={this.previous}
              goto={this.goto}
              submit={this.submit}
              parent_id={this.props.parent_id}
              canAddGroup={this.props.can_add_group}
              jurisdiction_paths={this.props.jurisdiction_paths}
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
  propagated_fields: PropTypes.object,
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  assigned_users: PropTypes.array,
  editMode: PropTypes.bool,
  parent_id: PropTypes.number,
  cc_id: PropTypes.number,
  can_add_group: PropTypes.bool,
  has_dependents: PropTypes.bool,
  blocked_sms: PropTypes.bool,
};

export default Enrollment;
