// import dependencies
import React from 'react'
import { render, fireEvent, waitFor, screen } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import DateInput from '../../components/util/DateInput.js'

// TO-DO: stub out all props for this component and test open/closing datepicker

test('DateInput properly opens and renders', () => {
    render(<DateInput />);
    expect(screen.getByTestId('date_input')).toBeInTheDocument;
});