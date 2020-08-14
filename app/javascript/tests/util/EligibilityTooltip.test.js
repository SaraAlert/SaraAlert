import React from 'react'
import { render, fireEvent, waitFor, screen } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import EligibilityTooltip from '../../components/util/EligibilityTooltip.js'

// TO-DO: stub out all eligibility mocks and test each one
const eligibilityMock = {
    eligible: false,
    household: true,
    messages: [
        { 
            message: "Monitoree is within a household, so the HoH will receive notifications instead",
            datetime: null
        },
        {
            message: "Monitoree has already reported today",
            datetime: "2020-08-11T18:58:02.000Z"
        }
    ],
    reported: true,
    sent: false
}

test('EligibilityTooltip properly renders', () => {
    render(<EligibilityTooltip report_eligibility={eligibilityMock} />);
    expect(screen.getByTestId('eligibility_tooltip')).toBeInTheDocument;
});