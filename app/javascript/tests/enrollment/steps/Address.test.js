import React from 'react'
import { shallow, mount } from 'enzyme';
import Address from '../../../components/enrollment/steps/Address.js'
import { blankMockPatient, mockPatient1 } from '../../mocks/mockPatients'

const newEnrollmentState = {
  isolation: false,
  patient: blankMockPatient,
  propagatedFields: {}
}

const requiredStrings = [
  'ADDRESS 1 *',
  'TOWN/CITY *',
  'STATE *',
  'ADDRESS 2',
  'ZIP *',
  'COUNTY (DISTRICT)',
  'ADDRESS 1',
  'TOWN/CITY',
  'STATE',
  'ADDRESS 2',
  'ZIP',
  'COUNTY (DISTRICT)',
]

describe('Address', () => {
  it('Properly renders all main components', () => {
    const wrapper = mount(<Address goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} />);
    requiredStrings.forEach(requiredString => {
      expect(wrapper.text().includes(requiredString)).toBe(true);
    })
  });

  it('Properly shows the `Next` button', () => {
    const wrapper = shallow(<Address goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} />);
    const button = wrapper.find('.btn-square')
    expect(button.at(0).text()).toEqual('Copy from Home Address');
    expect(button.at(1).text()).toEqual('Next');
  });

  it('Properly allows setting of the main address', () => {
    const wrapper = mount(<Address goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} />);
    expect(wrapper.find('#address_line_1').instance().value).toEqual('')
    expect(wrapper.find('#address_city').instance().value).toEqual('')
    expect(wrapper.find('#address_state').instance().value).toEqual('')
    expect(wrapper.find('#address_line_2').instance().value).toEqual('')
    expect(wrapper.find('#address_zip').instance().value).toEqual('')
    expect(wrapper.find('#address_county').instance().value).toEqual('')
    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1 } }, () => {
      expect(wrapper.find('#address_line_1').instance().value).toEqual(mockPatient1.address_line_1)
      expect(wrapper.find('#address_city').instance().value).toEqual(mockPatient1.address_city)
      expect(wrapper.find('#address_state').instance().value).toEqual(mockPatient1.address_state)
      expect(wrapper.find('#address_line_2').instance().value).toEqual(mockPatient1.address_line_2 || "")
      expect(wrapper.find('#address_zip').instance().value).toEqual(mockPatient1.address_zip)
      expect(wrapper.find('#address_county').instance().value).toEqual(mockPatient1.address_county)
    });
  });

  it('Properly allows copying of the main address to secondary address', () => {
    const wrapper = shallow(<Address goto={() => {}} next={() => {}} setEnrollmentState={() => {}} currentState={newEnrollmentState} />);

    wrapper.setState({ current: { ...wrapper.state.current, patient: mockPatient1 } }, () => {
      expect(wrapper.state().current.patient.monitored_address_line_1).not.toEqual(mockPatient1.address_line_1)
      expect(wrapper.state().current.patient.monitored_address_city).not.toEqual(mockPatient1.address_city)
      expect(wrapper.state().current.patient.monitored_address_state).not.toEqual(mockPatient1.address_state)
      expect(wrapper.state().current.patient.monitored_address_line_2).not.toEqual(mockPatient1.address_line_2)
      expect(wrapper.state().current.patient.monitored_address_zip).not.toEqual(mockPatient1.address_zip)
      expect(wrapper.state().current.patient.monitored_address_county).not.toEqual(mockPatient1.address_county)
      wrapper.find('#copy_home_address').simulate('click')
      expect(wrapper.state().current.patient.monitored_address_line_1).toEqual(mockPatient1.address_line_1)
      expect(wrapper.state().current.patient.monitored_address_city).toEqual(mockPatient1.address_city)
      expect(wrapper.state().current.patient.monitored_address_state).toEqual(mockPatient1.address_state)
      expect(wrapper.state().current.patient.monitored_address_line_2).toEqual(mockPatient1.address_line_2)
      expect(wrapper.state().current.patient.monitored_address_zip).toEqual(mockPatient1.address_zip)
      expect(wrapper.state().current.patient.monitored_address_county).toEqual(mockPatient1.address_county)
    })
  });

});
