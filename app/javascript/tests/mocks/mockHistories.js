const mockEnrollmentHistory = {
  id: 1,
  original_comment_id: null,
  created_by: 'mock_user_1@example.com',
  comment: 'test non-comment',
  history_type: 'Enrollment',
  created_at: '2020-10-13T14:35:09.000Z',
  updated_at: '2020-10-13T14:35:09.000Z',
  patient_id: 17,
};

const mockCommentHistory1 = {
  id: 2,
  original_comment_id: 2,
  created_by: 'mock_user_2@example.com',
  comment: 'I am another comment',
  history_type: 'Comment',
  created_at: '2020-07-13T14:35:09.000Z',
  updated_at: '2020-07-13T14:35:09.000Z',
  patient_id: 17,
};

const mockCommentHistory2 = {
  id: 3,
  original_comment_id: 3,
  created_by: 'mock_user_1@example.com',
  comment: 'I am a comment',
  history_type: 'Comment',
  created_at: '2020-09-13T14:35:09.000Z',
  updated_at: '2020-09-13T14:35:09.000Z',
  patient_id: 17,
};

const mockCommentHistory2Edit1 = {
  id: 4,
  original_comment_id: 3,
  created_by: 'mock_user_1@example.com',
  comment: 'I am a comment and have been edited',
  history_type: 'Comment',
  created_at: '2020-09-14T14:35:09.000Z',
  updated_at: '2020-09-14T14:35:09.000Z',
  patient_id: 17,
};

const mockCommentHistory2Edit2 = {
  id: 5,
  original_comment_id: 3,
  created_by: 'mock_user_1@example.com',
  comment: 'I am a comment and have been edited',
  history_type: 'Comment',
  created_at: '2020-09-16T14:35:09.000Z',
  updated_at: '2020-09-16T14:35:09.000Z',
  patient_id: 17,
};

export {
  mockEnrollmentHistory,
  mockCommentHistory1,
  mockCommentHistory2,
  mockCommentHistory2Edit1,
  mockCommentHistory2Edit2,
};
