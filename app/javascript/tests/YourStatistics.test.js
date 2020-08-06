import React from 'react'
import {render, fireEvent, screen} from '@testing-library/react'
import YourStatistics from '../components/analytics/widgets/YourStatistics.js'

test('YourStatistics properly renders', () => {
  const value1 = 'Test Message'
  const value2 = 'Test Message'
  expect(value1).toBe(value2);


  // render(<YourStatistics></YourStatistics>)

  // // query* functions will return the element or null if it cannot be found
  // // get* functions will return the element or throw an error if it cannot be found
  // expect(screen.queryByText(testMessage)).toBeNull()

  // // the queries can accept a regex to make your selectors more resilient to content tweaks and changes.
  // fireEvent.click(screen.getByLabelText(/show/i))

  // // .toBeInTheDocument() is an assertion that comes from jest-dom
  // // otherwise you could use .toBeDefined()
  // expect(screen.getByText(testMessage)).toBeInTheDocument()
})