// import dependencies
import React from 'react'
import { render, fireEvent, waitFor, screen } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import EmailModal from '../../components/admin/EmailModal.js'

test('EmailModal properly renders', () => {
    let title = "here is a title";
    render(<EmailModal show={true} title={title}/>);
    expect(screen.getByTestId('email_modal')).toBeInTheDocument;
    expect(screen.getByTestId('email_title')).toHaveTextContent(title);
})