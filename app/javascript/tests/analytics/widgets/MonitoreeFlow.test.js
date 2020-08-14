import React from 'react'
import { render, fireEvent, waitFor, screen } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import MonitoreeFlow from '../../../components/analytics/widgets/MonitoreeFlow.js'

const mocked_monitoree_snapshot = [
  {
    analytic_id: 100,
    closed: 14,
    created_at: "2020-01-01T12:00:00.000Z",
    document_completed_medical_evaluation: null,
    document_medical_evaluation_summary_and_plan: null,
    id: 300,
    new_enrollments: 425,
    public_health_test_specimen_received_by_lab_results_pending: null,
    referral_for_medical_evaluation: null,
    referral_for_public_health_test: null,
    results_of_public_health_test_negative: null,
    results_of_public_health_test_positive: null,
    time_frame: "Total",
    transferred_in: 42,
    transferred_out: 57,
    updated_at: "2020-01-01T12:00:00.000Z"
  },
  {
    analytic_id: 100,
    closed: 10,
    created_at: "2020-01-01T12:00:00.000Z",
    document_completed_medical_evaluation: null,
    document_medical_evaluation_summary_and_plan: null,
    id: 299,
    new_enrollments: 351,
    public_health_test_specimen_received_by_lab_results_pending: null,
    referral_for_medical_evaluation: null,
    referral_for_public_health_test: null,
    results_of_public_health_test_negative: null,
    results_of_public_health_test_positive: null,
    time_frame: "Last 14 Days",
    transferred_in: 36,
    transferred_out: 45,
    updated_at: "2020-01-01T12:00:00.000Z"
  },
  {
    analytic_id: 100,
    closed: 5,
    created_at: "2020-01-01T12:00:00.000Z",
    document_completed_medical_evaluation: null,
    document_medical_evaluation_summary_and_plan: null,
    id: 298,
    new_enrollments: 115,
    public_health_test_specimen_received_by_lab_results_pending: null,
    referral_for_medical_evaluation: null,
    referral_for_public_health_test: null,
    results_of_public_health_test_negative: null,
    results_of_public_health_test_positive: null,
    time_frame: "Last 24 Hours",
    transferred_in: 14,
    transferred_out: 25,
    updated_at: "2020-01-01T12:00:00.000Z"
  }
]
const mocked_stats = {
  monitoree_snapshots: mocked_monitoree_snapshot
}

test('MonitoreeFlow properly renders', () => {
  render(<MonitoreeFlow stats={mocked_stats}/>)
  const allExpectedDomStrings = ['Last 24 Hours', 'Last 14 Days', 'Total', 'INCOMING', 'NEW ENROLLMENTS',
    'TRANSFERRED IN', 'OUTGOING', 'CLOSED', 'TRANSFERRED OUT'];
  // screen.debug(); // Can be thought of as a DOM-dump. Essentially `console.log()` for jest
  allExpectedDomStrings.forEach(domString => {
    expect(screen.getByText(domString)).toBeInTheDocument();
  })
  const allExpectedDomValues = {
    'total_closed': 14,
    'total_new_enrollments': 425,
    'total_transferred_in':  42,
    'total_transferred_out': 57,
    'last_14_days_closed': 10,
    'last_14_days_new_enrollments': 351,
    'last_14_days_transferred_in':  36,
    'last_14_days_transferred_out': 45,
    'last_24_hours_closed': 5,
    'last_24_hours_new_enrollments': 115,
    'last_24_hours_transferred_in':  14,
    'last_24_hours_transferred_out': 25,
  }
  for (const [key, value] of Object.entries(allExpectedDomValues)) {
    expect(screen.getByTestId(key)).toHaveTextContent(value);
  }
})