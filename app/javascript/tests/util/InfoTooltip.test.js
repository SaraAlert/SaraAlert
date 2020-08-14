import React from 'react'
import { render, fireEvent, waitFor, screen } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import InfoTooltip from '../../components/util/InfoTooltip.js'

// TO-DO: stub out all tooltip options for this component and test them

test('InfoTooltip properly renders', () => {
    render(<InfoTooltip tooltipTextKey="lastDateOfExposure" />);
    expect(screen.getByTestId('info_tooltip')).toBeInTheDocument;
    fireEvent.mouseOver(screen.getByTestId('info_tooltip'));
    expect(screen.getByTestId('info_tooltip_text')).toHaveTextContent('Used by the system to automatically calculate the monitoring period.');
});