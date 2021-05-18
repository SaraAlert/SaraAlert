# frozen_string_literal: true

require 'test_case'

class HistoriesControllerTest < ActionController::TestCase
  # --- BEFORE ACTION --- #

  test 'before action: authenticate user' do
    post :create, params: {}
    assert_redirected_to(new_user_session_path)

    put :edit, params: { id: 'test' }
    assert_redirected_to(new_user_session_path)

    put :delete, params: { id: 'test' }
    assert_redirected_to(new_user_session_path)
  end

  test 'before action: check user role' do
    user = create(:enroller_user)
    sign_in user

    post :create, params: {}
    assert_response(:forbidden)

    put :edit, params: { id: 'test' }
    assert_response(:forbidden)

    put :delete, params: { id: 'test' }
    assert_response(:forbidden)

    sign_out user
  end

  test 'before action: check patient valid (patient exists)' do
    user = create(:public_health_enroller_user)
    sign_in user

    post :create, params: { patient_id: 'test' }
    assert_response(:bad_request)
    assert_equal("History comment cannot be modified for unknown monitoree with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])

    put :edit, params: { id: 'test', patient_id: 'test' }
    assert_response(:bad_request)
    assert_equal("History comment cannot be modified for unknown monitoree with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])

    put :delete, params: { id: 'test', patient_id: 'test' }
    assert_response(:bad_request)
    assert_equal("History comment cannot be modified for unknown monitoree with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])

    sign_out user
  end

  test 'before action: check patient (current user can view patient)' do
    user = create(:public_health_enroller_user)
    user_2 = create(:public_health_enroller_user)
    patient = create(:patient, creator: user_2)
    sign_in user

    post :create, params: { patient_id: patient.id }
    assert_response(:forbidden)
    assert_equal("User does not have access to Patient with ID: #{patient.id}", JSON.parse(response.body)['error'])

    put :edit, params: { id: 'test', patient_id: patient.id }
    assert_response(:forbidden)
    assert_equal("User does not have access to Patient with ID: #{patient.id}", JSON.parse(response.body)['error'])

    put :delete, params: { id: 'test', patient_id: patient.id }
    assert_response(:forbidden)
    assert_equal("User does not have access to Patient with ID: #{patient.id}", JSON.parse(response.body)['error'])

    sign_out user
  end

  test 'before action: check history' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    sign_in user

    put :edit, params: { id: 'test', patient_id: patient.id }
    assert_response(:bad_request)

    put :delete, params: { id: 'test', patient_id: patient.id }
    assert_response(:bad_request)

    sign_out user
  end

  # --- CREATE --- #

  test 'create: creates new history comment' do
    user = users(:usa_super_user)
    patient = create(:patient, creator: user)
    comment = 'test comment'
    sign_in user

    post :create, params: {
      patient_id: patient.id,
      history_type: History::HISTORY_TYPES[:comment],
      comment: comment
    }

    assert_response :success
    assert patient.histories.where(comment: comment).exists?

    new_history = History.last
    assert_equal new_history.id, new_history.original_comment_id
    assert_equal user.email, new_history.created_by
    assert_equal comment, new_history.comment
    assert_equal History::HISTORY_TYPES[:comment], new_history.history_type
  end

  test 'create: handles failure on create and fires error' do
    user = users(:usa_super_user)
    patient = create(:patient, creator: user)
    comment = 'test comment'
    allow_any_instance_of(History).to receive(:save).and_return(false)
    sign_in user

    post :create, params: {
      patient_id: patient.id,
      history_type: History::HISTORY_TYPES[:comment],
      comment: comment
    }

    assert_response(:bad_request)
    assert_equal('Comment was unable to be created.', JSON.parse(response.body)['error'])
    assert_equal(0, patient.histories.count)

    sign_out user
  end

  # --- EDIT --- #

  test 'edit: edits existing history comment by creating a new version linked to the original' do
    user = users(:usa_super_user)
    history = histories(:public_health_action_patient_20_comment_2)
    comment = 'test comment edit'
    sign_in user

    post :edit, params: {
      id: history.id,
      patient_id: patients(:patient_20).id,
      comment: comment
    }

    assert_response :success
    assert patients(:patient_20).histories.where(original_comment_id: history.id, comment: comment).exists?
    assert_equal 2, patients(:patient_20).histories.where(original_comment_id: history.id).length

    new_history = History.last
    assert_equal history.id, new_history.original_comment_id
    assert_equal user.email, new_history.created_by
    assert_equal comment, new_history.comment
    assert_equal History::HISTORY_TYPES[:comment], new_history.history_type

    old_history = History.find_by(id: new_history.original_comment_id)
    assert_equal history.original_comment_id, old_history.original_comment_id
    assert_equal history.created_by, old_history.created_by
    assert_equal history.comment, old_history.comment
    assert_equal History::HISTORY_TYPES[:comment], old_history.history_type
  end

  test 'edit: handles failure on edit and fires error' do
    user = users(:usa_super_user)
    history = histories(:public_health_action_patient_20_comment_2)
    comment = 'test comment edit'

    allow_any_instance_of(History).to receive(:save).and_return(false)
    sign_in user

    post :edit, params: {
      id: history.id,
      patient_id: patients(:patient_20).id,
      comment: comment
    }

    assert_response(:bad_request)
    assert_equal('Comment was unable to be edited.', JSON.parse(response.body)['error'])
    assert_not patients(:patient_20).histories.where(original_comment_id: history.id, comment: comment).exists?
    assert_equal 1, patients(:patient_20).histories.where(original_comment_id: history.id).length

    sign_out user
  end

  # --- DELETE --- #

  test 'delete: deletes history comment by flagging it as deleted' do
    user = users(:usa_super_user)
    history = histories(:public_health_action_patient_20_comment_2)
    delete_reason = 'test delete reason'
    sign_in user

    post :delete, params: {
      id: history.id,
      patient_id: patients(:patient_20).id,
      delete_reason: delete_reason
    }

    assert_response :success

    deleted_history = History.find_by(id: history.id)
    assert_equal user.email, deleted_history.deleted_by
    assert_equal delete_reason, deleted_history.delete_reason
  end

  test 'delete: deletes all versions of a history comment by flagging them as deleted' do
    user = users(:usa_super_user)
    history = histories(:public_health_action_patient_20_comment_1)
    delete_reason = 'test delete reason'
    sign_in user

    post :delete, params: {
      id: history.id,
      patient_id: patients(:patient_20).id,
      delete_reason: delete_reason
    }

    assert_response :success

    deleted_histories = History.where(original_comment_id: history.id)
    assert_equal 3, deleted_histories.length
    deleted_histories.each do |h|
      assert_equal user.email, h.deleted_by
      assert_equal delete_reason, h.delete_reason
    end
  end
end
