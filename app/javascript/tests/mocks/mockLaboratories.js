const mockLaboratory1 = {
  id: 1,
  patient_id: 17,
  lab_type: 'PCR',
  specimen_collection: '2020-11-25',
  report: '2020-11-30',
  result: 'positive',
  created_at: '2021-11-23T17:34:25.108Z',
  updated_at: '2021-12-03T17:34:25.108Z',
};

const mockLaboratory2 = {
  id: 2,
  patient_id: 17,
  lab_type: 'Other',
  specimen_collection: '2021-12-13',
  report: '2021-12-15',
  result: 'negative',
  created_at: '2021-12-16T17:34:25.108Z',
  updated_at: '2021-12-16T17:34:25.108Z',
};

const mockLaboratory3 = {
  id: 3,
  patient_id: 17,
  lab_type: 'Antigen',
  specimen_collection: '2021-12-19',
  report: null,
  result: null,
  created_at: '2021-12-23T17:34:25.108Z',
  updated_at: '2021-12-23T17:34:25.108Z',
};

export { mockLaboratory1, mockLaboratory2, mockLaboratory3 };
