const mockCloseContactBlank = {
  id: null,
  patient_id: null,
  first_name: null,
  last_name: null,
  primary_telephone: null,
  email: null,
  notes: null,
  enrolled_id: null,
  contact_attempts: null,
  created_at: null,
  updated_at: null,
  last_date_of_exposure: null,
  assigned_user: null,
  user_defined_id_statelocal: null,
  user_defined_id_cdc: null,
  user_defined_id_nndss: null,
};

const mockCloseContact1 = {
  id: 18,
  patient_id: 4,
  first_name: 'Captain',
  last_name: 'Rogers',
  primary_telephone: '+15555550146',
  email: 'captain_america@example.com',
  notes: 'I can do this all day, Tony',
  enrolled_id: 25,
  contact_attempts: 11,
  created_at: '2021-01-09 18:58:58.000000000 +0000',
  updated_at: '2021-01-09 18:58:58.000000000 +0000',
  last_date_of_exposure: null,
  assigned_user: null,
  user_defined_id_statelocal: null,
  user_defined_id_cdc: null,
  user_defined_id_nndss: null,
};

const mockCloseContact2 = {
  id: 19,
  patient_id: 4,
  first_name: 'Thor',
  last_name: 'Odinson',
  primary_telephone: '+15555150256',
  email: 'strongest_avenger@example.com',
  notes: "Because that's what superheros do",
  enrolled_id: null,
  contact_attempts: null,
  created_at: '2021-01-06 17:53:58.000000000 +0000',
  updated_at: '2021-01-06 17:53:58.000000000 +0000',
  last_date_of_exposure: '2021-04-03 18:58:58.000000000 +0000',
  assigned_user: 123234,
  user_defined_id_statelocal: null,
  user_defined_id_cdc: null,
  user_defined_id_nndss: null,
};

export { mockCloseContactBlank, mockCloseContact1, mockCloseContact2 };