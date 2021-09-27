import React from 'react';
import { shallow } from 'enzyme';
import ReactTooltip from 'react-tooltip';
import IconMinor from '../../../components/patient/icons/IconMinor';

describe('IconMinor', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<IconMinor patientId={'1'} />);
    expect(wrapper.find('i').exists()).toBe(true);
    expect(wrapper.find('i').hasClass('fa-child')).toBe(true);
    expect(wrapper.find(ReactTooltip).exists()).toBe(true);
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual('Monitoree is a minor');
  });
});
