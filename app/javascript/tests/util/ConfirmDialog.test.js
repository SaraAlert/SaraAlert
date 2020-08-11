// import dependencies
import React from 'react'
import { render, fireEvent, waitFor, screen } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import ConfirmDialog from '../../components/util/ConfirmDialog.js'

// TO-DO: stub out all props for this component and test open/closing

test('ConfirmDialog properly opens and renders', () => {
    ConfirmDialog('confirm');
    expect(screen.getByTestId('confirm_dialog')).toBeInTheDocument;
    expect(screen.getByTestId('confirm_dialog_text')).toHaveTextContent('confirm');
});