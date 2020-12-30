import React from 'react'
import { shallow } from 'enzyme';
import { Carousel } from 'react-bootstrap';
import Report from '../../../components/patient/report/Report.js'
import SymptomsReport from '../../../components/patient/report/SymptomsReport.js'
import ReportCompleted from '../../../components/patient/report/ReportCompleted.js'
import { mockPatient1 } from '../../mocks/mockPatients'
import { mockReport1 } from '../../mocks/mockReports'
import { mockUser1 } from '../../mocks/mockUsers'
import { mockTranslations } from '../../mocks/mockTranslations'

const contactInfo = {
  email: 'email@example.com',
  phone: '1111111111',
  webpage: 'somewebpage.com'
}
const patientSubmissionToken = 'SBjjR0SfMB';
const thresholdHash = '6287ac3ebfc5ee8404cff93d96c9b06567767e2903deec22047f34083666f8df'
const authyToken = 'Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==';

function getWrapper() {
  return shallow(<Report report={mockReport1} symptoms={mockReport1.symptoms} current_user={mockUser1} patient={mockPatient1} patient_initials={'AA'}
  patient_age={39} lang={'en'} contact_info={contactInfo} translations={mockTranslations} reload={false} updateId={789} idPre={'789'}
  authenticity_token={authyToken} threshold_hash={thresholdHash} patient_submission_token={patientSubmissionToken} />);
};

describe('Report', () => {
  it('Properly renders all main components', () => {
    const wrapper = getWrapper();
    expect(wrapper.find(Carousel).exists()).toBeTruthy();
    expect(wrapper.find(Carousel.Item).exists()).toBeTruthy();
    expect(wrapper.find(Carousel.Item).length).toEqual(2);
    expect(wrapper.find(Carousel.Item).at(0).find(SymptomsReport).exists()).toBeTruthy();
    expect(wrapper.find(Carousel.Item).at(1).find(ReportCompleted).exists()).toBeTruthy();
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
