// import dependencies
import React from 'react'


// import react-testing methods
import { render, fireEvent, waitFor, screen } from '@testing-library/react'

// add custom jest matchers from jest-dom
import '@testing-library/jest-dom/extend-expect'
// the component to test
// import Fetch from '../fetch'
import PublicHealthAnalyticss from '../components/analytics/PublicHealthAnalytics.js'

test('PublicHealthAnalyticss properly renders', () => {
  console.log(PublicHealthAnalyticss)
  const { container, asFragment } = render(<PublicHealthAnalyticss/>)
  console.log(container)
  console.log(asFragment)
  // render(<YourStatistics></YourStatistics>)

  // query* functions will return the element or null if it cannot be found
  // get* functions will return the element or throw an error if it cannot be found
  // expect(screen.queryByText(testMessage)).toBeNull()

  // the queries can accept a regex to make your selectors more resilient to content tweaks and changes.
  // fireEvent.click(screen.getByLabelText(/show/i))

  // .toBeInTheDocument() is an assertion that comes from jest-dom
  // otherwise you could use .toBeDefined()
})