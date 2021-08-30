import React from 'react';
import { shallow, mount } from 'enzyme';
import { Button, Card, Form } from 'react-bootstrap';

import ExposureInformation from '../../../components/enrollment/steps/ExposureInformation';
import PublicHealthManagement from '../../../components/enrollment/steps/PublicHealthManagement';
import DateInput from '../../../components/util/DateInput';
import { blankExposureMockPatient, blankIsolationMockPatient, mockPatient1, mockPatient2 } from '../../mocks/mockPatients';
import { mockJurisdictionPaths } from '../../mocks/mockJurisdiction';

const previousMock = jest.fn();
const nextMock = jest.fn();
const setEnrollmentStateMock = jest.fn();
const exposureInputLabels = ['LAST DATE OF EXPOSURE', 'EXPOSURE LOCATION', 'EXPOSURE COUNTRY', 'CONTINUOUS EXPOSURE', 'EXPOSURE RISK FACTORS (USE COMMAS TO SEPARATE MULTIPLE SPECIFIED VALUES)', 'CLOSE CONTACT WITH A KNOWN CASE', 'TRAVEL FROM AFFECTED COUNTRY OR AREA', 'WAS IN HEALTHCARE FACILITY WITH KNOWN CASES', 'LABORATORY PERSONNEL', 'HEALTHCARE PERSONNEL', 'CREW ON PASSENGER OR CARGO FLIGHT', 'MEMBER OF A COMMON EXPOSURE COHORT', 'NOTES'];
const continuous_exposure_enabled = true;

function getShallowWrapper(patient, showBtn) {
  const current = {
    isolation: patient.isolation,
    patient: patient,
    propagatedFields: {},
  };
  return shallow(<ExposureInformation previous={previousMock} next={nextMock} setEnrollmentState={setEnrollmentStateMock} currentState={current} patient={patient} showPreviousButton={showBtn} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} continuous_exposure_enabled={continuous_exposure_enabled} authenticity_token={'123'} />);
}

function getMountedWrapper(patient, showBtn) {
  const current = {
    isolation: patient.isolation,
    patient: patient,
    propagatedFields: {},
  };
  return mount(<ExposureInformation previous={previousMock} next={nextMock} setEnrollmentState={setEnrollmentStateMock} currentState={current} patient={patient} showPreviousButton={showBtn} has_dependents={false} jurisdiction_paths={mockJurisdictionPaths} assigned_users={[]} continuous_exposure_enabled={continuous_exposure_enabled} authenticity_token={'123'} />);
}

afterEach(() => {
  jest.clearAllMocks();
});

describe('ExposureInformation', () => {
  it('Properly renders all main components when monitoree is in exposure', () => {
    const wrapper = getMountedWrapper(mockPatient2, true);
    expect(wrapper.find('h1.sr-only').exists()).toBe(true);
    expect(wrapper.find('h1.sr-only').text()).toEqual('Monitoree Potential Exposure Information');
    expect(wrapper.find(Card).exists()).toBe(true);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual('Monitoree Potential Exposure Information');
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Form).exists()).toBe(true);
    expect(wrapper.find('#exposure_notes').exists()).toBe(true);
    expect(wrapper.find(PublicHealthManagement).exists()).toBe(true);
    expect(wrapper.find(Button).length).toEqual(2);
    expect(wrapper.find(Button).at(0).text()).toEqual('Previous');
    expect(wrapper.find(Button).at(1).text()).toEqual('Next');
  });

  it('Properly renders all main components when monitoree is in isolation', () => {
    const wrapper = getMountedWrapper(mockPatient1, true);
    expect(wrapper.find('h1.sr-only').exists()).toBe(true);
    expect(wrapper.find('h1.sr-only').text()).toEqual('Monitoree Potential Exposure Information');
    expect(wrapper.find(Card).exists()).toBe(true);
    expect(wrapper.find(Card.Header).exists()).toBe(true);
    expect(wrapper.find(Card.Header).text()).toEqual('Monitoree Potential Exposure Information');
    expect(wrapper.find(Card.Body).exists()).toBe(true);
    expect(wrapper.find(Form).exists()).toBe(true);
    expect(wrapper.find('#exposure_notes').exists()).toBe(false);
    expect(wrapper.find(PublicHealthManagement).exists()).toBe(false);
    expect(wrapper.find(Button).length).toEqual(2);
    expect(wrapper.find(Button).at(0).text()).toEqual('Previous');
    expect(wrapper.find(Button).at(1).text()).toEqual('Next');
  });

  it('Properly renders exposure information inputs when creating a new monitoree', () => {
    const wrapper = getMountedWrapper(blankExposureMockPatient);
    exposureInputLabels.forEach((label, index) => {
      expect(wrapper.find('label').at(index).text()).toContain(label);
    });

    expect(wrapper.find('#last_date_of_exposure').exists()).toBe(true);
    expect(wrapper.find(DateInput).exists()).toBe(true);
    expect(wrapper.find(DateInput).prop('date')).toBeNull();

    expect(wrapper.find('#potential_exposure_location').exists()).toBe(true);
    expect(wrapper.find('#potential_exposure_location').prop('value')).toEqual('');

    expect(wrapper.find('#potential_exposure_country').exists()).toBe(true);
    expect(wrapper.find('#potential_exposure_country').prop('value')).toEqual('');

    expect(wrapper.find('#continuous_exposure').exists()).toBe(true);
    expect(wrapper.find('#continuous_exposure').hostNodes().prop('checked')).toBe(false);

    expect(wrapper.find('#contact_of_known_case').exists()).toBe(true);
    expect(wrapper.find('#contact_of_known_case').hostNodes().prop('checked')).toBe(false);
    expect(wrapper.find('#contact_of_known_case_id').exists()).toBe(true);
    expect(wrapper.find('#contact_of_known_case_id').hostNodes().prop('value')).toEqual('');

    expect(wrapper.find('#travel_to_affected_country_or_area').exists()).toBe(true);
    expect(wrapper.find('#travel_to_affected_country_or_area').hostNodes().prop('checked')).toBe(false);

    expect(wrapper.find('#was_in_health_care_facility_with_known_cases').exists()).toBe(true);
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases').hostNodes().prop('checked')).toBe(false);
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases_facility_name').exists()).toBe(true);
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases_facility_name').hostNodes().prop('value')).toEqual('');

    expect(wrapper.find('#laboratory_personnel').exists()).toBe(true);
    expect(wrapper.find('#laboratory_personnel').hostNodes().prop('checked')).toBe(false);
    expect(wrapper.find('#laboratory_personnel_facility_name').exists()).toBe(true);
    expect(wrapper.find('#laboratory_personnel_facility_name').hostNodes().prop('value')).toEqual('');

    expect(wrapper.find('#healthcare_personnel').exists()).toBe(true);
    expect(wrapper.find('#healthcare_personnel').hostNodes().prop('checked')).toBe(false);
    expect(wrapper.find('#healthcare_personnel_facility_name').exists()).toBe(true);
    expect(wrapper.find('#healthcare_personnel_facility_name').hostNodes().prop('value')).toEqual('');

    expect(wrapper.find('#crew_on_passenger_or_cargo_flight').exists()).toBe(true);
    expect(wrapper.find('#crew_on_passenger_or_cargo_flight').hostNodes().prop('checked')).toBe(false);

    expect(wrapper.find('#member_of_a_common_exposure_cohort').exists()).toBe(true);
    expect(wrapper.find('#member_of_a_common_exposure_cohort').hostNodes().prop('checked')).toBe(false);
    expect(wrapper.find('#member_of_a_common_exposure_cohort_type').exists()).toBe(true);
    expect(wrapper.find('#member_of_a_common_exposure_cohort_type').hostNodes().prop('value')).toEqual('');

    expect(wrapper.find('#exposure_notes').exists()).toBe(true);
    expect(wrapper.find('#exposure_notes').hostNodes().prop('value')).toEqual('');
    expect(wrapper.find('.character-limit-text').exists()).toBe(true);
    expect(wrapper.find('.character-limit-text').hostNodes().text()).toEqual('2000 characters remaining');
  });

  it('Properly renders exposure information inputs when editing an existing monitoree', () => {
    const wrapper = getMountedWrapper(mockPatient2);
    exposureInputLabels.forEach((label, index) => {
      expect(wrapper.find('label').at(index).text()).toContain(label);
    });

    expect(wrapper.find('#last_date_of_exposure').exists()).toBe(true);
    expect(wrapper.find(DateInput).exists()).toBe(true);
    expect(wrapper.find(DateInput).prop('date')).toEqual(mockPatient2.last_date_of_exposure);

    expect(wrapper.find('#potential_exposure_location').exists()).toBe(true);
    expect(wrapper.find('#potential_exposure_location').prop('value')).toEqual(mockPatient2.potential_exposure_location);

    expect(wrapper.find('#potential_exposure_country').exists()).toBe(true);
    expect(wrapper.find('#potential_exposure_country').prop('value')).toEqual(mockPatient2.potential_exposure_country);

    expect(wrapper.find('#continuous_exposure').exists()).toBe(true);
    expect(wrapper.find('#continuous_exposure').hostNodes().prop('checked')).toBe(mockPatient2.continuous_exposure);

    expect(wrapper.find('#contact_of_known_case').exists()).toBe(true);
    expect(wrapper.find('#contact_of_known_case').hostNodes().prop('checked')).toBe(mockPatient2.contact_of_known_case);
    expect(wrapper.find('#contact_of_known_case_id').exists()).toBe(true);
    expect(wrapper.find('#contact_of_known_case_id').hostNodes().prop('value')).toEqual(mockPatient2.contact_of_known_case_id);

    expect(wrapper.find('#travel_to_affected_country_or_area').exists()).toBe(true);
    expect(wrapper.find('#travel_to_affected_country_or_area').hostNodes().prop('checked')).toBe(mockPatient2.travel_to_affected_country_or_area);

    expect(wrapper.find('#was_in_health_care_facility_with_known_cases').exists()).toBe(true);
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases').hostNodes().prop('checked')).toBe(mockPatient2.was_in_health_care_facility_with_known_cases);
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases_facility_name').exists()).toBe(true);
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases_facility_name').hostNodes().prop('value')).toEqual(mockPatient2.was_in_health_care_facility_with_known_cases_facility_name);

    expect(wrapper.find('#laboratory_personnel').exists()).toBe(true);
    expect(wrapper.find('#laboratory_personnel').hostNodes().prop('checked')).toBe(mockPatient2.laboratory_personnel);
    expect(wrapper.find('#laboratory_personnel_facility_name').exists()).toBe(true);
    expect(wrapper.find('#laboratory_personnel_facility_name').hostNodes().prop('value')).toEqual(mockPatient2.laboratory_personnel_facility_name);

    expect(wrapper.find('#healthcare_personnel').exists()).toBe(true);
    expect(wrapper.find('#healthcare_personnel').hostNodes().prop('checked')).toBe(mockPatient2.healthcare_personnel);
    expect(wrapper.find('#healthcare_personnel_facility_name').exists()).toBe(true);
    expect(wrapper.find('#healthcare_personnel_facility_name').hostNodes().prop('value')).toEqual(mockPatient2.healthcare_personnel_facility_name);

    expect(wrapper.find('#crew_on_passenger_or_cargo_flight').exists()).toBe(true);
    expect(wrapper.find('#crew_on_passenger_or_cargo_flight').hostNodes().prop('checked')).toBe(mockPatient2.crew_on_passenger_or_cargo_flight);

    expect(wrapper.find('#member_of_a_common_exposure_cohort').exists()).toBe(true);
    expect(wrapper.find('#member_of_a_common_exposure_cohort').hostNodes().prop('checked')).toBe(mockPatient2.member_of_a_common_exposure_cohort);
    expect(wrapper.find('#member_of_a_common_exposure_cohort_type').exists()).toBe(true);
    expect(wrapper.find('#member_of_a_common_exposure_cohort_type').hostNodes().prop('value')).toEqual(mockPatient2.member_of_a_common_exposure_cohort_type);

    expect(wrapper.find('#exposure_notes').exists()).toBe(true);
    expect(wrapper.find('#exposure_notes').hostNodes().prop('value')).toEqual(mockPatient2.exposure_notes);
    expect(wrapper.find('.character-limit-text').exists()).toBe(true);
    expect(wrapper.find('.character-limit-text').hostNodes().text()).toEqual(`${2000 - mockPatient2.exposure_notes.length} characters remaining`);
  });

  it('Changing LDE and Continuous Exposure properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getShallowWrapper(blankExposureMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.last_date_of_exposure).toBeNull();
    expect(wrapper.state('current').patient.continuous_exposure).toBe(false);
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find(DateInput).prop('date')).toBeNull();
    expect(wrapper.find('#continuous_exposure').prop('checked')).toBe(false);

    wrapper.find(DateInput).simulate('change', '2021-04-18');
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').patient.last_date_of_exposure).toEqual('2021-04-18');
    expect(wrapper.state('current').patient.continuous_exposure).toBe(false);
    expect(wrapper.state('modified').patient.last_date_of_exposure).toEqual('2021-04-18');
    expect(wrapper.state('current').patient.continuous_exposure).toBe(false);
    expect(wrapper.find(DateInput).prop('date')).toEqual('2021-04-18');
    expect(wrapper.find('#continuous_exposure').prop('checked')).toBe(false);

    wrapper.find('#continuous_exposure').simulate('change', { target: { id: 'continuous_exposure', value: true } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').patient.last_date_of_exposure).toBeNull();
    expect(wrapper.state('current').patient.continuous_exposure).toBe(true);
    expect(wrapper.state('modified').patient.last_date_of_exposure).toBeNull();
    expect(wrapper.state('current').patient.continuous_exposure).toBe(true);
    expect(wrapper.find(DateInput).prop('date')).toBeNull();
    expect(wrapper.find('#continuous_exposure').prop('checked')).toBe(true);

    wrapper.find(DateInput).simulate('change', '2021-07-04');
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(3);
    expect(wrapper.state('current').patient.last_date_of_exposure).toEqual('2021-07-04');
    expect(wrapper.state('current').patient.continuous_exposure).toBe(false);
    expect(wrapper.state('modified').patient.last_date_of_exposure).toEqual('2021-07-04');
    expect(wrapper.state('current').patient.continuous_exposure).toBe(false);
    expect(wrapper.find(DateInput).prop('date')).toEqual('2021-07-04');
    expect(wrapper.find('#continuous_exposure').prop('checked')).toBe(false);

    wrapper.find(DateInput).simulate('change', null);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(4);
    expect(wrapper.state('current').patient.last_date_of_exposure).toBeNull();
    expect(wrapper.state('current').patient.continuous_exposure).toBe(false);
    expect(wrapper.state('modified').patient.last_date_of_exposure).toBeNull();
    expect(wrapper.state('current').patient.continuous_exposure).toBe(false);
    expect(wrapper.find(DateInput).prop('date')).toBeNull();
    expect(wrapper.find('#continuous_exposure').prop('checked')).toBe(false);
  });

  it('Changing Exposure Location properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getMountedWrapper(blankExposureMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.exposure_notes).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#potential_exposure_location').prop('value')).toEqual('');

    let location = 'Diagon Alley';
    wrapper.find('#potential_exposure_location').simulate('change', { target: { id: 'potential_exposure_location', value: location } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').patient.potential_exposure_location).toEqual(location);
    expect(wrapper.state('modified').patient.potential_exposure_location).toEqual(location);
    expect(wrapper.find('#potential_exposure_location').prop('value')).toEqual(location);

    location = 'Hogsmeade';
    wrapper.find('#potential_exposure_location').simulate('change', { target: { id: 'potential_exposure_location', value: location } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').patient.potential_exposure_location).toEqual(location);
    expect(wrapper.state('modified').patient.potential_exposure_location).toEqual(location);
    expect(wrapper.find('#potential_exposure_location').prop('value')).toEqual(location);

    location = '';
    wrapper.find('#potential_exposure_location').simulate('change', { target: { id: 'potential_exposure_location', value: location } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(3);
    expect(wrapper.state('current').patient.potential_exposure_location).toEqual(location);
    expect(wrapper.state('modified').patient.potential_exposure_location).toEqual(location);
    expect(wrapper.find('#potential_exposure_location').prop('value')).toEqual(location);
  });

  it('Changing Exposure Country properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getMountedWrapper(blankExposureMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.exposure_notes).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#potential_exposure_country').prop('value')).toEqual('');

    let country = 'Canada';
    wrapper.find('#potential_exposure_country').simulate('change', { target: { id: 'potential_exposure_country', value: country } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').patient.potential_exposure_country).toEqual(country);
    expect(wrapper.state('modified').patient.potential_exposure_country).toEqual(country);
    expect(wrapper.find('#potential_exposure_country').prop('value')).toEqual(country);

    country = 'South Africa';
    wrapper.find('#potential_exposure_country').simulate('change', { target: { id: 'potential_exposure_country', value: country } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').patient.potential_exposure_country).toEqual(country);
    expect(wrapper.state('modified').patient.potential_exposure_country).toEqual(country);
    expect(wrapper.find('#potential_exposure_country').prop('value')).toEqual(country);

    country = '';
    wrapper.find('#potential_exposure_country').simulate('change', { target: { id: 'potential_exposure_country', value: country } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(3);
    expect(wrapper.state('current').patient.potential_exposure_country).toEqual(country);
    expect(wrapper.state('modified').patient.potential_exposure_country).toEqual(country);
    expect(wrapper.find('#potential_exposure_country').prop('value')).toEqual(country);
  });

  it('Changing Risk Factor: "Close Contact with Known Case" properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getShallowWrapper(blankExposureMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.contact_of_known_case).toBe(false);
    expect(wrapper.state('current').patient.contact_of_known_case_id).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#contact_of_known_case').prop('checked')).toBe(false);
    expect(wrapper.find('#contact_of_known_case_id').prop('value')).toEqual('');

    wrapper.find('#contact_of_known_case').simulate('change', { target: { id: 'contact_of_known_case', value: true } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').patient.contact_of_known_case).toBe(true);
    expect(wrapper.state('current').patient.contact_of_known_case_id).toBeNull();
    expect(wrapper.state('modified').patient.contact_of_known_case).toBe(true);
    expect(wrapper.state('modified').patient.contact_of_known_case_id).toBeUndefined();
    expect(wrapper.find('#contact_of_known_case').prop('checked')).toBe(true);
    expect(wrapper.find('#contact_of_known_case_id').prop('value')).toEqual('');

    wrapper.find('#contact_of_known_case_id').simulate('change', { target: { id: 'contact_of_known_case_id', value: '123' } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').patient.contact_of_known_case).toBe(true);
    expect(wrapper.state('current').patient.contact_of_known_case_id).toEqual('123');
    expect(wrapper.state('modified').patient.contact_of_known_case).toBe(true);
    expect(wrapper.state('modified').patient.contact_of_known_case_id).toEqual('123');
    expect(wrapper.find('#contact_of_known_case').prop('checked')).toBe(true);
    expect(wrapper.find('#contact_of_known_case_id').prop('value')).toEqual('123');

    wrapper.find('#contact_of_known_case').simulate('change', { target: { id: 'contact_of_known_case', value: false } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(3);
    expect(wrapper.state('current').patient.contact_of_known_case).toBe(false);
    expect(wrapper.state('current').patient.contact_of_known_case_id).toEqual('123');
    expect(wrapper.state('modified').patient.contact_of_known_case).toBe(false);
    expect(wrapper.state('modified').patient.contact_of_known_case_id).toEqual('123');
    expect(wrapper.find('#contact_of_known_case').prop('checked')).toBe(false);
    expect(wrapper.find('#contact_of_known_case_id').prop('value')).toEqual('123');

    wrapper.find('#contact_of_known_case_id').simulate('change', { target: { id: 'contact_of_known_case_id', value: '' } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(4);
    expect(wrapper.state('current').patient.contact_of_known_case).toBe(false);
    expect(wrapper.state('current').patient.contact_of_known_case_id).toEqual('');
    expect(wrapper.state('modified').patient.contact_of_known_case).toBe(false);
    expect(wrapper.state('modified').patient.contact_of_known_case_id).toEqual('');
    expect(wrapper.find('#contact_of_known_case').prop('checked')).toBe(false);
    expect(wrapper.find('#contact_of_known_case_id').prop('value')).toEqual('');
  });

  it('Changing Risk Factor: "Travel to Affected Country or Area" properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getShallowWrapper(blankExposureMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.travel_to_affected_country_or_area).toBe(false);
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#travel_to_affected_country_or_area').prop('checked')).toBe(false);

    wrapper.find('#travel_to_affected_country_or_area').simulate('change', { target: { id: 'travel_to_affected_country_or_area', value: true } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').patient.travel_to_affected_country_or_area).toBe(true);
    expect(wrapper.state('modified').patient.travel_to_affected_country_or_area).toBe(true);
    expect(wrapper.find('#travel_to_affected_country_or_area').prop('checked')).toBe(true);

    wrapper.find('#travel_to_affected_country_or_area').simulate('change', { target: { id: 'travel_to_affected_country_or_area', value: false } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').patient.travel_to_affected_country_or_area).toBe(false);
    expect(wrapper.state('modified').patient.travel_to_affected_country_or_area).toBe(false);
    expect(wrapper.find('#travel_to_affected_country_or_area').prop('checked')).toBe(false);
  });

  it('Changing Risk Factor: "Was in Healthcare Facility with Known Cases" properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getShallowWrapper(blankExposureMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.was_in_health_care_facility_with_known_cases).toBe(false);
    expect(wrapper.state('current').patient.was_in_health_care_facility_with_known_cases_facility_name).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases').prop('checked')).toBe(false);
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases_facility_name').prop('value')).toEqual('');

    wrapper.find('#was_in_health_care_facility_with_known_cases').simulate('change', { target: { id: 'was_in_health_care_facility_with_known_cases', value: true } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').patient.was_in_health_care_facility_with_known_cases).toBe(true);
    expect(wrapper.state('current').patient.was_in_health_care_facility_with_known_cases_facility_name).toBeNull();
    expect(wrapper.state('modified').patient.was_in_health_care_facility_with_known_cases).toBe(true);
    expect(wrapper.state('modified').patient.was_in_health_care_facility_with_known_cases_facility_name).toBeUndefined();
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases').prop('checked')).toBe(true);
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases_facility_name').prop('value')).toEqual('');

    wrapper.find('#was_in_health_care_facility_with_known_cases_facility_name').simulate('change', { target: { id: 'was_in_health_care_facility_with_known_cases_facility_name', value: '123' } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').patient.was_in_health_care_facility_with_known_cases).toBe(true);
    expect(wrapper.state('current').patient.was_in_health_care_facility_with_known_cases_facility_name).toEqual('123');
    expect(wrapper.state('modified').patient.was_in_health_care_facility_with_known_cases).toBe(true);
    expect(wrapper.state('modified').patient.was_in_health_care_facility_with_known_cases_facility_name).toEqual('123');
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases').prop('checked')).toBe(true);
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases_facility_name').prop('value')).toEqual('123');

    wrapper.find('#was_in_health_care_facility_with_known_cases').simulate('change', { target: { id: 'was_in_health_care_facility_with_known_cases', value: false } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(3);
    expect(wrapper.state('current').patient.was_in_health_care_facility_with_known_cases).toBe(false);
    expect(wrapper.state('current').patient.was_in_health_care_facility_with_known_cases_facility_name).toEqual('123');
    expect(wrapper.state('modified').patient.was_in_health_care_facility_with_known_cases).toBe(false);
    expect(wrapper.state('modified').patient.was_in_health_care_facility_with_known_cases_facility_name).toEqual('123');
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases').prop('checked')).toBe(false);
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases_facility_name').prop('value')).toEqual('123');

    wrapper.find('#was_in_health_care_facility_with_known_cases_facility_name').simulate('change', { target: { id: 'was_in_health_care_facility_with_known_cases_facility_name', value: '' } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(4);
    expect(wrapper.state('current').patient.was_in_health_care_facility_with_known_cases).toBe(false);
    expect(wrapper.state('current').patient.was_in_health_care_facility_with_known_cases_facility_name).toEqual('');
    expect(wrapper.state('modified').patient.was_in_health_care_facility_with_known_cases).toBe(false);
    expect(wrapper.state('modified').patient.was_in_health_care_facility_with_known_cases_facility_name).toEqual('');
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases').prop('checked')).toBe(false);
    expect(wrapper.find('#was_in_health_care_facility_with_known_cases_facility_name').prop('value')).toEqual('');
  });

  it('Changing Risk Factor: "Laboratory Personnel" properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getShallowWrapper(blankExposureMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.laboratory_personnel).toBe(false);
    expect(wrapper.state('current').patient.laboratory_personnel_facility_name).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#laboratory_personnel').prop('checked')).toBe(false);
    expect(wrapper.find('#laboratory_personnel_facility_name').prop('value')).toEqual('');

    wrapper.find('#laboratory_personnel').simulate('change', { target: { id: 'laboratory_personnel', value: true } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').patient.laboratory_personnel).toBe(true);
    expect(wrapper.state('current').patient.laboratory_personnel_facility_name).toBeNull();
    expect(wrapper.state('modified').patient.laboratory_personnel).toBe(true);
    expect(wrapper.state('modified').patient.laboratory_personnel_facility_name).toBeUndefined();
    expect(wrapper.find('#laboratory_personnel').prop('checked')).toBe(true);
    expect(wrapper.find('#laboratory_personnel_facility_name').prop('value')).toEqual('');

    wrapper.find('#laboratory_personnel_facility_name').simulate('change', { target: { id: 'laboratory_personnel_facility_name', value: 'MGH' } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').patient.laboratory_personnel).toBe(true);
    expect(wrapper.state('current').patient.laboratory_personnel_facility_name).toEqual('MGH');
    expect(wrapper.state('modified').patient.laboratory_personnel).toBe(true);
    expect(wrapper.state('modified').patient.laboratory_personnel_facility_name).toEqual('MGH');
    expect(wrapper.find('#laboratory_personnel').prop('checked')).toBe(true);
    expect(wrapper.find('#laboratory_personnel_facility_name').prop('value')).toEqual('MGH');

    wrapper.find('#laboratory_personnel').simulate('change', { target: { id: 'laboratory_personnel', value: false } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(3);
    expect(wrapper.state('current').patient.laboratory_personnel).toBe(false);
    expect(wrapper.state('current').patient.laboratory_personnel_facility_name).toEqual('MGH');
    expect(wrapper.state('modified').patient.laboratory_personnel).toBe(false);
    expect(wrapper.state('modified').patient.laboratory_personnel_facility_name).toEqual('MGH');
    expect(wrapper.find('#laboratory_personnel').prop('checked')).toBe(false);
    expect(wrapper.find('#laboratory_personnel_facility_name').prop('value')).toEqual('MGH');

    wrapper.find('#laboratory_personnel_facility_name').simulate('change', { target: { id: 'laboratory_personnel_facility_name', value: '' } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(4);
    expect(wrapper.state('current').patient.laboratory_personnel).toBe(false);
    expect(wrapper.state('current').patient.laboratory_personnel_facility_name).toEqual('');
    expect(wrapper.state('modified').patient.laboratory_personnel).toBe(false);
    expect(wrapper.state('modified').patient.laboratory_personnel_facility_name).toEqual('');
    expect(wrapper.find('#laboratory_personnel').prop('checked')).toBe(false);
    expect(wrapper.find('#laboratory_personnel_facility_name').prop('value')).toEqual('');
  });

  it('Changing Risk Factor: "Healthcare Personnel" properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getShallowWrapper(blankExposureMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.healthcare_personnel).toBe(false);
    expect(wrapper.state('current').patient.healthcare_personnel_facility_name).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#healthcare_personnel').prop('checked')).toBe(false);
    expect(wrapper.find('#healthcare_personnel_facility_name').prop('value')).toEqual('');

    wrapper.find('#healthcare_personnel').simulate('change', { target: { id: 'healthcare_personnel', value: true } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').patient.healthcare_personnel).toBe(true);
    expect(wrapper.state('current').patient.healthcare_personnel_facility_name).toBeNull();
    expect(wrapper.state('modified').patient.healthcare_personnel).toBe(true);
    expect(wrapper.state('modified').patient.healthcare_personnel_facility_name).toBeUndefined();
    expect(wrapper.find('#healthcare_personnel').prop('checked')).toBe(true);
    expect(wrapper.find('#healthcare_personnel_facility_name').prop('value')).toEqual('');

    wrapper.find('#healthcare_personnel_facility_name').simulate('change', { target: { id: 'healthcare_personnel_facility_name', value: 'MGH' } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').patient.healthcare_personnel).toBe(true);
    expect(wrapper.state('current').patient.healthcare_personnel_facility_name).toEqual('MGH');
    expect(wrapper.state('modified').patient.healthcare_personnel).toBe(true);
    expect(wrapper.state('modified').patient.healthcare_personnel_facility_name).toEqual('MGH');
    expect(wrapper.find('#healthcare_personnel').prop('checked')).toBe(true);
    expect(wrapper.find('#healthcare_personnel_facility_name').prop('value')).toEqual('MGH');

    wrapper.find('#healthcare_personnel').simulate('change', { target: { id: 'healthcare_personnel', value: false } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(3);
    expect(wrapper.state('current').patient.healthcare_personnel).toBe(false);
    expect(wrapper.state('current').patient.healthcare_personnel_facility_name).toEqual('MGH');
    expect(wrapper.state('modified').patient.healthcare_personnel).toBe(false);
    expect(wrapper.state('modified').patient.healthcare_personnel_facility_name).toEqual('MGH');
    expect(wrapper.find('#healthcare_personnel').prop('checked')).toBe(false);
    expect(wrapper.find('#healthcare_personnel_facility_name').prop('value')).toEqual('MGH');

    wrapper.find('#healthcare_personnel_facility_name').simulate('change', { target: { id: 'healthcare_personnel_facility_name', value: '' } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(4);
    expect(wrapper.state('current').patient.healthcare_personnel).toBe(false);
    expect(wrapper.state('current').patient.healthcare_personnel_facility_name).toEqual('');
    expect(wrapper.state('modified').patient.healthcare_personnel).toBe(false);
    expect(wrapper.state('modified').patient.healthcare_personnel_facility_name).toEqual('');
    expect(wrapper.find('#healthcare_personnel').prop('checked')).toBe(false);
    expect(wrapper.find('#healthcare_personnel_facility_name').prop('value')).toEqual('');
  });

  it('Changing Risk Factor: "Crew on Passenger or Cargo Flight" properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getShallowWrapper(blankExposureMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.crew_on_passenger_or_cargo_flight).toBe(false);
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#crew_on_passenger_or_cargo_flight').prop('checked')).toBe(false);

    wrapper.find('#crew_on_passenger_or_cargo_flight').simulate('change', { target: { id: 'crew_on_passenger_or_cargo_flight', value: true } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').patient.crew_on_passenger_or_cargo_flight).toBe(true);
    expect(wrapper.state('modified').patient.crew_on_passenger_or_cargo_flight).toBe(true);
    expect(wrapper.find('#crew_on_passenger_or_cargo_flight').prop('checked')).toBe(true);

    wrapper.find('#crew_on_passenger_or_cargo_flight').simulate('change', { target: { id: 'crew_on_passenger_or_cargo_flight', value: false } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').patient.crew_on_passenger_or_cargo_flight).toBe(false);
    expect(wrapper.state('modified').patient.crew_on_passenger_or_cargo_flight).toBe(false);
    expect(wrapper.find('#crew_on_passenger_or_cargo_flight').prop('checked')).toBe(false);
  });

  it('Changing Risk Factor: "Member of Common Exposure Cohort" properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getShallowWrapper(blankExposureMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.member_of_a_common_exposure_cohort).toBe(false);
    expect(wrapper.state('current').patient.member_of_a_common_exposure_cohort_type).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#member_of_a_common_exposure_cohort').prop('checked')).toBe(false);
    expect(wrapper.find('#member_of_a_common_exposure_cohort_type').prop('value')).toEqual('');

    wrapper.find('#member_of_a_common_exposure_cohort').simulate('change', { target: { id: 'member_of_a_common_exposure_cohort', value: true } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').patient.member_of_a_common_exposure_cohort).toBe(true);
    expect(wrapper.state('current').patient.member_of_a_common_exposure_cohort_type).toBeNull();
    expect(wrapper.state('modified').patient.member_of_a_common_exposure_cohort).toBe(true);
    expect(wrapper.state('modified').patient.member_of_a_common_exposure_cohort_type).toBeUndefined();
    expect(wrapper.find('#member_of_a_common_exposure_cohort').prop('checked')).toBe(true);
    expect(wrapper.find('#member_of_a_common_exposure_cohort_type').prop('value')).toEqual('');

    wrapper.find('#member_of_a_common_exposure_cohort_type').simulate('change', { target: { id: 'member_of_a_common_exposure_cohort_type', value: 'some type' } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').patient.member_of_a_common_exposure_cohort).toBe(true);
    expect(wrapper.state('current').patient.member_of_a_common_exposure_cohort_type).toEqual('some type');
    expect(wrapper.state('modified').patient.member_of_a_common_exposure_cohort).toBe(true);
    expect(wrapper.state('modified').patient.member_of_a_common_exposure_cohort_type).toEqual('some type');
    expect(wrapper.find('#member_of_a_common_exposure_cohort').prop('checked')).toBe(true);
    expect(wrapper.find('#member_of_a_common_exposure_cohort_type').prop('value')).toEqual('some type');

    wrapper.find('#member_of_a_common_exposure_cohort').simulate('change', { target: { id: 'member_of_a_common_exposure_cohort', value: false } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(3);
    expect(wrapper.state('current').patient.member_of_a_common_exposure_cohort).toBe(false);
    expect(wrapper.state('current').patient.member_of_a_common_exposure_cohort_type).toEqual('some type');
    expect(wrapper.state('modified').patient.member_of_a_common_exposure_cohort).toBe(false);
    expect(wrapper.state('modified').patient.member_of_a_common_exposure_cohort_type).toEqual('some type');
    expect(wrapper.find('#member_of_a_common_exposure_cohort').prop('checked')).toBe(false);
    expect(wrapper.find('#member_of_a_common_exposure_cohort_type').prop('value')).toEqual('some type');

    wrapper.find('#member_of_a_common_exposure_cohort_type').simulate('change', { target: { id: 'member_of_a_common_exposure_cohort_type', value: '' } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(4);
    expect(wrapper.state('current').patient.member_of_a_common_exposure_cohort).toBe(false);
    expect(wrapper.state('current').patient.member_of_a_common_exposure_cohort_type).toEqual('');
    expect(wrapper.state('modified').patient.member_of_a_common_exposure_cohort).toBe(false);
    expect(wrapper.state('modified').patient.member_of_a_common_exposure_cohort_type).toEqual('');
    expect(wrapper.find('#member_of_a_common_exposure_cohort').prop('checked')).toBe(false);
    expect(wrapper.find('#member_of_a_common_exposure_cohort_type').prop('value')).toEqual('');
  });

  it('Changing Notes properly updates state and calls props.setEnrollmentState', () => {
    const wrapper = getMountedWrapper(blankExposureMockPatient);
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(0);
    expect(wrapper.state('current').patient.exposure_notes).toBeNull();
    expect(wrapper.state('modified')).toEqual({});
    expect(wrapper.find('#exposure_notes').prop('value')).toEqual('');
    expect(wrapper.find('.character-limit-text').text()).toEqual('2000 characters remaining');

    let note = 'I am a note';
    wrapper.find('#exposure_notes').simulate('change', { target: { id: 'exposure_notes', value: note } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(1);
    expect(wrapper.state('current').patient.exposure_notes).toEqual(note);
    expect(wrapper.state('modified').patient.exposure_notes).toEqual(note);
    expect(wrapper.find('#exposure_notes').prop('value')).toEqual(note);
    expect(wrapper.find('.character-limit-text').text()).toEqual(`${2000 - note.length} characters remaining`);

    note = 'I am a different note';
    wrapper.find('#exposure_notes').simulate('change', { target: { id: 'exposure_notes', value: note } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(2);
    expect(wrapper.state('current').patient.exposure_notes).toEqual(note);
    expect(wrapper.state('modified').patient.exposure_notes).toEqual(note);
    expect(wrapper.find('#exposure_notes').prop('value')).toEqual(note);
    expect(wrapper.find('.character-limit-text').text()).toEqual(`${2000 - note.length} characters remaining`);

    note = '';
    wrapper.find('#exposure_notes').simulate('change', { target: { id: 'exposure_notes', value: note } });
    expect(setEnrollmentStateMock).toHaveBeenCalledTimes(3);
    expect(wrapper.state('current').patient.exposure_notes).toEqual(note);
    expect(wrapper.state('modified').patient.exposure_notes).toEqual(note);
    expect(wrapper.find('#exposure_notes').prop('value')).toEqual(note);
    expect(wrapper.find('.character-limit-text').text()).toEqual(`${2000 - note.length} characters remaining`);
  });

  it('Hides "Previous" and "Next" buttons if requisite functions are not passed in via props', () => {
    const wrapper = shallow(<ExposureInformation currentState={{ isolation: false, patient: blankExposureMockPatient, propagatedFields: {} }} patient={blankIsolationMockPatient} showPreviousButton={false} jurisdiction_paths={mockJurisdictionPaths} />);
    expect(wrapper.find(Button).length).toEqual(0);
  });

  it('Hides the "Previous" button when props.showPreviousButton is false', () => {
    const wrapper = getShallowWrapper(blankIsolationMockPatient);
    expect(wrapper.find(Button).length).toEqual(1);
    expect(wrapper.find(Button).at(0).text()).toEqual('Next');
  });

  it('Clicking the "Previous" button calls props.previous', () => {
    const wrapper = getShallowWrapper(blankIsolationMockPatient, true);
    expect(previousMock).not.toHaveBeenCalled();
    wrapper.find(Button).at(0).simulate('click');
    expect(previousMock).toHaveBeenCalled();
  });

  it('Clicking the "Next" button calls validate method', () => {
    const wrapper = getShallowWrapper(blankIsolationMockPatient);
    const validateSpy = jest.spyOn(wrapper.instance(), 'validate');
    expect(validateSpy).not.toHaveBeenCalled();
    wrapper.find(Button).simulate('click');
    expect(validateSpy).toHaveBeenCalled();
  });
});
