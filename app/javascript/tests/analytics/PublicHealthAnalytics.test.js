import React from 'react'
import { render, screen, prettyDOM } from '@testing-library/react'

import '@testing-library/jest-dom/extend-expect'

import PublicHealthAnalytics from '../../components/analytics/PublicHealthAnalytics.js'
import { mockUser1, mockAnalyticsData } from '../mockData/mock'

test('PublicHealthAnalytics properly renders', () => {
  window.SVGPathElement = function () {};
  // SVGPathElement exists in the browser, not node so we have to define it

  render(<PublicHealthAnalytics current_user={mockUser1} stats={mockAnalyticsData}/>)
  // You could add more to this, but these cover most bases. If all of these are there, we can say it's rendered
  const allExpectedDomStrings = ['Epidemiological Summary',
    'Country of Exposure',
    'Total Monitorees by Date of Last Exposure By Risk Status',
    'Active Records in Exposure Workflow',
    'Active Records in Isolation Workflow',
  ];
  allExpectedDomStrings.forEach(domString => {
    expect(screen.getByText(domString)).toBeInTheDocument();
  })
})