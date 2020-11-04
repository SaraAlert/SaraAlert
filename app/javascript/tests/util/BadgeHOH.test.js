import React from 'react'
import { shallow } from 'enzyme';
import { Badge } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';
import BadgeHOH from '../../components/util/BadgeHOH.js'

describe('BadgeHOH', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<BadgeHOH patientId={'1'} location={'right'} />);

    expect(wrapper.find(Badge).exists()).toBeTruthy();
    expect(wrapper.find(Badge).text()).toEqual('HoH');
    expect(wrapper.find(ReactTooltip).exists()).toBeTruthy();
    expect(wrapper.find(ReactTooltip).find('span').text()).toEqual('Monitoree is Head of Household that reports on behalf of household members');
  });
});
