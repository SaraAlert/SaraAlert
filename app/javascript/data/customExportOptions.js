import React from 'react';

export const customExportOptions = [
  {
    value: 'monitoree_details',
    label: 'Monitoree Details',
    icon: <i className="fas fa-id-card" />,
    children: [
      {
        value: 'identification',
        label: 'Identification',
        icon: <i className="fas fa-fingerprint" />,
      },
      {
        value: 'contact_information',
        label: 'Contact Information',
        icon: <i className="fas fa-phone" />,
      },
      {
        value: 'address',
        label: 'Address',
        icon: <i className="fas fa-map-marker" />,
      },
      {
        value: 'arrival_information',
        label: 'Arrival Information',
        icon: <i className="fas fa-plane-arrival" />,
      },
      {
        value: 'additional_planned_travel',
        label: 'Additional Planned Travel',
        icon: <i className="fas fa-plane-departure" />,
      },
      {
        value: 'potential_exposure_information',
        label: 'Potential Exposure Information',
        icon: <i className="fas fa-biohazard" />,
      },
    ],
  },
  {
    value: 'monitoring_actions',
    label: 'Monitoring Actions',
    icon: <i className="fas fa-tv" />,
    children: [
      {
        value: 'monitoring_status',
        label: 'Monitoring Status',
      },
      {
        value: 'exposure_risk_assessment',
        label: 'Exposure Risk Assessment',
      },
      {
        value: 'monitoring_plan',
        label: 'Monitoring Plan',
      },
      {
        value: 'case_status',
        label: 'Case Status',
      },
      {
        value: 'public_health_action',
        label: 'Latest Public Health Action',
      },
      {
        value: 'assigned_user',
        label: 'Assigned User',
      },
      {
        value: 'jurisdiction_path',
        label: 'Assigned Jurisdiction',
      },
    ],
  },
  {
    value: 'report_history',
    label: 'Report History',
    icon: <i className="fas fa-notes-medical" />,
  },
  {
    value: 'lab_results',
    label: 'Lab Results',
    icon: <i className="fas fa-flask" />,
  },
  {
    value: 'close_contacts',
    label: 'Close Contacts',
    icon: <i className="fas fa-address-book" />,
  },
  {
    value: 'history',
    label: 'History',
    icon: <i className="fas fa-history" />,
    children: [
      {
        value: 'comment',
        label: 'Comment',
      },
      {
        value: 'contact_attempt',
        label: 'Contact Attempt',
      },
      {
        value: 'enrollment',
        label: 'Enrollment',
      },
      {
        value: 'lab_result',
        label: 'Lab Result',
      },
      {
        value: 'lab_result_edit',
        label: 'Lab Result Edit',
      },
      {
        value: 'monitoree_data_download',
        label: 'Monitoree Data Download',
      },
      {
        value: 'monitoring_change',
        label: 'Monitoring Change',
      },
      {
        value: 'report_created',
        label: 'Report Created',
      },
      {
        value: 'report_note',
        label: 'Report Note',
      },
      {
        value: 'report_reminder',
        label: 'Report Reminder',
      },
      {
        value: 'report_reviewed',
        label: 'Report Reviewed',
      },
      {
        value: 'report_updated',
        label: 'Report Updated',
      },
      {
        value: 'reports_reviewed',
        label: 'Reports Reviewed',
      },
    ],
  },
  {
    value: 'comments',
    label: 'Comments',
    icon: <i className="fas fa-comments" />,
  },
];
