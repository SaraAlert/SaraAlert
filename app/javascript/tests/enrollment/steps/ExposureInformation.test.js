import React from 'react';
import { shallow, mount } from 'enzyme';
import ExposureInformation from '../../../components/enrollment/steps/ExposureInformation';
import { blankMockPatient, mockPatient2 } from '../../mocks/mockPatients';
import { mockJurisdiction1, mockJurisdictionPaths } from '../../mocks/mockJurisdiction';
import { mockLaboratory1 } from '../../mocks/mockLaboratories';

const newEnrollmentState = {
  isolation: false,
  patient: blankMockPatient,
  propagatedFields: {},
};

const requiredStrings = ['LAST DATE OF EXPOSURE', 'EXPOSURE LOCATION', 'EXPOSURE COUNTRY', 'CONTINUOUS EXPOSURE', 'EXPOSURE RISK FACTORS (USE COMMAS TO SEPARATE MULTIPLE SPECIFIED VALUES)', 'NOTES'];

describe('ExposureInformation', () => {
  it('Properly renders all main components', () => {
    const wrapper = mount(<ExposureInformation goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} patient={blankMockPatient} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} selected_jurisdiction={mockJurisdiction1} first_positive_lab={mockLaboratory1} edit_mode={false} authenticity_token={'123'} />);
    requiredStrings.forEach(requiredString => {
      expect(wrapper.text().includes(requiredString)).toBe(true);
    });
  });

  it('Properly shows the `Next` button', () => {
    const wrapper = shallow(<ExposureInformation goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} patient={blankMockPatient} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} selected_jurisdiction={mockJurisdiction1} first_positive_lab={mockLaboratory1} edit_mode={false} authenticity_token={'123'} />);
    const button = wrapper.find('.btn-square');
    expect(button.at(0).text()).toEqual('Next');
  });

  it('Properly shows the `Previous` button', () => {
    const wrapper = shallow(<ExposureInformation goto={() => {}} next={() => {}} previous={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} patient={blankMockPatient} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} selected_jurisdiction={mockJurisdiction1} first_positive_lab={mockLaboratory1} edit_mode={false} authenticity_token={'123'} />);
    const button = wrapper.find('.btn-square');
    expect(button.at(0).text()).toEqual('Previous');
  });

  it('Properly hides the `Previous` button', () => {
    const wrapper = shallow(<ExposureInformation goto={() => {}} next={() => {}} previous={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} patient={blankMockPatient} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} hidePreviousButton={true} assigned_users={[]} selected_jurisdiction={mockJurisdiction1} first_positive_lab={mockLaboratory1} edit_mode={false} authenticity_token={'123'} />);
    const button = wrapper.find('.btn-square');
    expect(button.at(0).text()).toEqual('Next');
  });

  it('Properly allows setting of Exposure Location', () => {
    const wrapper = mount(<ExposureInformation goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} patient={blankMockPatient} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} selected_jurisdiction={mockJurisdiction1} first_positive_lab={mockLaboratory1} edit_mode={false} authenticity_token={'123'} />);
    expect(wrapper.find('#potential_exposure_location').instance().value).toEqual('');
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient2 } }, () => {
      expect(wrapper.find('#potential_exposure_location').instance().value).toEqual(mockPatient2.potential_exposure_location);
    });
  });

  it('Properly allows setting of Exposure Country', () => {
    const wrapper = mount(<ExposureInformation goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} patient={blankMockPatient} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} selected_jurisdiction={mockJurisdiction1} first_positive_lab={mockLaboratory1} edit_mode={false} authenticity_token={'123'} />);
    expect(wrapper.find('#potential_exposure_country').instance().value).toEqual('');
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient2 } }, () => {
      expect(wrapper.find('#potential_exposure_country').instance().value).toEqual(mockPatient2.potential_exposure_country);
    });
  });
});
