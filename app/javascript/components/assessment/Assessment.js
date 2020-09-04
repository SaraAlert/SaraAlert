import React from 'react';
import PropTypes from 'prop-types';
import { Carousel } from 'react-bootstrap';
import _ from 'lodash';
import axios from 'axios';

import SymptomsAssessment from './steps/SymptomsAssessment';
import AssessmentCompleted from './steps/AssessmentCompleted';
import confirmDialog from '../util/ConfirmDialog';
import reportError from '../util/ReportError';

class Assessment extends React.Component {
  constructor(props) {
    super(props);
    this.state = { index: 0, direction: null, assessmentState: { symptoms: this.props.symptoms } };
    this.setAssessmentState = this.setAssessmentState.bind(this);
    this.next = this.next.bind(this);
    this.previous = this.previous.bind(this);
    this.goto = this.goto.bind(this);
    this.submit = this.submit.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.hasChanges = this.hasChanges.bind(this);
    this.fieldIsEmptyOrNew = this.fieldIsEmptyOrNew.bind(this);
  }

  setAssessmentState(assessmentState) {
    let currentAssessmentState = this.state.assessmentState;
    this.setState({ assessmentState: { ...currentAssessmentState, ...assessmentState } });
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

  // TODO: This needs to use generic symptoms lists and not be hard-coded
  hasChanges() {
    let currentAssessment = _.cloneDeep(this.props.assessment);
    let symptoms = ['cough', 'difficulty_breathing', 'symptomatic'];
    // Having falsey values on them causes the comparison to fail.
    symptoms.forEach(symptom => {
      if (currentAssessment[parseInt(symptom)] === false) {
        delete currentAssessment[parseInt(symptom)];
      }
    });
    return !_.isEqual(this.state.assessmentState, currentAssessment);
  }

  fieldIsEmptyOrNew(object) {
    const keysToIgnore = ['who_reported'];
    let allFieldsEmpty = true;
    _.map(object, (value, key) => {
      if (object[String(key)] !== null && !keysToIgnore.includes(key)) {
        allFieldsEmpty = false;
      }
    });
    if (allFieldsEmpty || _.isEmpty(this.props.assessment)) {
      return true;
    } else {
      return false;
    }
  }

  submit() {
    var submitData = this.state.assessmentState;
    submitData.threshold_hash = this.props.threshold_hash;
    var self = this;
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios({
      method: 'post',
      url: `${window.BASE_PATH}${this.props.signed_in ? '' : '/report'}/patients/${this.props.patient_submission_token}/assessments${
        this.props.updateId ? '/' + this.props.updateId : ''
      }`,
      data: submitData,
    })
      .then(function() {
        if (self.props.reload) {
          location.reload(true);
        }
      })
      .catch(error => {
        reportError(error);
      });
    if (!this.props.reload) {
      // No need to say thanks for reporting if we want to reload the page
      this.goto(1);
    }
  }

  handleSubmit = async () => {
    if (this.fieldIsEmptyOrNew(this.props.assessment)) {
      this.submit();
    } else {
      if (this.hasChanges()) {
        if (await confirmDialog("Are you sure you'd like to modify this report?")) {
          this.submit();
        }
      } else {
        this.submit();
      }
    }
  };

  render() {
    return (
      <React.Fragment>
        <Carousel
          controls={false}
          indicators={false}
          slide={false}
          interval={null}
          keyboard={false}
          activeIndex={this.state.index}
          direction={this.state.direction}
          onSelect={() => {}}>
          <Carousel.Item>
            <SymptomsAssessment
              goto={this.goto}
              submit={this.handleSubmit}
              setAssessmentState={this.setAssessmentState}
              symptoms={this.state.symptoms}
              currentState={this.state.assessmentState}
              idPre={this.props.idPre}
              translations={this.props.translations}
              lang={this.props.lang || 'en'}
            />
          </Carousel.Item>
          <Carousel.Item>
            <AssessmentCompleted
              goto={this.goto}
              submit={this.handleSubmit}
              setAssessmentState={this.setAssessmentState}
              currentState={this.state.assessmentState}
              translations={this.props.translations}
              lang={this.props.lang || 'en'}
              contact_info={this.props.contact_info || {}}
            />
          </Carousel.Item>
        </Carousel>
      </React.Fragment>
    );
  }
}

Assessment.propTypes = {
  translations: PropTypes.object,
  contact_info: PropTypes.object,
  lang: PropTypes.string,
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
  patient_submission_token: PropTypes.string,
  symptoms: PropTypes.array,
  threshold_hash: PropTypes.string,
  assessment: PropTypes.object,
  updateId: PropTypes.number,
  reload: PropTypes.bool,
  idPre: PropTypes.string,
  signed_in: PropTypes.bool,
};

export default Assessment;
