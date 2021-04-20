
const mockHistory1 = {
  id: 1,
  created_by: 'minnie.mouse@example.com',
  comment: "test non-comment",
  history_type: "Enrollment",
  created_at: '2020-09-13T14:35:09.000Z',
  updated_at: '2020-09-13T14:35:09.000Z',
  patient_id: 17,
  was_edited: false
};

const mockHistory2 = {
  id: 2,
  created_by: 'mickey.mouse@example.com',
  comment: "test comment",
  history_type: "Comment",
  created_at: '2020-09-13T14:35:09.000Z',
  updated_at: '2020-09-13T14:35:09.000Z',
  patient_id: 17,
  was_edited: false
};

const mockHistory3 = {
  id: 3,
  created_by: 'minnie.mouse@example.com',
  comment: "test comment",
  history_type: "Comment",
  created_at: '2020-09-13T14:35:09.000Z',
  updated_at: '2020-09-13T14:35:09.000Z',
  patient_id: 17,
  was_edited: true
};

export {
  mockHistory1,
  mockHistory2,
  mockHistory3
};