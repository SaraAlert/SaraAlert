import React from 'react';
import { shallow } from 'enzyme';
import { Row } from 'react-bootstrap';
import Dependent from '../../../components/patient/household/Dependent';
import RemoveFromHousehold from '../../../components/patient/household/actions/RemoveFromHousehold';
import { mockPatient1, mockPatient2 } from '../../mocks/mockPatients';
import { nameFormatter } from '../../util.js'

const authyToken = "Q1z4yZXLdN+tZod6dBSIlMbZ3yWAUFdY44U06QWffEP76nx1WGMHIz8rYxEUZsl9sspS3ePF2ZNmSue8wFpJGg==";

describe('Dependent', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<Dependent patient={mockPatient2} hoh={mockPatient1} authenticity_token={authyToken} />);
    expect(wrapper.find(Row).length).toEqual(2);
    expect(wrapper.find(Row).at(0).text().includes('The reporting responsibility for this monitoree is handled by')).toBeTruthy();
    expect(wrapper.find('a').exists()).toBeTruthy();
    expect(wrapper.find('a').text()).toEqual(nameFormatter(mockPatient1));
    expect(wrapper.find('a').prop('href').includes(`/patients/${mockPatient2.responder_id}`)).toBeTruthy();
    expect(wrapper.find(RemoveFromHousehold).exists()).toBeTruthy();
  });

  it('Properly renders all main components if HoH is not defined', () => {
    const wrapper = shallow(<Dependent patient={mockPatient2} authenticity_token={authyToken} />);
    expect(wrapper.find(Row).length).toEqual(2);
    expect(wrapper.find(Row).at(0).text().includes('The reporting responsibility for this monitoree is handled by')).toBeTruthy();
    expect(wrapper.find('a').exists()).toBeTruthy();
    expect(wrapper.find('a').text()).toEqual('this monitoree');
    expect(wrapper.find('a').prop('href').includes(`/patients/${mockPatient2.responder_id}`)).toBeTruthy();
    expect(wrapper.find(RemoveFromHousehold).exists()).toBeTruthy();
  });
});
