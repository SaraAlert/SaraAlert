import React from 'react';
import { shallow } from 'enzyme';
import Viewers from '../../components/patient/Viewers';
import { Alert } from 'react-bootstrap';

function getWrapper(viewers) {
  return shallow(<Viewers patient_id={1} viewers={viewers} />);
}

describe('Viewers', () => {
  it('Properly renders a list of multiple viewers', () => {
    const wrapper = getWrapper(["1@example.com", "2@example.com"]);
    expect(wrapper.find(Alert).exists()).toBeTruthy();
    expect(wrapper.find('#multiple-warning').text()).toEqual('Multiple users currently have this monitoree record open: 1@example.com, 2@example.com');
  });

  it('Properly renders a list of a single viewer', () => {
    const wrapper = getWrapper(["0@example.com"]);
    expect(wrapper.find(Alert).exists()).toBeTruthy();
    expect(wrapper.find('#multiple-warning').text()).toEqual('Another user currently have this monitoree record open: 0@example.com');
  });

  it('Properly renders a list of an empty list of viewers', () => {
    const wrapper = getWrapper([]);
    expect(wrapper.find(Alert).exists()).toBeFalsy();
  });
});
