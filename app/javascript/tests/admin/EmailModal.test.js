import React from 'react'
import { render, fireEvent, waitFor, screen } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import EmailModal from '../../components/admin/EmailModal.js'

// TO-DO: stub out all props for this component and test open and closing

test('EmailModal properly renders', () => {
    render(<EmailModal show={true} />);
    expect(screen.getByTestId('email_modal')).toBeInTheDocument;
});