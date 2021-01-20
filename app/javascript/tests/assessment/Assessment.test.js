import React from 'react'
import { shallow } from 'enzyme';
import { Carousel } from 'react-bootstrap';
import Assessment from '../../components/assessment/Assessment.js'
import SymptomsAssessment from '../../components/assessment/steps/SymptomsAssessment.js'
import AssessmentCompleted from '../../components/assessment/steps/AssessmentCompleted.js'
import { mockPatient1 } from '../mocks/mockPatients'
import { mockAssessment1 } from '../mocks/mockAssessments'
import { mockUser1 } from '../mocks/mockUsers'
import { mockTranslations } from '../mocks/mockTranslations'

const contactInfo = {
  email: 'email@example.com',
  phone: '1111111111',
  webpage: 'somewebpage.com'
}
const patientSubmissionToken = 'SBjjR0SfMB';
const thresholdHash = '6287ac3ebfc5ee8404cff93d96c9b06567767e2903deec22047f34083666f8df'
const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';

function getWrapper() {
  return shallow(<Assessment report={mockAssessment1} symptoms={mockAssessment1.symptoms} current_user={mockUser1} patient={mockPatient1} patient_initials={'AA'}
  patient_age={39} lang={'en'} contact_info={contactInfo} translations={mockTranslations} reload={false} updateId={789} idPre={'789'}
  authenticity_token={authyToken} threshold_hash={thresholdHash} patient_submission_token={patientSubmissionToken} />);
}

describe('Report', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Carousel).exists()).toBeTruthy();
    expect(wrapper.find(Carousel.Item).exists()).toBeTruthy();
    expect(wrapper.find(Carousel.Item).length).toEqual(2);
    expect(wrapper.find(Carousel.Item).at(0).find(SymptomsAssessment).exists()).toBeTruthy();
    expect(wrapper.find(Carousel.Item).at(1).find(AssessmentCompleted).exists()).toBeTruthy();
  });

  it('Calling goto method properly updates index and updates state correctly', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Carousel).prop('activeIndex')).toEqual(0);
    expect(wrapper.state('index')).toEqual(0);
    expect(wrapper.state('direction')).toEqual(null);
    expect(wrapper.state('lastIndex')).toEqual(null);
    wrapper.instance().goto(1);
    expect(wrapper.find(Carousel).prop('activeIndex')).toEqual(1);
    expect(wrapper.state('index')).toEqual(1);
    expect(wrapper.state('direction')).toEqual('next');
    expect(wrapper.state('lastIndex')).toEqual(0);
    wrapper.instance().goto(1);
    expect(wrapper.find(Carousel).prop('activeIndex')).toEqual(1);
    expect(wrapper.state('index')).toEqual(1);
    expect(wrapper.state('direction')).toEqual('next');
    expect(wrapper.state('lastIndex')).toEqual(0);
    wrapper.instance().goto(0);
    expect(wrapper.find(Carousel).prop('activeIndex')).toEqual(0);
    expect(wrapper.state('index')).toEqual(0);
    expect(wrapper.state('direction')).toEqual('prev');
    expect(wrapper.state('lastIndex')).toEqual(1);
    wrapper.instance().goto(0);
    expect(wrapper.find(Carousel).prop('activeIndex')).toEqual(0);
    expect(wrapper.state('index')).toEqual(0);
    expect(wrapper.state('direction')).toEqual('prev');
    expect(wrapper.state('lastIndex')).toEqual(1);
  });
});
