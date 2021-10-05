import React from 'react';
import { shallow } from 'enzyme';
import { Text } from 'recharts';
import CustomizedAxisTick from '../../../components/analytics/display/CustomizedAxisTick';

const payload = { coordinate: 123, index: 4, offset: 32.1, value: 'some value' };

describe('CustomizedAxisTick', () => {
  it('Properly renders all main components', () => {
    const wrapper = shallow(<CustomizedAxisTick x={0} y={0} payload={payload} />);
    expect(wrapper.find(Text).exists()).toBe(true);
  });
});
