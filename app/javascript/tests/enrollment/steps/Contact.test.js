import React from 'react'
import { shallow, mount } from 'enzyme';
import Contact from '../../../components/enrollment/steps/Contact.js'
import { mockPatient1, mockPatient2 } from '../../mocks/mockPatients'

const newEnrollmentState = {
  isolation: false,
  patient: {},
  propagatedFields: {}
}

const requiredStrings = [
  'PRIMARY TELEPHONE NUMBER',
  'SECONDARY TELEPHONE NUMBER',
  'PRIMARY PHONE TYPE',
  'SECONDARY PHONE TYPE',
  'E-MAIL ADDRESS',
  'CONFIRM E-MAIL ADDRESS'
]

describe('Monitoree Contact', () => {
  it('Properly renders all main components', () => {
    const wrapper = mount(<Contact goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} />);
    requiredStrings.forEach(requiredString => {
      expect(wrapper.text().includes(requiredString)).toBe(true);
    })
  });

  it('Properly allows setting of all Contact information', () => {
    const wrapper = mount(<Contact goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} />);
    expect(wrapper.find('#preferred_contact_method').instance().value).toEqual("Unknown")
    expect(wrapper.find('#primary_telephone').at(0).instance().value).toBeFalsy()
    expect(wrapper.find('#primary_telephone_type').instance().value).toBeFalsy()
    expect(wrapper.find('#secondary_telephone').at(0).instance().value).toBeFalsy()
    expect(wrapper.find('#secondary_telephone_type').instance().value).toBeFalsy()
    expect(wrapper.find('#email').instance().value).toBeFalsy()
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1 } }, () => {
      expect(wrapper.find('#preferred_contact_method').instance().value).toEqual(mockPatient1.preferred_contact_method)
      expect(wrapper.find('#primary_telephone').at(0).instance().value).toBeUndefined()
      expect(wrapper.find('#primary_telephone_type').instance().value).toBeFalsy()
      expect(wrapper.find('#secondary_telephone').at(0).instance().value).toBeUndefined()
      expect(wrapper.find('#secondary_telephone_type').instance().value).toBeFalsy()
      expect(wrapper.find('#email').instance().value).toEqual(mockPatient1.email)
    })
  });

});
