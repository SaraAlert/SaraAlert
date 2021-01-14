import React from 'react';
import PropTypes from 'prop-types';
import { Carousel } from 'react-bootstrap';
import axios from 'axios';

import SymptomsAssessment from './steps/SymptomsAssessment';
import AssessmentCompleted from './steps/AssessmentCompleted';
import reportError from '../util/ReportError';

class Assessment extends React.Component {
  constructor(props) {
    super(props);
    this.state = { index: 0, direction: null, lastIndex: null };
  }

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

  submit = submitData => {
    submitData.threshold_hash = this.props.threshold_hash;
    var self = this;
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios({
      method: 'post',
      url: `${window.BASE_PATH}${this.props.current_user ? '' : '/report'}/patients/${this.props.patient_submission_token}/assessments${
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
              submit={this.submit}
              assessment={this.props.assessment}
              symptoms={this.props.symptoms}
              idPre={this.props.idPre}
              translations={this.props.translations}
              patient_initials={this.props.patient_initials}
              patient_age={this.props.patient_age}
              lang={this.props.lang || 'en'}
            />
          </Carousel.Item>
          <Carousel.Item>
            <AssessmentCompleted translations={this.props.translations} lang={this.props.lang || 'en'} contact_info={this.props.contact_info || {}} />
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
  patient_initials: PropTypes.string,
  patient_age: PropTypes.number,
  symptoms: PropTypes.array,
  threshold_hash: PropTypes.string,
  assessment: PropTypes.object,
  updateId: PropTypes.number,
  reload: PropTypes.bool,
  idPre: PropTypes.string,
  current_user: PropTypes.object,
};

export default Assessment;
