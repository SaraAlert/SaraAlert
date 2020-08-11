import React from 'react'
import { render, fireEvent, waitFor, screen } from '@testing-library/react'

import '@testing-library/jest-dom/extend-expect'

import PublicHealthAnalytics from '../../components/analytics/PublicHealthAnalytics.js'
import { mockUser1, mockAnalyticsData } from '../mockData/mock'

test('PublicHealthAnalytics properly renders', () => {
  window.SVGPathElement = function () {};
  // SVGPath exists in the browser, not node so we have to define it

  render(<PublicHealthAnalytics current_user={mockUser1} stats={mockAnalyticsData}/>)

  screen.debug(); // Can be thought of as a DOM-dump. Essentially `console.log()` for jest


})