const mockExportPresets = [
  { 
    config: {
      data: {
        assessments: {
          checked: [ 'patient_id', 'user_defined_id_statelocal', 'user_defined_id_cdc', 'user_defined_id_nndss', 'id', 'symptomatic',  'who_reported', 'created_at', 'updated_at', 'symptoms' ],
          expanded: [],
          query: {}
        },
        close_contacts: {
          checked: [],
          expanded: [],
          query: {}
        },
        histories: {
          checked: [],
          expanded: [],
          query: {}
        },
        laboratories: {
          checked: [],
          expanded: [],
          query: {}
        },
        patients: {
          checked: [],
          expanded: [],
          query: {}
        },
        transfers: {
          checked: [],
          expanded: [],
          query: {}
        },
        format: 'xlsx'
      },
    },
    id: 1,
    name: 'custom1'
  },
  {
    config: {
      data: {
        assessments: {
          checked: [ 'patient_id', 'user_defined_id_statelocal', 'symptoms' ],
          expanded: [],
          query: {}
        },
        close_contacts: {
          checked: [],
          expanded: [],
          query: {}
        },
        histories: {
          checked: [],
          expanded: [],
          query: {}
        },
        laboratories: {
          checked: [],
          expanded: [],
          query: {}
        },
        patients: {
          checked: [],
          expanded: [],
          query: {}
        },
        transfers: {
          checked: [],
          expanded: [],
          query: {}
        },
        format: 'xlsx'
      },
    },
    id: 2,
    name: 'custom2'
  }
]

export {
  mockExportPresets
}