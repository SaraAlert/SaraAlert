import React from 'react'
import { shallow } from 'enzyme';
import PublicHealthAnalytics from '../../components/analytics/PublicHealthAnalytics.js'
import { mockUser1 } from '../mocks/mockUsers'
import mockAnalyticsData from '../mocks/mockAnalytics'

let wrapped = shallow(<PublicHealthAnalytics current_user={mockUser1} stats={mockAnalyticsData} />);

describe('PublicHealthAnalytics', () => {
  it('Properly renders all main components', () => {
    expect(wrapped.find('.display-5').text()).toEqual('Epidemiological Summary');
    expect(wrapped.find('.export-png').exists()).toBeTruthy();
  });
});
