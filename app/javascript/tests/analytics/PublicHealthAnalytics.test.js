import React from 'react'
import { render, screen, prettyDOM } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import PublicHealthAnalytics from '../../components/analytics/PublicHealthAnalytics.js'
import { mockUser1 } from '../mocks/mockUsers'
import mockAnalyticsData from '../mocks/mockAnalytics'

const allExpectedDomStrings = [
  'Epidemiological Summary',
  'Country of Exposure',
  'Total Monitorees by Date of Last Exposure By Risk Status',
  'Active Records in Exposure Workflow',
  'Active Records in Isolation Workflow',
];

describe('PublicHealthAnalytics properly renders', () => {
  // SVGPathElement exists in the browser, not node so we have to define it
  window.SVGPathElement = function () {};

  test('section headers', () => {
    render(<PublicHealthAnalytics current_user={mockUser1} stats={mockAnalyticsData}/>);
    allExpectedDomStrings.forEach(domString => {
      expect(screen.getByText(domString)).toBeInTheDocument();
    });
  });

  test('export button', () => {
    render(<PublicHealthAnalytics current_user={mockUser1} stats={mockAnalyticsData}/>);
    expect(screen.getByTestId('export_analysis_png')).toBeInTheDocument();
  });

  // You could add more to this, but these cover most bases. If all of these are there, we can say it's rendered
});