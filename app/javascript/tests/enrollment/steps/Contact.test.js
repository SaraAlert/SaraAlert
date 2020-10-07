import React from 'react'
import { shallow, mount } from 'enzyme';
import Contact from '../../../components/enrollment/steps/Contact.js'
import { blankMockPatient, mockPatient1, mockPatient2 } from '../../mocks/mockPatients'

const newEnrollmentState = {
  isolation: false,
  patient: blankMockPatient,
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

describe('Contact', () => {
  it('Properly renders all main components', () => {
    const wrapper = mount(<Contact goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} />);
    requiredStrings.forEach(requiredString => {
      expect(wrapper.text().includes(requiredString)).toBe(true);
    })
  });

  it('Properly allows changing of the preferred Contact Method', () => {
    const wrapper = mount(<Contact goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} />);
    let newPatient = mockPatient2
    const preferredContactMethods = [ 'Unknown', 'E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message', 'Opt-out']
    preferredContactMethods.forEach(method => {
      newPatient.preferred_contact_method = method
      wrapper.setState({ current: { ...wrapper.state.current, patient: newPatient } }, () => {
        expect(wrapper.find('#preferred_contact_method').instance().value).toEqual(method)
      })
    })
  })

  it('Properly allows changing of the primary_telephone', () => {
    const wrapper = mount(<Contact goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} />);
    expect(wrapper.find('#primary_telephone').at(2).instance().value).toEqual('')
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1 } }, () => {
      expect(wrapper.find('#primary_telephone').at(2).instance().value).toEqual(mockPatient1.primary_telephone || '')
    })
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient2 } }, () => {
      expect(wrapper.find('#primary_telephone').at(2).instance().value).toEqual(mockPatient2.primary_telephone || '')
    })
  })

  it('Properly allows changing of the primary_telephone_type', () => {
    const wrapper = mount(<Contact goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} />);
    expect(wrapper.find('#primary_telephone_type').instance().value).toEqual('')
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1 } }, () => {
      expect(wrapper.find('#primary_telephone_type').instance().value).toEqual(mockPatient1.primary_telephone_type || '')
    })
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient2 } }, () => {
      expect(wrapper.find('#primary_telephone_type').instance().value).toEqual(mockPatient2.primary_telephone_type || '')
    })
  })

  it('Properly allows changing of the secondary_telephone', () => {
    const wrapper = mount(<Contact goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} />);
    expect(wrapper.find('#secondary_telephone').at(2).instance().value).toEqual('')
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1 } }, () => {
      expect(wrapper.find('#secondary_telephone').at(2).instance().value).toEqual(mockPatient1.secondary_telephone || '')
    })
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient2 } }, () => {
      expect(wrapper.find('#secondary_telephone').at(2).instance().value).toEqual(mockPatient2.secondary_telephone || '')
    })
  })

  it('Properly allows changing of the secondary_telephone_type', () => {
    const wrapper = mount(<Contact goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} />);
    expect(wrapper.find('#secondary_telephone_type').instance().value).toEqual('')
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1 } }, () => {
      expect(wrapper.find('#secondary_telephone_type').instance().value).toEqual(mockPatient1.secondary_telephone_type || '')
    })
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient2 } }, () => {
      expect(wrapper.find('#secondary_telephone_type').instance().value).toEqual(mockPatient2.secondary_telephone_type || '')
    })
  })

  it('Properly allows changing of the email', () => {
    const wrapper = mount(<Contact goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} />);
    expect(wrapper.find('#email').instance().value).toEqual('')
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1 } }, () => {
      expect(wrapper.find('#email').instance().value).toEqual(mockPatient1.email)
    })
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient2 } }, () => {
      expect(wrapper.find('#email').instance().value).toEqual(mockPatient2.email)
    })
  })

});
