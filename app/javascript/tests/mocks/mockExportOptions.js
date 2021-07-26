const mockPlaybookImportExportOptions = {
  enroll: {
    label: 'Enroll New Monitoree',
  },
  export: {
    label: 'Export',
    options: {
      csv: {
        label: 'Line list CSV',
        workflow_specific: true,
      },
      saf: {
        label: 'Sara Alert Format',
        workflow_specific: true,
      },
      purge_eligible: {
        label: 'Excel Export For Purge-Eligible Monitorees',
        workflow_specific: false,
      },
      all: {
        label: 'Excel Export For All Monitorees',
        workflow_specific: false,
      },
      custom_format: {
        label: 'Custom Format...',
        workflow_specific: false,
      },
    },
  },
  import: {
    label: 'Import',
    options: {
      epix: {
        label: 'Epi-X',
      },
      saf: {
        label: 'Sara Alert Format',
      },
    },
  },
};

export { mockPlaybookImportExportOptions };
