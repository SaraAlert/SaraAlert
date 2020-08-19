import React from 'react'
import { shallow } from 'enzyme';
import PublicHealthAnalytics from '../../components/analytics/PublicHealthAnalytics.js'
import { mockUser1 } from '../mocks/mockUsers'
import mockAnalyticsData from '../mocks/mockAnalytics'

let wrapped = shallow(<PublicHealthAnalytics current_user={mockUser1} stats={mockAnalyticsData} />);

describe('PublicHealthAnalytics properly renders', () => {
  it('section header', () => {
      expect(wrapped.find('.display-5').text()).toEqual('Epidemiological Summary');
  });

  it('export button', () => {
    expect(wrapped.find('.export-png').exists()).toBeTruthy();
  });

  // You could add more to this, but these cover most bases. If all of these are there, we can say it's rendered
  // Could add each analytics component included in this one to be sure they are there
});

// should add a test for the text shown on error as well
