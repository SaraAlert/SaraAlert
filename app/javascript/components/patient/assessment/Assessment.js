import React from 'react';
import PropTypes from 'prop-types';
import { Carousel } from 'react-bootstrap';
import axios from 'axios';

import SymptomsAssessment from './steps/SymptomsAssessment';
import AssessmentCompleted from './steps/AssessmentCompleted';
import reportError from '../../util/ReportError';

// For backwards-compatibility reasons, we still want to support the old 2-letter language codes
// THIS SHOULDN'T BE NECESSARY AS WE TRANSLATE THIS ON THE BACK-END
const LANGUAGE_MAPPINGS = {
  en: 'eng',
  es: 'spa',
  'es-PR': 'spa-PR',
  so: 'som',
  fr: 'fra',
};

class Assessment extends React.Component {
  constructor(props) {
    super(props);
    this.state = { index: 0, direction: null, lastIndex: null, lang: this.mapLanguage() };
  }

  mapLanguage = () => {
    if (Object.prototype.hasOwnProperty.call(LANGUAGE_MAPPINGS, this.props.lang)) {
      // If we make it through testing without this ever printing, i think it's safe to remove it.
      console.error("I do not think this should ever print. If this prints, something is happening that we don't understand.");
      return LANGUAGE_MAPPINGS[`${this.props.lang}`];
    } else {
      return this.props.lang;
    }
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

  submit = submitData => {
    submitData.threshold_hash = this.props.threshold_hash;
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios({
      method: 'post',
      url: `${window.BASE_PATH}${this.props.current_user ? '' : '/report'}/patients/${this.props.patient_submission_token}/assessments${
        this.props.updateId ? '/' + this.props.updateId : ''
      }`,
      data: submitData,
    })
      .then(() => {
        if (this.props.reload) {
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
              lang={this.state.lang || 'eng'}
            />
          </Carousel.Item>
          <Carousel.Item>
            <AssessmentCompleted translations={this.props.translations} lang={this.state.lang || 'eng'} contact_info={this.props.contact_info || {}} />
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
