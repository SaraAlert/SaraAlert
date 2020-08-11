// import dependencies
import React from 'react'
import { render, fireEvent, waitFor, screen } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import PhoneInput from '../../components/util/PhoneInput.js'

// TO-DO: stub out all props for this component and test different phone number cases

test('PhoneInput properly opens and renders', () => {
    render(<PhoneInput />);
    expect(screen.getByTestId('phone_input')).toBeInTheDocument;
});