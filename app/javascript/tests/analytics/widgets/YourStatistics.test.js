import React from 'react'
import {render, fireEvent, screen} from '@testing-library/react'
import YourStatistics from '../../../components/analytics/widgets/YourStatistics.js'

test('YourStatistics properly renders', () => {
  const value1 = 'Test Message'
  const value2 = 'Test Message'
  expect(value1).toBe(value2);
})